import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:madrasa_app/features/auth/auth_gate.dart';
import 'package:madrasa_app/features/settings/settings_screen.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً ${widget.user.name}'),
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
                docs.sort((a, b) => (b['createdAt'] as String)
                    .compareTo(a['createdAt'] as String));
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
                              size: 72, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'لا توجد طلبات بعد',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اضغط على الزر (+) في الأسفل\nلإرسال طلب شراء أو صيانة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
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
                      final r = requests[i];
                      return _requestCard(r);
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
    final status = r['status'] as String;
    final priority = r['priority'] as String;
    final priColor = AppTheme.priorityColor(priority);
    final statColor = AppTheme.statusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
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
                    Icon(
                      r['category'] == 'purchase'
                          ? Icons.shopping_cart
                          : Icons.build,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
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
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMd().format(
                          DateTime.parse(r['createdAt'])),
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
