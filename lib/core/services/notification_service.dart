import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:madrasa_app/core/services/logger.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Set<String> _knownIds = {};
  static StreamSubscription<QuerySnapshot>? _subscription;

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
      _initialized = true;
      Logger.info('Local notification service initialized');
    } catch (e) {
      Logger.error('Notification init failed: $e');
    }
  }

  static void startListening() {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !_knownIds.contains(change.doc.id)) {
          _knownIds.add(change.doc.id);
        }
      }
    });

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((doc) {
      if (!doc.exists) return;
      final role = doc.data()?['role'] as String?;
      if (role == null ||
          (role != 'finance_manager' && role != 'maintenance_manager')) return;
      _listenForNewRequests(role);
    });
  }

  static void _listenForNewRequests(String role) {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('requests')
        .where('assignedRole', isEqualTo: role)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !_knownIds.contains(change.doc.id)) {
          _knownIds.add(change.doc.id);
          final data = change.doc.data() as Map<String, dynamic>;
          final title = data['category'] == 'purchase'
              ? 'طلب شراء جديد'
              : 'طلب صيانة جديد';
          final body = '${data['userName'] ?? 'عضو'}: ${data['itemName'] ?? ''}';
          _showNotification(title, body);
        }
      }
    });
  }

  static void _showNotification(String title, String body) {
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
          ongoing: true,
          autoCancel: false,
        ),
      ),
    );
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
