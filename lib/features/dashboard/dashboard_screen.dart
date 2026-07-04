import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:madrasa_app/features/auth/auth_gate.dart';
import 'package:madrasa_app/features/settings/settings_screen.dart';
import 'package:madrasa_app/features/dashboard/request_detail_screen.dart';
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

  String get _roleLabel =>
      widget.user.isFinanceManager ? 'finance_manager' : 'maintenance_manager';

  String get _title =>
      widget.user.isFinanceManager ? 'طلبات الشراء' : 'طلبات الصيانة';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
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
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getRequestsByRole(_roleLabel),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        const Text('حدث خطأ في تحميل الطلبات'),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
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
                docs.sort((a, b) {
                  final p = _priorityValue(a['priority'])
                      .compareTo(_priorityValue(b['priority']));
                  if (p != 0) return p;
                  return (b['createdAt'] as String)
                      .compareTo(a['createdAt'] as String);
                });
                if (_filter != 'all') {
                  docs = docs.where((d) => d['status'] == _filter).toList();
                }
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد طلبات للمراجعة',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'عندما يرسل الأعضاء طلبات جديدة، ستظهر هنا',
                          style: TextStyle(color: Colors.grey[600]),
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r['itemName'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statColor.withValues(alpha: 0.15),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(r['userName'] as String,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      if ((r['quantity'] as num?)?.toInt() != null &&
                          (r['quantity'] as num).toInt() > 1) ...[
                        Icon(Icons.numbers,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('x${(r['quantity'] as num).toInt()}',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600])),
                        const SizedBox(width: 12),
                      ],
                      Icon(Icons.flag_outlined,
                          size: 14, color: priColor),
                      const SizedBox(width: 4),
                      Text(AppTheme.priorityLabel(priority),
                          style: TextStyle(
                              fontSize: 13, color: priColor)),
                      if (priceText != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.attach_money,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(priceText,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600])),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat.yMd().format(
                            DateTime.parse(r['createdAt'])),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        r['category'] == 'purchase'
                            ? Icons.shopping_cart
                            : Icons.build,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        r['category'] == 'purchase' ? 'شراء' : 'صيانة',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}
