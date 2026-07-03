import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/features/auth/login_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً ${widget.user.name}'),
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
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getRequestsByUser(widget.user.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                final requests = docs.where((d) {
                  if (_filter == 'all') return true;
                  return d['status'] == _filter;
                }).toList();
                if (requests.isEmpty) {
                  return const Center(
                    child: Text('لا توجد طلبات بعد'),
                  );
                }
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (_, i) {
                    final r = requests[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _statusColor(r['status']).withValues(alpha: 0.2),
                          child: Icon(
                            r['category'] == 'purchase'
                                ? Icons.shopping_cart
                                : Icons.build,
                            color: _statusColor(r['status']),
                          ),
                        ),
                        title: Text(r['itemName'] as String),
                        subtitle: Text(
                          '${_statusLabel(r['status'])} | ${_priorityLabel(r['priority'])}'
                          ' | ${DateFormat.yMd().format(DateTime.parse(r['createdAt']))}',
                        ),
                        trailing: Chip(
                          label: Text(
                            _statusLabel(r['status']),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              _statusColor(r['status']).withValues(alpha: 0.2),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
        ),
        child: const Icon(Icons.add),
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
