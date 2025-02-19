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
  Locale _locale = const Locale('en');
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocale();
    });
  }

  Future<void> _loadLocale() async {
    Locale deviceLocale = Localizations.localeOf(context);

    String? storedLanguageCode = await DatabaseHelper().getSelectedLanguage();
    if (storedLanguageCode != null) {
      setLocale(Locale(storedLanguageCode));
    } else {
      setLocale(
          deviceLocale.languageCode == 'ar' || deviceLocale.languageCode == 'en'
              ? deviceLocale
              : const Locale('ar'));
    }
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراجعة الورد اليومي',
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.green,
        fontFamily: 'Uthmanic',
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
      locale: _locale,
      home: HomeScreen(setLocale: setLocale),
    );
  }
}
