import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:madrasa_app/core/services/logger.dart';

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static Set<String> _knownIds = {};
  static StreamSubscription<QuerySnapshot>? _subscription;
  static ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  static StreamSubscription<QuerySnapshot>? _unreadSub;

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

    _unreadSub?.cancel();
    _unreadSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      unreadCount.value = snapshot.docs.length;
    });

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified &&
            !_knownIds.contains('${change.doc.id}_status')) {
          _knownIds.add('${change.doc.id}_status');
          final data = change.doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          final statusLabels = {
            'approved': 'تمت الموافقة على طلبك',
            'rejected': 'تم رفض طلبك',
            'hold': 'طلبك معلق',
            'completed': 'تم إنجاز طلبك',
          };
          final title = statusLabels[status] ?? 'تحديث الطلب';
          final notes = data['notes'] as String?;
          final body = notes != null && notes.isNotEmpty
              ? '${data['itemName'] ?? ''} - $notes'
              : '${data['itemName'] ?? ''}';
          _saveAndShow(
            user.uid,
            title,
            body,
            data['category'] as String? ?? '',
            data['priority'] as String? ?? 'medium',
            status,
          );
        }
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
      if (role == null) return;

      if (role == 'general_manager') {
        _listenForAllRequests(user.uid);
      } else if (role == 'finance_manager' || role == 'maintenance_manager') {
        _listenForNewRequests(role, user.uid);
      }
    });
  }

  static void _listenForNewRequests(String role, String uid) {
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
          final notes = data['notes'] as String?;
          final body = notes != null && notes.isNotEmpty
              ? '${data['userName'] ?? 'عضو'}: ${data['itemName'] ?? ''} - $notes'
              : '${data['userName'] ?? 'عضو'}: ${data['itemName'] ?? ''}';
          _saveAndShow(
            uid,
            title,
            body,
            data['category'] as String? ?? '',
            data['priority'] as String? ?? 'medium',
            'pending',
          );
        }
      }
    });
  }

  static void _listenForAllRequests(String uid) {
    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('requests')
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added &&
            !_knownIds.contains(change.doc.id)) {
          _knownIds.add(change.doc.id);
          final data = change.doc.data() as Map<String, dynamic>;
          final cat = data['category'] == 'purchase' ? 'شراء' : 'صيانة';
          final title = 'طلب $cat جديد';
          final notes = data['notes'] as String?;
          final body = notes != null && notes.isNotEmpty
              ? '${data['userName'] ?? 'عضو'}: ${data['itemName'] ?? ''} - $notes'
              : '${data['userName'] ?? 'عضو'}: ${data['itemName'] ?? ''}';
          _saveAndShow(
            uid,
            title,
            body,
            data['category'] as String? ?? '',
            data['priority'] as String? ?? 'medium',
            'pending',
          );
        }
      }
    });
  }

  static Future<void> _saveAndShow(
    String userId,
    String title,
    String body,
    String category,
    String priority,
    String status,
  ) async {
    try {
      final doc = FirebaseFirestore.instance.collection('notifications').doc();
      await doc.set({
        'id': doc.id,
        'userId': userId,
        'title': title,
        'body': body,
        'category': category,
        'priority': priority,
        'status': status,
        'read': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error('Failed to save notification: $e');
    }

    _showNotification(title, body);
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
    _unreadSub?.cancel();
    _unreadSub = null;
  }
}
