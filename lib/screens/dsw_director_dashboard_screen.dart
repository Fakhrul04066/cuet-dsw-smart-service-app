import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/application.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/character_certificate_service.dart';
import '../services/complaint_service_data.dart';
import '../services/hall_transfer_service.dart';
import '../services/notification_service.dart';
import '../widgets/status_chip.dart';
import 'analytics_dashboard_screen.dart';
import 'application_details_screen.dart';
import 'complaint_management_screen.dart';
import 'notifications_screen.dart';
import 'service_request_management_screen.dart';
import 'student_registry_management_screen.dart';

class DSWDirectorDashboardScreen extends StatefulWidget {
  const DSWDirectorDashboardScreen({super.key});

  @override
  State<DSWDirectorDashboardScreen> createState() =>
      _DSWDirectorDashboardScreenState();
}

class _DSWDirectorDashboardScreenState extends State<DSWDirectorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<_DirectorData> _dataFuture;
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

  Future<_DirectorData> _loadData() async {
    final queues = await Future.wait([
      CharacterCertificateService.instance.getDirectorQueue(),
      HallTransferService.instance.getDirectorQueue(),
    ]);
    final applications = [...queues[0], ...queues[1]]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final complaints = await ComplaintServiceData.instance.getAllComplaints();
    return _DirectorData(applications: applications, complaints: complaints);
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    final nextFuture = _loadData();
    setState(() {
      _dataFuture = nextFuture;
    });

    try {
      await nextFuture;
    } catch (_) {
      // FutureBuilder displays the loading error in the dashboard.
    }
  }

  Future<void> _decision(Application application, String decision) async {
    if (decision == 'issue_certificate') {
      await _run(
        () => CharacterCertificateService.instance.directorDecision(
          applicationId: application.id,
          decision: decision,
        ),
      );
      return;
    }

    final note = await _askForNote(
      title: decision == 'approve' ? 'Approve application' : 'Reject application',
      button: decision == 'approve' ? 'Approve' : 'Reject',
    );
    if (note == null || !mounted) return;

    await _run(() async {
      if (application.type == HallTransferService.applicationType) {
        await HallTransferService.instance.directorDecision(
          applicationId: application.id,
          decision: decision,
          comment: note,
        );
      } else {
        await CharacterCertificateService.instance.directorDecision(
          applicationId: application.id,
          decision: decision,
          comment: note,
        );
      }
    });
  }

  Future<String?> _askForNote({
    required String title,
    required String button,
  }) async {
    var draft = '';
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Official Director note'),
          onChanged: (value) => draft = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final note = draft.trim();
              if (note.isEmpty) return;
              Navigator.of(dialogContext).pop(note);
            },
            child: Text(button),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return result;
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      String message = error.toString();
      if (error is FirebaseException) {
        message = 'Firebase Error [${error.code}]: ${error.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('DSW Director Dashboard'),
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
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: 'Service request oversight',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServiceRequestManagementScreen(
                    directorMode: true,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: 'Analytics',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AnalyticsDashboardScreen(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.support_agent_outlined),
              tooltip: 'Complaints',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ComplaintManagementScreen(
                    director: true,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Logout',
              onPressed: () => AuthService.instance.signOut(),
            ),
          ],
        ),
        body: FutureBuilder<_DirectorData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load Director dashboard: ${snapshot.error}',
                ),
              );
            }

            final data = snapshot.data!;
            final waitingDirector = data.applications
                .where((item) => item.status == 'OFFICER_REVIEW_COMPLETE')
                .length;
            final approved = data.applications
                .where(
                  (item) =>
                      ['APPROVED', 'CERTIFICATE_ISSUED'].contains(item.status),
                )
                .length;
            final rejected = data.applications
                .where((item) => item.status == 'REJECTED')
                .length;
            final complaintsWaiting = data.complaints
                .where((item) => item.status == 'OFFICER_REVIEW_COMPLETE')
                .length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Text(
                    'Director overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Requests first go to DSW Officers. The Director acts after an Officer completes the information review.',
                  ),
                  const SizedBox(height: 18),
                  _SummaryGrid(
                    items: [
                      (
                        'Applications waiting',
                        waitingDirector,
                        Icons.pending_actions_outlined,
                      ),
                      ('Approved', approved, Icons.check_circle_outline),
                      ('Rejected', rejected, Icons.cancel_outlined),
                      (
                        'Complaints waiting',
                        complaintsWaiting,
                        Icons.report_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Applications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  TabBar(
                    controller: _tabs,
                    tabs: const [
                      Tab(text: 'Character Certificate'),
                      Tab(text: 'Hall Transfer'),
                    ],
                  ),
                  SizedBox(
                    height: 470,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _DirectorApplicationList(
                          applications: data.applications
                              .where(
                                (item) =>
                                    item.type == 'character_certificate',
                              )
                              .toList(),
                          onDecision: _decision,
                        ),
                        _DirectorApplicationList(
                          applications: data.applications
                              .where(
                                (item) =>
                                    item.type ==
                                    HallTransferService.applicationType,
                              )
                              .toList(),
                          onDecision: _decision,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DashboardLink(
                    title: 'Unified service request oversight',
                    subtitle:
                        'Make final decisions after Officer review is complete',
                    icon: Icons.inbox_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServiceRequestManagementScreen(
                          directorMode: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DashboardLink(
                    title: 'Complaints',
                    subtitle:
                        '$complaintsWaiting complaints are ready for Director action',
                    icon: Icons.support_agent_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComplaintManagementScreen(
                          director: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DashboardLink(
                    title: 'AI analytics',
                    subtitle: 'KPIs and advisory management insights',
                    icon: Icons.analytics_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsDashboardScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DashboardLink(
                    title: 'Student registry management',
                    subtitle: 'Manage students allowed to create accounts',
                    icon: Icons.badge_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const StudentRegistryManagementScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _DirectorApplicationList extends StatelessWidget {
  final List<Application> applications;
  final Future<void> Function(Application, String) onDecision;

  const _DirectorApplicationList({
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
        final actions = <Widget>[];

        if (application.status == 'OFFICER_REVIEW_COMPLETE') {
          actions.addAll([
            FilledButton.tonal(
              onPressed: () => onDecision(application, 'approve'),
              child: const Text('Approve'),
            ),
            OutlinedButton(
              onPressed: () => onDecision(application, 'reject'),
              child: const Text('Reject'),
            ),
          ]);
        } else if (application.status == 'SUBMITTED' ||
            application.status == 'RESUBMITTED') {
          actions.add(
            const Chip(label: Text('Waiting for Officer review')),
          );
        } else if (application.status == 'CORRECTION_REQUIRED') {
          actions.add(
            const Chip(label: Text('Waiting for student resubmission')),
          );
        }

        if (application.type == 'character_certificate' &&
            application.status == 'APPROVED') {
          actions.add(
            FilledButton.icon(
              onPressed: () => onDecision(application, 'issue_certificate'),
              icon: const Icon(Icons.workspace_premium_outlined),
              label: const Text('Issue Certificate'),
            ),
          );
        }

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
                    application.type == HallTransferService.applicationType
                        ? '${application.studentId}\n${application.currentHall ?? '-'} → ${application.requestedHall ?? '-'}'
                        : '${application.studentId}\n${application.purpose}',
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
                if (application.officerComment?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Officer review: ${application.officerComment}',
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

class _DirectorData {
  final List<Application> applications;
  final List<Complaint> complaints;
  const _DirectorData({required this.applications, required this.complaints});
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
