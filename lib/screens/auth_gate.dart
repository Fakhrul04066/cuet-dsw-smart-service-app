import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'dsw_director_dashboard_screen.dart';
import 'dsw_officer_dashboard_screen.dart';
import 'login_screen.dart';
import 'student_dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authState;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authState = AuthService.instance.authStateChanges;
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      final profile = await AuthService.instance.getCurrentUserProfile();
      if (!mounted) return;
      if (profile == null) {
        setState(() => _isLoading = false);
        return;
      }
      setState(() => _isLoading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return const _LoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return FutureBuilder<StudentUser?>(
          future: AuthService.instance.getCurrentUserProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            if (profileSnapshot.hasError || profileSnapshot.data == null) {
              return const _AuthErrorScreen(
                message:
                    'Missing user profile document. Please contact support.',
              );
            }

            final role = StudentUser.normalizeRole(profileSnapshot.data!.role);
            switch (role) {
              case 'student':
                return const StudentDashboardScreen();
              case 'dsw_officer':
                return const DSWOfficerDashboardScreen();
              case 'dsw_director':
                return const DSWDirectorDashboardScreen();
              default:
                return const _AuthErrorScreen(
                  message: 'Unknown or invalid role in user profile.',
                );
            }
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your account...'),
          ],
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final String message;

  const _AuthErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 52),
                const SizedBox(height: 16),
                Text(
                  'Access Error',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Return to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
