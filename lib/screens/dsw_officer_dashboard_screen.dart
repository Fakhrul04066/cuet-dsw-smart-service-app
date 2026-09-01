import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/character_certificate_service.dart';
import '../services/complaint_service_data.dart';
import '../services/hall_transfer_service.dart';
import '../services/notification_service.dart';
import '../widgets/status_chip.dart';
import 'application_details_screen.dart';
import 'complaint_management_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class DSWOfficerDashboardScreen extends StatefulWidget {
  const DSWOfficerDashboardScreen({super.key});
  @override
  State<DSWOfficerDashboardScreen> createState() =>
      _DSWOfficerDashboardScreenState();
}

class _DSWOfficerDashboardScreenState extends State<DSWOfficerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<_OfficerData> _dataFuture;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<_OfficerData> _loadData() async {
    final queues = await Future.wait([
      CharacterCertificateService.instance.getOfficerQueue(),
      HallTransferService.instance.getOfficerQueue(),
    ]);
    final applications = [...queues[0], ...queues[1]]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final complaints = await ComplaintServiceData.instance.getAllComplaints();
    for (final application in applications) {
      await NotificationService.instance.createForCurrentUserIfMissing(
        title: 'New application',
        message:
            'A ${application.type.replaceAll('_', ' ')} needs officer attention.',
        type: 'new_application',
        referenceId: application.id,
      );
    }
    for (final complaint in complaints) {
      final urgent =
          complaint.priority == 'URGENT' || complaint.priority == 'HIGH';
      await NotificationService.instance.createForCurrentUserIfMissing(
        title: urgent ? 'Urgent complaint' : 'New complaint',
        message: '${complaint.title} is available for review.',
        type: urgent ? 'urgent_complaint' : 'new_complaint',
        referenceId: complaint.id,
      );
    }
    return _OfficerData(applications: applications, complaints: complaints);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _dataFuture = _loadData();
    });
  }

  Future<void> _handleDecision(Application application, String decision) async {
    final comment = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(_decisionTitle(decision)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add a comment',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (comment == null) {
      return;
    }
    if ((decision == 'request_correction' || decision == 'reject') &&
        comment.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A reason is required for this action.'),
          ),
        );
      }
      return;
    }
    try {
      if (application.type == HallTransferService.applicationType) {
        if (decision == 'review') {
          await HallTransferService.instance.reviewForOfficer(application.id);
        } else {
          await HallTransferService.instance.officerDecision(
            applicationId: application.id,
            decision: decision,
            comment: comment.isEmpty ? null : comment,
          );
        }
      } else if (decision == 'review') {
        await CharacterCertificateService.instance.reviewApplicationForOfficer(
          application.id,
        );
      } else {
        await CharacterCertificateService.instance.officerDecision(
          applicationId: application.id,
          decision: decision,
          comment: comment.isEmpty ? null : comment,
        );
      }
      if (!mounted) return;
      _refresh();
    } catch (error) {
      if (mounted) {
        String errorMessage = error.toString();
        if (error is FirebaseException) {
          errorMessage = 'Firebase Error [${error.code}]: ${error.message}';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  String _decisionTitle(String decision) => switch (decision) {
    'review' => 'Review Application',
    'request_correction' => 'Request Correction',
    'reject' => 'Reject Application',
    'approve' => 'Approve Application',
    _ => 'Update Application',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('DSW Officer Dashboard'),
      actions: [
        _NotificationAction(),
        IconButton(
          icon: const Icon(Icons.support_agent_outlined),
          tooltip: 'Complaints',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ComplaintManagementScreen(),
            ),
          ),
        ),
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
    body: FutureBuilder<_OfficerData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load officer dashboard: ${snapshot.error}'),
          );
        }
        final data = snapshot.data!;
        final pending = data.applications
            .where(
              (item) => [
                'SUBMITTED',
                'OFFICER_REVIEW',
                'CORRECTION_REQUIRED',
              ].contains(item.status),
            )
            .length;
        final high = data.complaints
            .where((item) => ['HIGH', 'URGENT'].contains(item.priority))
            .length;
        final processed = data.applications
            .where(
              (item) => [
                'OFFICER_APPROVED',
                'REJECTED',
                'APPROVED',
              ].contains(item.status),
            )
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              'Officer workspace',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            const Text('Review applications and complaints by priority.'),
            const SizedBox(height: 20),
            _SummaryGrid(
              items: [
                ('Pending applications', pending, Icons.assignment_outlined),
                (
                  'Pending complaints',
                  data.complaints
                      .where(
                        (item) => !['RESOLVED', 'CLOSED'].contains(item.status),
                      )
                      .length,
                  Icons.report_outlined,
                ),
                ('High / urgent', high, Icons.priority_high_rounded),
                (
                  'Recently processed',
                  processed.length,
                  Icons.task_alt_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Applications', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Character Certificate'),
                Tab(text: 'Hall Transfer'),
              ],
            ),
            SizedBox(
              height: 430,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _ApplicationList(
                    applications: data.applications
                        .where((item) => item.type == 'character_certificate')
                        .toList(),
                    onDecision: _handleDecision,
                  ),
                  _ApplicationList(
                    applications: data.applications
                        .where(
                          (item) =>
                              item.type == HallTransferService.applicationType,
                        )
                        .toList(),
                    onDecision: _handleDecision,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DashboardLink(
              title: 'Complaints',
              subtitle: '$high high or urgent complaints',
              icon: Icons.support_agent_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ComplaintManagementScreen(),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _NotificationAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: NotificationService.instance.streamUnreadCount(),
    builder: (context, snapshot) => IconButton(
      tooltip: 'Notifications',
      icon: Badge(
        isLabelVisible: (snapshot.data ?? 0) > 0,
        label: Text('${snapshot.data ?? 0}'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
    ),
  );
}

class _OfficerData {
  final List<Application> applications;
  final List<Complaint> complaints;
  const _OfficerData({required this.applications, required this.complaints});
}

class _SummaryGrid extends StatelessWidget {
  final List<(String, int, IconData)> items;
  const _SummaryGrid({required this.items});
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.45,
    children: items
        .map(
          (item) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(item.$3, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${item.$2}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(item.$1, maxLines: 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .toList(),
  );
}

class _ApplicationList extends StatelessWidget {
  final List<Application> applications;
  final Future<void> Function(Application, String) onDecision;
  const _ApplicationList({
    required this.applications,
    required this.onDecision,
  });
  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const Center(child: Text('No applications in this category.'));
    }
    return ListView.builder(
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        final actions =
            application.status == 'SUBMITTED' ||
                application.status == 'CORRECTION_REQUIRED'
            ? <Widget>[
                OutlinedButton(
                  onPressed: () => onDecision(application, 'review'),
                  child: const Text('Start review'),
                ),
              ]
            : <Widget>[
                OutlinedButton(
                  onPressed: () =>
                      onDecision(application, 'request_correction'),
                  child: const Text('Request correction'),
                ),
                OutlinedButton(
                  onPressed: () => onDecision(application, 'reject'),
                  child: const Text('Reject'),
                ),
                FilledButton(
                  onPressed: () => onDecision(application, 'approve'),
                  child: const Text('Approve'),
                ),
              ];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(application.id),
                  subtitle: Text(
                    '${application.studentId}\n${application.purpose}',
                  ),
                  isThreeLine: true,
                  trailing: StatusChip(label: application.status),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ApplicationDetailsScreen(application: application),
                    ),
                  ),
                ),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardLink extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _DashboardLink({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}
