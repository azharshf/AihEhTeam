import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(const LipidWiseApp());
}

class LipidWiseApp extends StatelessWidget {
  const LipidWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LipidWise AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        fontFamily: 'Inter',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
      ),
      themeMode: ThemeMode.dark, // Default to dark aesthetic
      home: const LandingScreen(),
    );
  }
}
