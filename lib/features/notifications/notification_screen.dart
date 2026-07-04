import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _uid = auth.FirebaseAuth.instance.currentUser?.uid ?? '';

  void _markAllRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .where('read', isEqualTo: false)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({'read': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'تحديد الكل كمقروء',
            onPressed: _markAllRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: _uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  const Text('حدث خطأ في تحميل الإشعارات'),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إشعارات',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'عندما يحدث تحديث لطلباتك، ستظهر الإشعارات هنا',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data() as Map<String, dynamic>;
              final read = data['read'] as bool? ?? false;
              final createdAt = data['createdAt'] as String? ?? '';
              return _notificationTile(data, read, createdAt);
            },
          );
        },
      ),
    );
  }

  Widget _notificationTile(Map<String, dynamic> data, bool read, String createdAt) {
    final scheme = Theme.of(context).colorScheme;
    final title = data['title'] as String? ?? '';
    final body = data['body'] as String? ?? '';
    final icon = data['category'] == 'purchase'
        ? Icons.shopping_cart
        : data['category'] == 'maintenance'
            ? Icons.build
            : Icons.notifications_outlined;
    final status = data['status'] as String? ?? '';
    final statColor = AppTheme.statusColor(status);

    return Dismissible(
      key: Key('${data['id']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: scheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        FirebaseFirestore.instance
            .collection('notifications')
            .doc(data['id'])
            .delete();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: read ? Colors.transparent : scheme.primaryContainer.withValues(alpha: 0.15),
        child: InkWell(
          onTap: () {
            if (!read) {
              FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(data['id'])
                  .update({'read': true});
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: read
                        ? scheme.surfaceContainerLow
                        : scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight:
                                    read ? FontWeight.w500 : FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (status.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: statColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppTheme.statusLabel(status),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!read)
                  Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat.yMd().add_Hm().format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }
}
