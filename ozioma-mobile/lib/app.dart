import 'package:flutter/material.dart';
import 'screens/lock_screen.dart';
import 'screens/shell.dart';

class OziomaApp extends StatelessWidget {
  const OziomaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ozioma',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF0F172A)),
        scaffoldBackgroundColor: Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const LockScreen(child: Shell()),
    );
  }
}
