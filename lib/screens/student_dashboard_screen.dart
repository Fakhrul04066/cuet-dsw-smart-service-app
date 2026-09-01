import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'character_certificate_screen.dart';
import 'complaint_screen.dart';
import 'hall_transfer_screen.dart';
import 'login_screen.dart';
import 'my_applications_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late Future<StudentUser?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.instance.getCurrentUserProfile();
  }

  void _reloadProfile() {
    if (!mounted) return;
    setState(() {
      _profileFuture = AuthService.instance.getCurrentUserProfile();
    });
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _open(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    _reloadProfile();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Student Dashboard'),
          actions: [
            StreamBuilder<int>(
              stream: NotificationService.instance.streamUnreadCount(),
              builder: (context, snapshot) => IconButton(
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: (snapshot.data ?? 0) > 0,
                  label: Text('${snapshot.data ?? 0}'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => _open(context, const NotificationsScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
              onPressed: () => _signOut(context),
            ),
          ],
        ),
        body: FutureBuilder<StudentUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load your profile.'));
            }
            final profile = snapshot.data;
            if (profile == null) {
              return const Center(child: Text('Student profile is unavailable.'));
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _ProfileSummary(
                  profile: profile,
                  onEdit: () => _openProfile(context),
                ),
                const SizedBox(height: 28),
                const _SectionHeading(
                  title: 'Services',
                  subtitle: 'Start an official DSW service request',
                ),
                const SizedBox(height: 12),
                _DashboardCard(
                  icon: Icons.description_outlined,
                  title: 'Character Certificate',
                  subtitle: 'Apply and track your certificate',
                  onTap: () => _open(context, const CharacterCertificateScreen()),
                ),
                _DashboardCard(
                  icon: Icons.home_work_outlined,
                  title: 'Hall Transfer',
                  subtitle: 'Submit and track a hall transfer request',
                  onTap: () => _open(context, const HallTransferScreen()),
                ),
                const SizedBox(height: 14),
                const _SectionHeading(
                  title: 'Personal Activity',
                  subtitle: 'Access your applications and complaints',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActivityCard(
                        icon: Icons.assignment_outlined,
                        title: 'My Applications',
                        onTap: () => _open(context, const MyApplicationsScreen()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActivityCard(
                        icon: Icons.report_problem_outlined,
                        title: 'Online Complaint',
                        onTap: () => _open(context, const ComplaintScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DashboardCard(
                  icon: Icons.history_outlined,
                  title: 'My Complaints',
                  subtitle: 'Track submitted complaints and responses',
                  onTap: () => _open(context, const ComplaintHistoryScreen()),
                ),
              ],
            );
          },
        ),
      );
}

class _ProfileSummary extends StatelessWidget {
  final StudentUser profile;
  final VoidCallback onEdit;

  const _ProfileSummary({required this.profile, required this.onEdit});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Text(
                      profile.name.isEmpty ? '?' : profile.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profile.name.isEmpty ? 'Student' : profile.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit profile',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  _ProfileDetail(label: 'Student ID', value: profile.studentId),
                  _ProfileDetail(label: 'Department', value: profile.department),
                  if (profile.hall.isNotEmpty)
                    _ProfileDetail(label: 'Hall', value: profile.hall),
                  if (profile.phone.isNotEmpty)
                    _ProfileDetail(label: 'Mobile', value: profile.phone),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ProfileDetail extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value.isEmpty ? 'Not provided' : value),
        ],
      );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon),
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
        ),
      );
}
