import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:notes/models/note.dart';
import 'package:notes/provider/theme_provider.dart';
import 'package:notes/screens/google_map_screen.dart';
import 'package:notes/services/note_service.dart';
import 'package:notes/widgets/note_dialog.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});

  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
      ),
      body: const NoteList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return const NoteDialog();
            },
          );
        },
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NoteList extends StatelessWidget {
  const NoteList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 30),
          child: Consumer<ThemeNotifier>(
            builder: (context, notifier, child) => SwitchListTile.adaptive(
              title: const Text('Dark Mode'),
              onChanged: (val) {
                notifier.toggleChangeTheme(val);
              },
              value: notifier.darkMode!,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: NoteService.getNoteList(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                default:
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: snapshot.data!.map((document) {
                      return Card(
                        child: Column(
                          children: [
                            document.imageUrl != null &&
                                    Uri.parse(document.imageUrl!).isAbsolute
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      document.imageUrl!,
                                      width: double.infinity,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                    ),
                                  )
                                : Container(),
                            ListTile(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return NoteDialog(note: document);
                                  },
                                );
                              },
                              title: Text(document.title),
                              subtitle: Text(document.description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  document.lat != null && document.lng != null
                                      ? InkWell(
                                          onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        GoogleMapScreen(
                                                          document.lat,
                                                          document.lng,
                                                        )));
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10),
                                            child: Icon(Icons.map),
                                          ),
                                        )
                                      : const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Icon(
                                            Icons.map,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  InkWell(
                                    onTap: () {
                                      showAlertDialog(context, document);
                                    },
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Icon(Icons.delete),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _onShareWithResult(
                                          context, document.imageUrl);
                                    },
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      child: Icon(Icons.share),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
              }
            },
          ),
        ),
      ],
    );
  }

  void _onShareWithResult(BuildContext context, String? imageUrl) async {
    final box = context.findRenderObject() as RenderBox?;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    ShareResult shareResult;
    if (imageUrl != null && Uri.parse(imageUrl).isAbsolute) {
      final http.Response responseData = await http.get(Uri.parse(imageUrl));

      Uint8List uint8list = responseData.bodyBytes;
      var buffer = uint8list.buffer;
      ByteData byteData = ByteData.view(buffer);

      var tempDir = await getTemporaryDirectory();
      File file = await File('${tempDir.path}/img').writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
      final files = <XFile>[];

      files.add(XFile(file.path));

      shareResult = await Share.shareXFiles(
        files,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      shareResult = await Share.share(
        'Kosong',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    }
    scaffoldMessenger.showSnackBar(getResultSnackBar(shareResult));
  }

  SnackBar getResultSnackBar(ShareResult result) {
    return SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Share result: ${result.status}"),
          if (result.status == ShareResultStatus.success)
            Text("Shared to: ${result.raw}")
        ],
      ),
    );
  }

  Future<void> openMap(String? lat, String? lng) async {
    Uri uri =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat, $lng");
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri!');
    }
  }

  showAlertDialog(BuildContext context, Note document) {
    // set up the buttons
    Widget cancelButton = ElevatedButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = ElevatedButton(
      child: const Text("Yes"),
      onPressed: () {
        NoteService.deleteNote(document).whenComplete(() {
          Navigator.of(context).pop();
        });
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Delete Note"),
      content: const Text("Are you sure to delete Note?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
