import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/theme.dart';
import 'package:madrasa_app/core/services/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _colorOptions = [
  ColorOption('أخضر', Color(0xFF1B5E20)),
  ColorOption('أزرق', Color(0xFF0D47A1)),
  ColorOption('بني', Color(0xFF4E342E)),
  ColorOption('بنفسجي', Color(0xFF4A148C)),
  ColorOption('أحمر', Color(0xFFB71C1C)),
];

class ColorOption {
  final String label;
  final Color color;
  const ColorOption(this.label, this.color);
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _adminPasswordController = TextEditingController();
  final _auth = auth.FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _adminMode = false;
  bool _adminLoading = false;
  List<Map<String, dynamic>> _users = [];
  Color _selectedColor = _colorOptions[0].color;

  @override
  void initState() {
    super.initState();
    _loadColor();
  }

  Future<void> _loadColor() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt('themeColor');
    if (val != null) {
      setState(() => _selectedColor = Color(val));
    }
  }

  Future<void> _setColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color.value);
    AppTheme.seedNotifier.value = color;
    setState(() => _selectedColor = color);
  }

  void _enterAdminMode() async {
    final password = _adminPasswordController.text.trim();
    if (password.isEmpty) return;
    setState(() => _adminLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        _showError('يجب تسجيل الدخول أولاً');
        return;
      }
      await user.reauthenticateWithCredential(
        auth.EmailAuthProvider.credential(email: user.email!, password: password),
      );
      if (!mounted) return;
      final snapshot = await _firestore.collection('users').get();
      _users = snapshot.docs.map((d) => d.data()).toList();
      setState(() => _adminMode = true);
    } on auth.FirebaseAuthException catch (e) {
      _showError(e.message ?? 'كلمة السر خطأ');
    } catch (e) {
      Logger.error('Admin auth error: $e');
      _showError('خطأ: ${e.toString().length > 60 ? e.toString().substring(0, 60) : e.toString()}');
    } finally {
      if (mounted) setState(() => _adminLoading = false);
    }
  }

  Future<void> _updateRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({'role': newRole});
      final idx = _users.indexWhere((u) => u['id'] == userId);
      if (idx != -1) {
        setState(() => _users[idx]['role'] = newRole);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث المهمة')),
      );
    } catch (e) {
      Logger.error('Role update error: $e');
      _showError('فشل تحديث المهمة');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _adminPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _sectionHeader(Icons.palette_outlined, 'الألوان'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _colorOptions.map((opt) {
              final selected = _selectedColor.value == opt.color.value;
              return ChoiceChip(
                label: Text(opt.label),
                selected: selected,
                selectedColor: opt.color.withValues(alpha: 0.25),
                onSelected: (_) => _setColor(opt.color),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          _sectionHeader(Icons.email_outlined, 'البريد الإلكتروني'),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: _auth.currentUser?.email ?? ''),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
            ),
            enabled: false,
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: DecorativeDivider(),
          ),
          const SizedBox(height: 8),
          _sectionHeader(Icons.admin_panel_settings, 'إدارة المهام'),
          const SizedBox(height: 4),
          Text('أدخل كلمة السر للدخول إلى لوحة إدارة المهام',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
          const SizedBox(height: 14),
          if (!_adminMode)
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _adminPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة السر',
                        prefixIcon: Icon(Icons.lock_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _adminLoading ? null : _enterAdminMode,
                        icon: _adminLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.admin_panel_settings),
                        label: const Text('دخول'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_adminMode) ...[
            const SizedBox(height: 16),
            Text('قائمة المستخدمين',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                )),
            const SizedBox(height: 10),
            ..._users.map((u) => _userCard(u)),
          ],
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: DecorativeDivider(),
          ),
          _sectionHeader(Icons.info_outline, 'معلومات التقنية'),
          const SizedBox(height: 8),
          Text('المشروع: ${_firestore.app.options.projectId}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text('البريد: ${_auth.currentUser?.email ?? '—'}',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
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

  Widget _userCard(Map<String, dynamic> u) {
    final roles = ['member', 'finance_manager', 'maintenance_manager', 'general_manager'];
    final labels = {
      'member': 'عضو',
      'finance_manager': 'مدير مالية',
      'maintenance_manager': 'مدير صيانة',
      'general_manager': 'مدير عام',
    };
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                (u['name'] as String).isNotEmpty
                    ? (u['name'] as String)[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(u['email'] as String,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            DropdownButton<String>(
              value: u['role'] as String,
              items: roles.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(labels[r] ?? r, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (newRole) {
                if (newRole != null) _updateRole(u['id'], newRole);
              },
              underline: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
