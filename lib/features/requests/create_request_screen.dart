import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madrasa_app/core/models/request_model.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/core/services/logger.dart';
import 'package:madrasa_app/core/services/auth_service.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  String _category = 'purchase';
  String _priority = 'medium';
  XFile? _selectedImage;
  bool _loading = false;
  final List<TextEditingController> _maintenanceControllers = [];

  @override
  void initState() {
    super.initState();
    _maintenanceControllers.add(TextEditingController());
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _selectedImage = file);
  }

  void _addMaintenanceItem() {
    setState(() => _maintenanceControllers.add(TextEditingController()));
  }

  void _removeMaintenanceItem(int i) {
    if (_maintenanceControllers.length <= 1) return;
    _maintenanceControllers[i].dispose();
    setState(() => _maintenanceControllers.removeAt(i));
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم الغرض');
      return;
    }
    if (_category == 'maintenance') {
      final items = _maintenanceControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (items.isEmpty) {
        _showError('يرجى إضافة متطلب صيانة واحد على الأقل');
        return;
      }
    }
    final user = await _authService.getCurrentUser();
    if (user == null) {
      _showError('يجب تسجيل الدخول أولاً');
      return;
    }
    final price = double.tryParse(_priceController.text);
    if (price == null && _category == 'purchase') {
      _showError('يرجى إدخال سعر تقديري صحيح');
      return;
    }
    final qty = int.tryParse(_quantityController.text) ?? 1;
    if (qty < 1) {
      _showError('الكمية يجب أن تكون 1 على الأقل');
      return;
    }
    setState(() => _loading = true);
    try {
      final maintenanceItems = _maintenanceControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final request = RequestModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        userName: user.name,
        category: _category,
        itemName: _nameController.text.trim(),
        imageUrl: _selectedImage?.path ?? '',
        estimatedPrice: price ?? 0,
        quantity: qty,
        location:
            _category == 'maintenance' ? _locationController.text.trim() : null,
        maintenanceItems:
            _category == 'maintenance' ? maintenanceItems : [],
        priority: _priority,
        status: 'pending',
        assignedRole:
            _category == 'purchase' ? 'finance_manager' : 'maintenance_manager',
        createdAt: DateTime.now(),
      );
      await _firestoreService.createRequest(request);
      Logger.info('Request submitted: ${request.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      Logger.error('Submit error: $e');
      _showError('فشل إرسال الطلب');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    for (final c in _maintenanceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلب جديد')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نوع الطلب',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'purchase',
                    label: Text('شراء'),
                    icon: Icon(Icons.shopping_cart),
                  ),
                  ButtonSegment(
                    value: 'maintenance',
                    label: Text('صيانة'),
                    icon: Icon(Icons.build),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (v) =>
                    setState(() => _category = v.first),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText:
                      _category == 'purchase' ? 'اسم الغرض' : 'وصف العطل',
                  prefixIcon: const Icon(Icons.inventory),
                ),
              ),
              if (_category == 'purchase') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'الكمية',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'السعر التقديري (د.ل)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (_category == 'maintenance') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'موقع العطل',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 20),
                Text('متطلبات الصيانة',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(_maintenanceControllers.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _maintenanceControllers[i],
                            decoration: InputDecoration(
                              labelText: 'متطلب ${i + 1}',
                              prefixIcon: const Icon(Icons.checklist),
                            ),
                          ),
                        ),
                        if (_maintenanceControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () => _removeMaintenanceItem(i),
                          ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: _addMaintenanceItem,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة متطلب آخر'),
                ),
              ],
              const SizedBox(height: 20),
              Text('درجة الأهمية',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'urgent',
                    label: Text('عاجل'),
                    icon: Icon(Icons.error_outline),
                  ),
                  ButtonSegment(
                    value: 'medium',
                    label: Text('متوسط'),
                    icon: Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: 'low',
                    label: Text('منخفض'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                ],
                selected: {_priority},
                onSelectionChanged: (v) =>
                    setState(() => _priority = v.first),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.surfaceContainerLow,
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  size: 40,
                                  color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text(
                                'إضافة صورة',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(_loading ? 'جاري الإرسال...' : 'إرسال الطلب'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
