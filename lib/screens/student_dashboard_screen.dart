import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'character_certificate_screen.dart';
import 'complaint_screen.dart';
import 'hall_transfer_screen.dart';
import 'login_screen.dart';
import 'my_applications_screen.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school_rounded, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Student Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose a service to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CharacterCertificateScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Character Certificate'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HallTransferScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.home_work_outlined),
                    label: const Text('Hall Transfer'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ComplaintScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.report_problem_outlined),
                    label: const Text('Online Complaint'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyApplicationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_rounded),
                    label: const Text('My Applications'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
