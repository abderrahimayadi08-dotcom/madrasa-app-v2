import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:madrasa_app/core/services/logger.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      const channel = AndroidNotificationChannel(
        'requests',
        'طلبات جديدة',
        description: 'إشعارات الطلبات الجديدة',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onMessage.listen(_handleForeground);
      FirebaseMessaging.onBackgroundMessage(_handleBackground);
      _initialized = true;
      Logger.info('Notification service initialized');
    } catch (e) {
      Logger.error('Notification init failed: $e');
    }
  }

  static Future<void> saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        final user = auth.FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'fcmToken': token}, SetOptions(merge: true));
          Logger.info('FCM token saved');
        }
      }
    } catch (e) {
      Logger.error('Failed to save FCM token: $e');
    }
  }

  static void _handleForeground(RemoteMessage message) {
    final title = message.notification?.title ?? 'إشعار';
    final body = message.notification?.body ?? '';
    _localNotifications.show(
      message.hashCode,
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

  @pragma('vm:entry-point')
  static Future<void> _handleBackground(RemoteMessage message) async {
    Logger.info('Background notification: ${message.messageId}');
  }
}
