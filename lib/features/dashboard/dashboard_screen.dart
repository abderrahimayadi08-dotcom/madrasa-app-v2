import 'package:cloud_firestore/cloud_firestore.dart';
// ignore_for_file: unnecessary_cast
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:madrasa_app/features/auth/auth_gate.dart';
import 'package:madrasa_app/features/settings/settings_screen.dart';
import 'package:madrasa_app/core/services/notification_service.dart';
import 'package:madrasa_app/features/dashboard/request_detail_screen.dart';
import 'package:madrasa_app/features/notifications/notification_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel user;
  const DashboardScreen({super.key, required this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  bool get _isGeneral => widget.user.isGeneralManager;

  String get _roleLabel =>
      widget.user.isFinanceManager ? 'finance_manager' : 'maintenance_manager';

  String get _title =>
      _isGeneral ? 'كل الطلبات'
      : widget.user.isFinanceManager ? 'طلبات الشراء' : 'طلبات الصيانة';

  DateTime _parseDate(dynamic d) {
    if (d is String) return DateTime.parse(d);
    if (d is Timestamp) return d.toDate();
    return DateTime.now();
  }

  int _priorityValue(String p) {
    switch (p) {
      case 'urgent':
        return 0;
      case 'medium':
        return 1;
      case 'low':
        return 2;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
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
                  _filterChip('hold', 'معلق'),
                  const SizedBox(width: 6),
                  _filterChip('completed', 'تم'),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _isGeneral
                  ? _firestoreService.getAllRequests()
                  : _firestoreService.getRequestsByRole(_roleLabel),
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
                    final pa = a['priority'];
                    final pb = b['priority'];
                    final va = pa is String ? _priorityValue(pa) : 3;
                    final vb = pb is String ? _priorityValue(pb) : 3;
                    final p = va.compareTo(vb);
                    if (p != 0) return p;
                    final ca = a['createdAt'];
                    final cb = b['createdAt'];
                    final sa = ca is String ? ca : '${ca}';
                    final sb = cb is String ? cb : '${cb}';
                    return sb.compareTo(sa);
                  });
                } catch (_) {}
                if (_filter != 'all') {
                  docs = docs.where((d) => d['status'] == _filter).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: scheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات للمراجعة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'عدد المستندات المستلمة: ${snapshot.data!.docs.length}',
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {},
                  child: ListView.builder(
                    itemCount: docs.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (_, i) {
                      final r = docs[i];
                      return _requestCard(r);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(QueryDocumentSnapshot r) {
    final status = r['status'] as String;
    final priority = r['priority'] as String;
    final priColor = AppTheme.priorityColor(priority);
    final statColor = AppTheme.statusColor(status);
    final price = r['estimatedPrice'];
    final priceText =
        price != null && price != 0 ? '${price.toStringAsFixed(0)} د.ل' : null;
    final notes = r['notes'] as String?;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(
              requestData: r.data() as Map<String, dynamic>,
              requestId: r.id,
            ),
          ),
        ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['itemName'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(r['userName'] as String,
                                style: TextStyle(
                                    fontSize: 13, color: scheme.onSurfaceVariant)),
                          ],
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
                        r['category'] == 'purchase' ? Icons.shopping_cart : Icons.build,
                        r['category'] == 'purchase' ? 'شراء' : 'صيانة',
                        scheme.onSurfaceVariant,
                      ),
                      if ((r['quantity'] as num?)?.toInt() != null &&
                          (r['quantity'] as num).toInt() > 1) ...[
                        const SizedBox(width: 8),
                        _metaChip(Icons.numbers,
                            'x${(r['quantity'] as num).toInt()}',
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
                            _parseDate(r['createdAt'])),
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      if (priceText != null) ...[
                        const Spacer(),
                        Text(priceText,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary)),
                      ],
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
      ),
    );
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
