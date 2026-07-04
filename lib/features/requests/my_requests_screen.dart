import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:madrasa_app/features/auth/auth_gate.dart';
import 'package:madrasa_app/features/settings/settings_screen.dart';
import 'package:madrasa_app/core/services/notification_service.dart';
import 'package:madrasa_app/features/notifications/notification_screen.dart';
import 'package:madrasa_app/features/requests/create_request_screen.dart';
import 'package:intl/intl.dart';

class MyRequestsScreen extends StatefulWidget {
  final UserModel user;
  const MyRequestsScreen({super.key, required this.user});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    NotificationService.startListening();
  }

  @override
  void dispose() {
    NotificationService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً ${widget.user.name}'),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadCount,
            builder: (_, count, __) => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  ),
                ),
                if (count > 0)
                  Positioned(
                    left: 22,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthGate()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: DecorativeDivider(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('all', 'الكل'),
                  const SizedBox(width: 6),
                  _filterChip('pending', 'قيد المراجعة'),
                  const SizedBox(width: 6),
                  _filterChip('approved', 'موافق'),
                  const SizedBox(width: 6),
                  _filterChip('rejected', 'مرفوض'),
                  const SizedBox(width: 6),
                  _filterChip('completed', 'تم'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getRequestsByUser(widget.user.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: scheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('حدث خطأ في تحميل الطلبات'),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs.toList();
                try {
                  docs.sort((a, b) {
                    final ca = a['createdAt'];
                    final cb = b['createdAt'];
                    final sa = ca is String ? ca : '${ca}';
                    final sb = cb is String ? cb : '${cb}';
                    return sb.compareTo(sa);
                  });
                } catch (_) {}
                final requests = docs.where((d) {
                  if (_filter == 'all') return true;
                  return d['status'] == _filter;
                }).toList();
                if (requests.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 72, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات بعد',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على الزر (+) في الأسفل\nلإرسال طلب شراء أو صيانة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const CreateRequestScreen()),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('طلب جديد'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    itemCount: requests.length,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemBuilder: (_, i) {
                      try {
                        final r = requests[i];
                        return _requestCard(r);
                      } catch (e) {
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('الوثيقة $i بها خطأ: $e',
                                style: const TextStyle(color: Colors.red)),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _requestCard(QueryDocumentSnapshot r) {
    final d = r.data()!;
    final status = d['status'] as String;
    final priority = d['priority'] as String;
    final priColor = AppTheme.priorityColor(priority);
    final statColor = AppTheme.statusColor(status);
    final notes = d['notes'] as String?;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 3, color: priColor),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: priColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        d['itemName'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AppTheme.statusLabel(status),
                        style: TextStyle(
                          fontSize: 12,
                          color: statColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metaChip(Icons.flag_outlined, AppTheme.priorityLabel(priority), priColor),
                    const SizedBox(width: 8),
                    _metaChip(
                      d['category'] == 'purchase' ? Icons.shopping_cart : Icons.build,
                      d['category'] == 'purchase' ? 'شراء' : 'صيانة',
                      scheme.onSurfaceVariant,
                    ),
                    if ((d['quantity'] as num?)?.toInt() != null &&
                        (d['quantity'] as num).toInt() > 1) ...[
                      const SizedBox(width: 8),
                      _metaChip(Icons.numbers,
                          'x${(d['quantity'] as num).toInt()}',
                          scheme.onSurfaceVariant),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 12, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMd().format(
                          _parseDate(d['createdAt'])),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notes_outlined,
                          size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          notes,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseDate(dynamic d) {
    if (d is String) return DateTime.parse(d);
    if (d is Timestamp) return d.toDate();
    return DateTime.now();
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label, style: TextStyle(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      )),
      selected: selected,
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.primary,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
