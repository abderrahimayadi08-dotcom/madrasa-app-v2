import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/features/auth/login_screen.dart';
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'hold':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _filterChip('all', 'الكل'),
                const SizedBox(width: 8),
                _filterChip('pending', 'قيد المراجعة'),
                const SizedBox(width: 8),
                _filterChip('approved', 'موافق'),
                const SizedBox(width: 8),
                _filterChip('rejected', 'مرفوض'),
                const SizedBox(width: 8),
                _filterChip('hold', 'معلق'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getRequestsByRole(_roleLabel),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs.toList();
                docs.sort((a, b) =>
                    _priorityValue(a['priority']).compareTo(
                        _priorityValue(b['priority'])));
                if (_filter != 'all') {
                  docs = docs.where((d) => d['status'] == _filter).toList();
                }
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد طلبات'),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final r = docs[i];
                    final statusLabel = _statusLabel(r['status']);
                    final priorityLabel = _priorityLabel(r['priority']);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(r['status']).withValues(alpha: 0.2),
                          child: Icon(
                            Icons.circle,
                            color: _priorityColor(r['priority']),
                            size: 16,
                          ),
                        ),
                        title: Text(r['itemName'] as String),
                        subtitle: Text(
                          '${r['userName']} | $priorityLabel'
                          ' | ${_priceText(r)}'
                          ' | ${DateFormat.yMd().format(DateTime.parse(r['createdAt']))}',
                        ),
                        trailing: Chip(
                          label: Text(
                            statusLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              _statusColor(r['status']).withValues(alpha: 0.2),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RequestDetailScreen(
                              requestData: r.data() as Map<String, dynamic>,
                              requestId: r.id,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'عاجل';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return priority;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'hold':
        return 'معلق';
      default:
        return status;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'urgent':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _priceText(QueryDocumentSnapshot r) {
    final price = r['estimatedPrice'];
    if (price == null || price == 0) return '';
    return '${price.toStringAsFixed(0)} د.ل';
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
