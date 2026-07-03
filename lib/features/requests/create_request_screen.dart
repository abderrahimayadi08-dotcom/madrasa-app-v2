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
  final _locationController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _picker = ImagePicker();

  String _category = 'purchase';
  String _priority = 'medium';
  XFile? _selectedImage;
  bool _loading = false;

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _selectedImage = file);
  }

  void _submit() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم الغرض');
      return;
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
    setState(() => _loading = true);
    try {
      final request = RequestModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        userName: user.name,
        category: _category,
        itemName: _nameController.text.trim(),
        imageUrl: _selectedImage?.path ?? '',
        estimatedPrice: price ?? 0,
        location: _category == 'maintenance' ? _locationController.text.trim() : null,
        priority: _priority,
        status: 'pending',
        assignedRole: _category == 'purchase' ? 'finance_manager' : 'maintenance_manager',
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
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('purchase', 'شراء', Icons.shopping_cart),
      ('maintenance', 'صيانة', Icons.build),
    ];
    final priorities = [
      ('urgent', 'عاجل', Colors.red),
      ('medium', 'متوسط', Colors.orange),
      ('low', 'منخفض', Colors.green),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('طلب جديد')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نوع الطلب', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: categories.map((c) {
                  final selected = _category == c.$1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: c.$1 == 'purchase' ? 8 : 0,
                      ),
                      child: FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(c.$3, size: 18),
                            const SizedBox(width: 4),
                            Text(c.$2),
                          ],
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = c.$1),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _category == 'purchase' ? 'اسم الغرض' : 'وصف العطل',
                  prefixIcon: const Icon(Icons.inventory),
                ),
              ),
              if (_category == 'purchase') ...[
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
              ],
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40),
                              Text('إضافة صورة'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('درجة الأهمية', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: priorities.map((p) {
                  final selected = _priority == p.$1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: p.$1 != 'low' ? 8 : 0,
                      ),
                      child: FilterChip(
                        label: Text(p.$2),
                        selected: selected,
                        selectedColor: p.$3.withValues(alpha: 0.3),
                        onSelected: (_) => setState(() => _priority = p.$1),
                      ),
                    ),
                  );
                }).toList(),
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
