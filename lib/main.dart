import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../database/database_helper.dart';
import '../screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = Locale('ar');
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocale();
    });
  }

  Future<void> _loadLocale() async {
    String? storedLanguageCode = await DatabaseHelper().getSelectedLanguage();
    Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;

    if (storedLanguageCode != null) {
      setLocale(Locale(storedLanguageCode));
    } else {
      setLocale(
          deviceLocale.languageCode == 'ar' || deviceLocale.languageCode == 'en'
              ? deviceLocale
              : const Locale('ar'));
    }

    setState(() {
      _isDarkMode =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
    });
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale,
      title: 'مراجعة الورد اليومي',
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.green,
        fontFamily: 'Uthmanic',
        popupMenuTheme: PopupMenuThemeData(
          color: _isDarkMode ? Colors.grey.shade200 : Colors.pink.shade200,
          textStyle: const TextStyle(
            color: Colors.black,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      home: HomeScreen(
          setLocale: setLocale,
          isDarkMode: _isDarkMode,
          toggleTheme: toggleTheme),
    );
  }
}
