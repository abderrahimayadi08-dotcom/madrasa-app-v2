import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B5E20),
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(centerTitle: true),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B5E20),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(centerTitle: true),
      );
}
