import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:madrasa_app/app.dart';
import 'package:madrasa_app/core/services/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    Logger.error('Flutter error: ${details.exception}');
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    Logger.error('Platform error: $error');
    return true;
  };
  try {
    await Firebase.initializeApp();
    Logger.info('Firebase initialized');
  } catch (e) {
    Logger.error('Firebase init failed: $e');
  }
  runApp(const MadrasaApp());
}
