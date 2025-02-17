import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.prefs.getBool('isDarkMode') ?? false;
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    String? storedLanguageCode = widget.prefs.getString('selectedLanguage');
    if (storedLanguageCode != null) {
      setLocale(Locale(storedLanguageCode));
    } else {
      setLocale(const Locale('ar'));
    }
  }

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  void setIsDarkMode(bool value) async {
    setState(() {
      _isDarkMode = value;
    });
    await widget.prefs.setBool('isDarkMode', value);
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
      home: HomeScreen(setLocale: setLocale, prefs: widget.prefs, isDarkMode: _isDarkMode, setIsDarkMode: setIsDarkMode),
    );
  }
}
