import 'package:flutter/material.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:madrasa_app/features/auth/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MadrasaApp extends StatefulWidget {
  const MadrasaApp({super.key});

  @override
  State<MadrasaApp> createState() => _MadrasaAppState();
}

class _MadrasaAppState extends State<MadrasaApp> {
  Color _seed = AppTheme.defaultSeed;

  @override
  void initState() {
    super.initState();
    AppTheme.seedNotifier.addListener(_onSeedChanged);
    _loadSeed();
  }

  void _onSeedChanged() {
    setState(() => _seed = AppTheme.seedNotifier.value);
  }

  Future<void> _loadSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt('themeColor');
    if (val != null) {
      final color = Color(val);
      AppTheme.seedNotifier.value = color;
    }
  }

  @override
  void dispose() {
    AppTheme.seedNotifier.removeListener(_onSeedChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المدرسة القرآنية',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seed: _seed),
      darkTheme: AppTheme.light(seed: _seed),
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
