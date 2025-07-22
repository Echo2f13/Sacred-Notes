import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() => runApp(const SettleApp());

class SettleApp extends StatelessWidget {
  const SettleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settle',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: const Color(0xFF0F0F1C),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1F1F2E),
          foregroundColor: Colors.white,
        ),

        cardTheme: CardThemeData(
          color: Color(0xFF1B1B2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
        ),

        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white60,
          ),
        ),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9D50BB),
          secondary: Color(0xFF6E48AA),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}