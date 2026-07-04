import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/core/theme.dart';

class RequestDetailScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  final String requestId;
  const RequestDetailScreen({
    super.key,
    required this.requestData,
    required this.requestId,
  });

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final _commentController = TextEditingController();
  final _firestoreService = FirestoreService();
  bool _loading = false;

  void _confirmAndUpdate(String status) {
    final labels = {
      'approved': 'موافقة',
      'rejected': 'رفض',
      'hold': 'تعليق',
      'completed': 'إنجاز',
    };
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${labels[status]} الطلب'),
        content: Text('هل أنت متأكد من ${_actionLabel(status)} هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateStatus(status);
            },
            child: Text(labels[status]!),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String status) async {
    setState(() => _loading = true);
    try {
      await _firestoreService.updateRequestStatus(
        widget.requestId,
        status,
        _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم ${_actionLabel(status)} الطلب')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تحديث الطلب')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _actionLabel(String status) {
    switch (status) {
      case 'approved':
        return 'الموافقة على';
      case 'rejected':
        return 'رفض';
      case 'hold':
        return 'تعليق';
      case 'completed':
        return 'إنجاز';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.requestData;
    final status = r['status'] as String;
    final priority = r['priority'] as String;
    final statColor = AppTheme.statusColor(status);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(r['itemName'] as String)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: r['imageUrl'] != null &&
                        (r['imageUrl'] as String).isNotEmpty
                    ? Image.network(
                        r['imageUrl'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: scheme.surfaceContainerLow,
                          child: Icon(Icons.image,
                              size: 64,
                              color: scheme.onSurfaceVariant),
                        ),
                      )
                    : Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.image,
                            size: 64,
                            color: scheme.onSurfaceVariant),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: statColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppTheme.statusLabel(status),
                    style: TextStyle(
                      color: statColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.priorityColor(priority)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    AppTheme.priorityLabel(priority),
                    style: TextStyle(
                      color: AppTheme.priorityColor(priority),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: DecorativeDivider(),
            ),
            const SizedBox(height: 4),
            _infoRow(Icons.person_outline, 'مقدم الطلب', r['userName']),
            _infoRow(
                Icons.category_outlined, 'النوع',
                r['category'] == 'purchase' ? 'شراء' : 'صيانة'),
            _infoRow(Icons.inventory, 'الغرض', r['itemName']),
            if ((r['quantity'] as num?)?.toInt() != null &&
                (r['quantity'] as num?)!.toInt() > 1)
              _infoRow(Icons.numbers, 'الكمية',
                  '${(r['quantity'] as num).toInt()}'),
            if (r['estimatedPrice'] != null &&
                (r['estimatedPrice'] as num) > 0)
              _infoRow(Icons.attach_money, 'السعر التقديري',
                  '${(r['estimatedPrice'] as num).toStringAsFixed(0)} د.ل'),
            if (r['location'] != null && (r['location'] as String).isNotEmpty)
              _infoRow(Icons.location_on, 'الموقع', r['location']),
            if (r['maintenanceItems'] != null &&
                (r['maintenanceItems'] as List).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.checklist, size: 20, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: Text(
                        'المتطلبات:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: (r['maintenanceItems'] as List)
                            .asMap()
                            .entries
                            .map((e) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text('${e.key + 1}. ${e.value}'),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (r['comment'] != null && (r['comment'] as String).isNotEmpty)
              _infoRow(Icons.comment, 'ملاحظات', r['comment']),
            if (r['createdAt'] != null)
              _infoRow(Icons.calendar_today, 'التاريخ',
                  _formatDate(r['createdAt'])),
            if (status == 'pending') ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: DecorativeDivider(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  prefixIcon: Icon(Icons.comment),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _confirmAndUpdate('approved'),
                        icon: const Icon(Icons.check),
                        label: const Text('موافقة'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _confirmAndUpdate('hold'),
                            icon: const Icon(Icons.pause),
                            label: const Text('تعليق'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmAndUpdate('rejected'),
                            icon: const Icon(Icons.close),
                            label: const Text('رفض'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
            if (status == 'approved') ...[
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: DecorativeDivider(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : () => _confirmAndUpdate('completed'),
                  icon: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.task_alt),
                  label: const Text('تم - إنجاز الطلب'),
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.tertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is String) {
      return date.substring(0, 10);
    }
    if (date is Timestamp) {
      return date.toDate().toString().substring(0, 10);
    }
    return '$date';
  }

  Widget _infoRow(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
