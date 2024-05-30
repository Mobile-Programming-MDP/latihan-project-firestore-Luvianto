import 'package:day_night_switcher/day_night_switcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'provider/theme_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: Consumer<ThemeNotifier>(
        builder: (context, ThemeNotifier notifier, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: notifier.darkMode! ? darkMode : lightMode,
            home: const MyHomePage(title: 'Theme: Shared Preferences'),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 30),
              child: Consumer<ThemeNotifier>(
                builder: (context, notifier, child) {
                  return DayNightSwitcherIcon(
                    onStateChanged: (val) {
                      notifier.toggleChangeTheme(val);
                    },
                    isDarkModeEnabled: notifier.darkMode!,
                  );
                },
              ),
            ),
            //
            //
            const SizedBox(height: 20),
            //
            //
            Container(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 30),
              child: Consumer<ThemeNotifier>(
                builder: (context, notifier, child) {
                  return DayNightSwitcher(
                    onStateChanged: (val) {
                      notifier.toggleChangeTheme(val);
                    },
                    isDarkModeEnabled: notifier.darkMode!,
                  );
                },
              ),
            ),
            //
            //
            const SizedBox(height: 20),
            //
            //
            Container(
              padding: const EdgeInsets.only(left: 15, right: 15, bottom: 30),
              child: Consumer<ThemeNotifier>(
                builder: (context, notifier, child) => SwitchListTile.adaptive(
                  title: notifier.darkMode!
                      ? const Text('Dark Mode')
                      : const Text("Light Mode"),
                  onChanged: (val) {
                    notifier.toggleChangeTheme(val);
                  },
                  value: notifier.darkMode!,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
