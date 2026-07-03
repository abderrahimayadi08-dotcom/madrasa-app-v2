import 'package:flutter/material.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(r['itemName'] as String)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: r['imageUrl'] != null && (r['imageUrl'] as String).isNotEmpty
                    ? Image.network(
                        r['imageUrl'],
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            _infoRow('مقدم الطلب', r['userName']),
            _infoRow('النوع', r['category'] == 'purchase' ? 'شراء' : 'صيانة'),
            _infoRow('الغرض', r['itemName']),
            if (r['estimatedPrice'] != null && (r['estimatedPrice'] as num) > 0)
              _infoRow('السعر التقديري',
                  '${(r['estimatedPrice'] as num).toStringAsFixed(0)} د.ل'),
            if (r['location'] != null && (r['location'] as String).isNotEmpty)
              _infoRow('الموقع', r['location']),
            _infoRow('الأهمية', r['priorityLabel']),
            _infoRow('الحالة', r['statusLabel']),
            if (r['comment'] != null && (r['comment'] as String).isNotEmpty)
              _infoRow('ملاحظات', r['comment']),
            if (r['status'] == 'pending') ...[
              const SizedBox(height: 24),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _updateStatus('approved'),
                        icon: const Icon(Icons.check),
                        label: const Text('موافقة'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _updateStatus('hold'),
                        icon: const Icon(Icons.pause),
                        label: const Text('تعليق'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _updateStatus('rejected'),
                        icon: const Icon(Icons.close),
                        label: const Text('رفض'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
