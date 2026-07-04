import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:madrasa_app/core/services/auth_service.dart';
import 'package:madrasa_app/core/services/logger.dart';
import 'package:madrasa_app/features/auth/login_screen.dart';
import 'package:madrasa_app/features/dashboard/dashboard_screen.dart';
import 'package:madrasa_app/features/requests/my_requests_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<auth.User?>(
      stream: AuthService().authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }
        return FutureBuilder(
          future: AuthService().getCurrentUser(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final userModel = userSnapshot.data;
            if (userModel == null) {
              return const LoginScreen();
            }
            return userModel.isFinanceManager ||
                    userModel.isMaintenanceManager
                ? DashboardScreen(user: userModel)
                : MyRequestsScreen(user: userModel);
          },
        );
      },
    );
  }
}
