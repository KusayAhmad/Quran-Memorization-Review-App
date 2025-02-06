import 'package:flutter/material.dart';
import 'package:quran_review_app/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مراجعة المحفوظ',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Uthmanic',
      ),
      home: const HomeScreen(),
    );
  }
}
