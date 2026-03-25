import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import "package:foodshare/StartPage.dart";
import 'package:foodshare/New_or_login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "foodshare",

      // 👇 これが重要
      locale: Locale('ja'),

      supportedLocales: [
        Locale('ja'),
        Locale('en'),
      ],

      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: NewOrLoginPage(),
    );
  }
}