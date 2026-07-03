import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/logger.dart';
import 'package:madrasa_app/features/dashboard/dashboard_screen.dart';
import 'package:madrasa_app/features/requests/my_requests_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  String _selectedRole = 'member';
  bool _loading = false;

  void _register() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showError('يرجى ملء جميع الحقول');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                user.isFinanceManager || user.isMaintenanceManager
                    ? DashboardScreen(user: user)
                    : MyRequestsScreen(user: user),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'فشل التسجيل');
    } catch (e) {
      Logger.error('Register error: $e');
      _showError('حدث خطأ، حاول مرة أخرى');
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      ('member', 'عضو'),
      ('finance_manager', 'مدير مالية'),
      ('maintenance_manager', 'مدير صيانة'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'الاسم',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'الدور',
                prefixIcon: Icon(Icons.badge),
              ),
              items: roles
                  .map((r) => DropdownMenuItem(
                      value: r.$1, child: Text(r.$2)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('تسجيل'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
