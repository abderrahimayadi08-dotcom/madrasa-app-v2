import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:madrasa_app/app.dart';
import 'package:madrasa_app/core/services/logger.dart';
import 'package:madrasa_app/core/services/notification_service.dart';
import 'package:madrasa_app/core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    Logger.error('Flutter error: ${details.exception}');
    FlutterError.presentError(details);
  };
  try {
    await Firebase.initializeApp();
    await NotificationService.init();
    await FcmService.init();
    Logger.info('Firebase initialized');
  } catch (e) {
    Logger.error('Firebase init failed: $e');
  }
  runApp(const MadrasaApp());
}
