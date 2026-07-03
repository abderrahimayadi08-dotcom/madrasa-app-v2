import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/models/user_model.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/logger.dart';
import 'package:madrasa_app/features/auth/register_screen.dart';
import 'package:madrasa_app/features/dashboard/dashboard_screen.dart';
import 'package:madrasa_app/features/requests/my_requests_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  void _login() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      if (user != null) {
        _navigateHome(user);
      } else {
        _showError('المستخدم غير موجود');
      }
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e.code));
    } catch (e) {
      Logger.error('Login error: $e');
      _showError('حدث خطأ، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل';
      case 'wrong-password':
        return 'كلمة المرور خاطئة';
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة';
      default:
        return 'خطأ في تسجيل الدخول';
    }
  }

  void _navigateHome(UserModel user) {
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('دخول'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('إنشاء حساب جديد'),
            ),
          ],
        ),
      ),
    );
  }
}
