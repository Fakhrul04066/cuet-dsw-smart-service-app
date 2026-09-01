import 'package:flutter/material.dart';

import '../models/application.dart';
import '../models/complaint.dart';
import '../services/auth_service.dart';
import '../services/character_certificate_service.dart';
import '../services/hall_transfer_service.dart';
import '../services/complaint_service_data.dart';
import '../services/notification_service.dart';
import '../widgets/status_chip.dart';
import 'application_details_screen.dart';
import 'complaint_management_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';

class DSWDirectorDashboardScreen extends StatefulWidget {
  const DSWDirectorDashboardScreen({super.key});

  @override
  State<DSWDirectorDashboardScreen> createState() =>
      _DSWDirectorDashboardScreenState();
}

class _DirectorSummary extends StatelessWidget {
  final List<(String, int, IconData)> items;
  const _DirectorSummary({required this.items});

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
        final actions = application.status == 'OFFICER_APPROVED'
            ? <Widget>[
                OutlinedButton(
                  onPressed: () => onDecision(application, 'review'),
                  child: const Text('Start review'),
                ),
              ]
            : <Widget>[
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

class _DSWDirectorDashboardScreenState extends State<DSWDirectorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Application>> _queueFuture;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _queueFuture = _loadQueue();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<List<Application>> _loadQueue() async {
    final queues = await Future.wait([
      CharacterCertificateService.instance.getDirectorQueue(),
      HallTransferService.instance.getDirectorQueue(),
    ]);
    final applications = [...queues[0], ...queues[1]];
    applications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final application in applications) {
      await NotificationService.instance.createForCurrentUserIfMissing(
        title: 'Application waiting for review',
        message:
            'A ${application.type.replaceAll('_', ' ')} is waiting for Director review.',
        type: 'director_review',
        referenceId: application.id,
      );
    }
    final complaints = await ComplaintServiceData.instance.getAllComplaints();
    for (final complaint in complaints.where(
      (item) =>
          !['RESOLVED', 'CLOSED'].contains(item.status) &&
          ['URGENT', 'HIGH'].contains(item.priority),
    )) {
      await NotificationService.instance.createForCurrentUserIfMissing(
        title: 'Urgent unresolved complaint',
        message: '${complaint.title} needs Director attention.',
        type: 'urgent_complaint',
        referenceId: complaint.id,
      );
    }
    return applications;
  }

  void _refreshQueue() {
    if (!mounted) return;
    setState(() {
      _queueFuture = _loadQueue();
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
              hintText: 'Add director comment',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (comment == null) {
      return;
    }
    if (decision == 'reject' && comment.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A rejection reason is required.')),
        );
      }
      return;
    }

    try {
      if (application.type == HallTransferService.applicationType) {
        if (decision == 'review') {
          await HallTransferService.instance.reviewForDirector(application.id);
        } else {
          await HallTransferService.instance.directorDecision(
            applicationId: application.id,
            decision: decision,
            comment: comment.isEmpty ? null : comment,
          );
        }
      } else if (decision == 'review') {
        await CharacterCertificateService.instance.reviewApplicationForDirector(
          application.id,
        );
      } else {
        await CharacterCertificateService.instance.directorDecision(
          applicationId: application.id,
          decision: decision,
          comment: comment.isEmpty ? null : comment,
        );
      }
      if (!mounted) return;
      _refreshQueue();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  String _decisionTitle(String decision) {
    switch (decision) {
      case 'review':
        return 'Director Review';
      case 'approve':
        return 'Approve Application';
      case 'reject':
        return 'Reject Application';
      case 'issue_certificate':
        return 'Issue Certificate';
      default:
        return 'Decision';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSW Director Dashboard'),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.instance.streamUnreadCount(),
            builder: (context, snapshot) => IconButton(
              icon: Badge(
                isLabelVisible: (snapshot.data ?? 0) > 0,
                label: Text('${snapshot.data ?? 0}'),
                child: const Icon(Icons.notifications_outlined),
              ),
              tooltip: 'Notifications',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.support_agent_outlined),
            tooltip: 'Complaints',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ComplaintManagementScreen(director: true),
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
      body: SafeArea(
        child: FutureBuilder<List<Application>>(
          future: _queueFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load applications: ${snapshot.error}'),
              );
            }

            final applications = snapshot.data ?? const <Application>[];
            return FutureBuilder<List<Complaint>>(
              future: ComplaintServiceData.instance.getAllComplaints(),
              builder: (context, complaintsSnapshot) {
                if (complaintsSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load complaint summary: ${complaintsSnapshot.error}',
                    ),
                  );
                }
                if (!complaintsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final complaints = complaintsSnapshot.data!;
                final unresolved = complaints
                    .where(
                      (item) => !['RESOLVED', 'CLOSED'].contains(item.status),
                    )
                    .length;
                final high = complaints
                    .where((item) => ['HIGH', 'URGENT'].contains(item.priority))
                    .length;
                final approved = applications
                    .where((item) => item.status == 'APPROVED')
                    .length;
                final rejected = applications
                    .where((item) => item.status == 'REJECTED')
                    .length;
                final directorPending = applications
                    .where(
                      (item) => [
                        'OFFICER_APPROVED',
                        'DIRECTOR_REVIEW',
                      ].contains(item.status),
                    )
                    .length;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    Text(
                      'Director overview',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitor decisions, complaints, and service activity.',
                    ),
                    const SizedBox(height: 20),
                    _DirectorSummary(
                      items: [
                        (
                          'Pending review',
                          directorPending,
                          Icons.pending_actions_outlined,
                        ),
                        ('Approved', approved, Icons.check_circle_outline),
                        ('Rejected', rejected, Icons.cancel_outlined),
                        (
                          'Total complaints',
                          complaints.length,
                          Icons.report_outlined,
                        ),
                        (
                          'Unresolved',
                          unresolved,
                          Icons.warning_amber_outlined,
                        ),
                        ('High / urgent', high, Icons.priority_high_rounded),
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
                      height: 440,
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _DirectorApplicationList(
                            applications: applications
                                .where(
                                  (item) =>
                                      item.type == 'character_certificate',
                                )
                                .toList(),
                            onDecision: _handleDecision,
                          ),
                          _DirectorApplicationList(
                            applications: applications
                                .where(
                                  (item) =>
                                      item.type ==
                                      HallTransferService.applicationType,
                                )
                                .toList(),
                            onDecision: _handleDecision,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.support_agent_outlined),
                        title: const Text('Complaints'),
                        subtitle: Text(
                          '$unresolved unresolved · $high high / urgent',
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const ComplaintManagementScreen(director: true),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
