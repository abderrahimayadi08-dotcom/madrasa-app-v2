import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:madrasa_app/core/models/request_model.dart';
import 'package:madrasa_app/core/services/firestore_service.dart';
import 'package:madrasa_app/core/services/logger.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/theme.dart';

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
  final _notesController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  String _category = 'purchase';
  String _priority = 'medium';
  XFile? _selectedImage;
  bool _loading = false;
  bool _priceUnknown = false;
  final List<TextEditingController> _maintenanceControllers = [];

  @override
  void initState() {
    super.initState();
    _maintenanceControllers.add(TextEditingController());
  }

  Future<void> _pickImageSource(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file != null) setState(() => _selectedImage = file);
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('اختيار صورة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImageSource(ImageSource.camera);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('الكاميرا'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImageSource(ImageSource.gallery);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('المعرض'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    final price = _priceUnknown ? null : double.tryParse(_priceController.text);
    if (price == null && !_priceUnknown && _category == 'purchase') {
      _showError('يرجى إدخال سعر تقديري أو اختيار "غير معروف"');
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
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
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
      _showError('فشل إرسال الطلب: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}');
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
    _notesController.dispose();
    for (final c in _maintenanceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('طلب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(Icons.category_outlined, 'نوع الطلب'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
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
            ),
            const SizedBox(height: 24),
            _sectionHeader(Icons.inventory, 'التفاصيل'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText:
                    _category == 'purchase' ? 'اسم الغرض' : 'وصف العطل',
                prefixIcon: const Icon(Icons.inventory),
              ),
            ),
            if (_category == 'purchase') ...[
              const SizedBox(height: 14),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'الكمية',
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceController,
                      enabled: !_priceUnknown,
                      decoration: InputDecoration(
                        labelText: 'السعر التقديري (د.ل)',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('غير معروف'),
                    selected: _priceUnknown,
                    onSelected: (v) => setState(() => _priceUnknown = v),
                  ),
                ],
              ),
            ],
            if (_category == 'maintenance') ...[
              const SizedBox(height: 14),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'موقع العطل',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 20),
              _sectionHeader(Icons.checklist, 'متطلبات الصيانة'),
              const SizedBox(height: 10),
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
            _sectionHeader(Icons.notes_outlined, 'ملاحظة'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات إضافية (اختياري)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _sectionHeader(Icons.flag_outlined, 'درجة الأهمية'),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
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
            ),
            const SizedBox(height: 20),
            _sectionHeader(Icons.add_photo_alternate, 'صورة (اختياري)'),
            const SizedBox(height: 10),
            InkWell(
              onTap: _showImagePicker,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outline),
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.surfaceContainerLow,
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate,
                                size: 40,
                                color: scheme.onSurfaceVariant),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط لاختيار صورة',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'كاميرا أو معرض',
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),
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
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            )),
      ],
    );
  }
}
