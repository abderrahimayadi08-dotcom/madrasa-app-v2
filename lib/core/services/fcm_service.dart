import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:madrasa_app/core/services/logger.dart';

class FcmService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static String? _currentRole;

  static Future<void> init() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    final perm = await _fcm.requestPermission();
    if (perm.authorizationStatus == AuthorizationStatus.denied) {
      Logger.info('FCM permission not granted');
      return;
    }
    final token = await _fcm.getToken();
    Logger.info('FCM token: $token');

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<void> subscribeForRole(String? role) async {
    if (_currentRole == role) return;
    if (_currentRole != null) {
      await _fcm.unsubscribeFromTopic(_currentRole!);
    }
    _currentRole = role;
    if (role != null) {
      await _fcm.subscribeToTopic(role);
      Logger.info('Subscribed to FCM topic: $role');
    }
  }

  static Future<void> subscribeUserTopic(String uid) async {
    await _fcm.subscribeToTopic('user_$uid');
    Logger.info('Subscribed to user topic: user_$uid');
  }

  static void _handleForegroundMessage(RemoteMessage msg) {
    final title = msg.notification?.title ?? msg.data['title'] ?? 'إشعار';
    final body = msg.notification?.body ?? msg.data['body'] ?? '';
    _showLocalNotif(title, body);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage msg) async {
    final title = msg.notification?.title ?? msg.data['title'] ?? 'إشعار';
    final body = msg.notification?.body ?? msg.data['body'] ?? '';
    _showLocalNotif(title, body);
  }

  static void _showLocalNotif(String title, String body) {
    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'requests',
          'طلبات جديدة',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}