import 'package:flutter/material.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:madrasa_app/features/auth/auth_gate.dart';

class MadrasaApp extends StatelessWidget {
  const MadrasaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المدرسة القرآنية',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
