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
import 'application_details_screen.dart';
import 'complaint_management_screen.dart';
import 'notifications_screen.dart';
import 'service_request_management_screen.dart';

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
    return _OfficerData(applications: applications, complaints: complaints);
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

  Future<void> _handleApplicationAction(
    Application application,
    String action,
  ) async {
    final note = await _askForNote(
      title: action == 'request_correction'
          ? 'Request resubmission'
          : 'Complete Officer review',
      label: action == 'request_correction'
          ? 'What information must the student correct or add?'
          : 'Officer review note / recommendation',
      button: action == 'request_correction'
          ? 'Request resubmission'
          : 'Send to Director',
    );
    if (note == null || !mounted) return;

    try {
      if (application.type == HallTransferService.applicationType) {
        await HallTransferService.instance.officerDecision(
          applicationId: application.id,
          decision: action,
          comment: note,
        );
      } else {
        await CharacterCertificateService.instance.officerDecision(
          applicationId: application.id,
          decision: action,
          comment: note,
        );
      }
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Officer review updated successfully.')),
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

  Future<String?> _askForNote({
    required String title,
    required String label,
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
          decoration: InputDecoration(labelText: label),
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

    // showDialog completes when pop is called, before the route's reverse
    // animation is fully removed. Waiting briefly prevents a Firestore-driven
    // rebuild from tearing down inherited widgets while the dialog route still
    // has dependents, which can trigger `_dependents.isEmpty` in debug mode.
    if (result != null && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('DSW Officer Dashboard'),
          actions: [
            const _NotificationAction(),
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: 'All service requests',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ServiceRequestManagementScreen(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.support_agent_outlined),
              tooltip: 'All complaints',
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
              onPressed: () => AuthService.instance.signOut(),
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
                child: Text(
                  'Unable to load officer dashboard: ${snapshot.error}',
                ),
              );
            }

            final data = snapshot.data!;
            final readyToReview = data.applications
                .where(
                  (item) =>
                      ['SUBMITTED', 'RESUBMITTED'].contains(item.status),
                )
                .length;
            final waitingCorrection = data.applications
                .where((item) => item.status == 'CORRECTION_REQUIRED')
                .length;
            final sentToDirector = data.applications
                .where((item) => item.status == 'OFFICER_REVIEW_COMPLETE')
                .length;
            final urgentComplaints = data.complaints
                .where((item) => ['HIGH', 'URGENT'].contains(item.priority))
                .length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  Text(
                    'Officer review workspace',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Every DSW Officer can see every request. Officers verify information, request resubmission when needed, and send complete reviews to the Director. Only the Director makes final decisions.',
                  ),
                  const SizedBox(height: 18),
                  _SummaryGrid(
                    items: [
                      (
                        'Ready to review',
                        readyToReview,
                        Icons.assignment_outlined,
                      ),
                      (
                        'Waiting resubmission',
                        waitingCorrection,
                        Icons.edit_note_outlined,
                      ),
                      (
                        'Sent to Director',
                        sentToDirector,
                        Icons.forward_to_inbox_outlined,
                      ),
                      (
                        'High / urgent complaints',
                        urgentComplaints,
                        Icons.priority_high_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'All applications',
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
                    height: 430,
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _ApplicationList(
                          applications: data.applications
                              .where(
                                (item) =>
                                    item.type == 'character_certificate',
                              )
                              .toList(),
                          onAction: _handleApplicationAction,
                        ),
                        _ApplicationList(
                          applications: data.applications
                              .where(
                                (item) =>
                                    item.type ==
                                    HallTransferService.applicationType,
                              )
                              .toList(),
                          onAction: _handleApplicationAction,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DashboardLink(
                    title: 'All service requests',
                    subtitle:
                        'Review every request, request resubmission, or send to Director',
                    icon: Icons.inbox_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ServiceRequestManagementScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DashboardLink(
                    title: 'All complaints',
                    subtitle:
                        'Every DSW Officer can review all submitted complaints',
                    icon: Icons.support_agent_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ComplaintManagementScreen(),
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

class _NotificationAction extends StatelessWidget {
  const _NotificationAction();

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

class _ApplicationList extends StatelessWidget {
  final List<Application> applications;
  final Future<void> Function(Application, String) onAction;
  const _ApplicationList({
    required this.applications,
    required this.onAction,
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
        if (['SUBMITTED', 'RESUBMITTED'].contains(application.status)) {
          actions.addAll([
            OutlinedButton(
              onPressed: () =>
                  onAction(application, 'request_correction'),
              child: const Text('Request resubmission'),
            ),
            FilledButton(
              onPressed: () => onAction(application, 'complete_review'),
              child: const Text('Send to Director'),
            ),
          ]);
        } else if (application.status == 'CORRECTION_REQUIRED') {
          actions.add(
            const Chip(label: Text('Waiting for student resubmission')),
          );
        } else if (application.status == 'OFFICER_REVIEW_COMPLETE') {
          actions.add(
            const Chip(label: Text('Waiting for Director decision')),
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
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ),
          ),
        );
      },
    );
  }
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
