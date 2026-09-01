import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/admin_service.dart';
import '../services/firebase_auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _index = 0;
  final _pages = const [
    _OverviewPage(),
    CertificateRequestsScreen(),
    HallTransferRequestsScreen(),
    ComplaintsManagementScreen(),
    ReportsScreen(),
    AuditLogsScreen(),
    AdminNotificationsScreen(),
  ];
  final _labels = const [
    'Overview',
    'Certificates',
    'Hall transfers',
    'Complaints',
    'Reports',
    'Audit logs',
    'Notifications',
  ];
  final _icons = const [
    Icons.dashboard_outlined,
    Icons.badge_outlined,
    Icons.swap_horiz,
    Icons.support_agent,
    Icons.bar_chart,
    Icons.history,
    Icons.notifications_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;
    return Scaffold(
      appBar: compact ? AppBar(title: Text(_labels[_index])) : null,
      drawer: compact ? Drawer(child: _navigation(context)) : null,
      body: Row(
        children: [
          if (!compact) SizedBox(width: 250, child: _navigation(context)),
          Expanded(child: _pages[_index]),
        ],
      ),
    );
  }

  Widget _navigation(BuildContext context) {
    return Material(
      color: const Color(0xFF102A43),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 18, 28),
              child: Text(
                'CUET DSW\nADMIN CONSOLE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            ...List.generate(
              _labels.length,
              (index) => ListTile(
                selected: _index == index,
                selectedTileColor: const Color(0xFF1F4E68),
                leading: Icon(_icons[index], color: Colors.white70),
                title: Text(
                  _labels[index],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() => _index = index);
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text(
                'Sign out',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                await FirebaseAuthService.instance.logout();
                if (context.mounted) {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (_) => false);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Text('Use the shared CUET DSW login to access this console.'),
    ),
  );
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage();
  @override
  Widget build(BuildContext context) {
    return _AdminPageScaffold(
      title: 'Good morning, DSW team',
      subtitle: 'A live view of student service activity.',
      child: FutureBuilder<Map<String, int>>(
        future: AdminService.instance.getSummary(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(message: 'Could not load dashboard data.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final values = snapshot.data!;
          final cards = [
            (
              'Pending certificates',
              values['pendingCertificates']!,
              Icons.badge_outlined,
            ),
            (
              'Pending transfers',
              values['pendingTransfers']!,
              Icons.swap_horiz,
            ),
            ('Open complaints', values['openComplaints']!, Icons.support_agent),
            (
              'Confidential complaints',
              values['confidentialComplaints']!,
              Icons.lock_outline,
            ),
            (
              'Resolved complaints',
              values['resolvedComplaints']!,
              Icons.task_alt,
            ),
          ];
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: cards
                .map(
                  (card) => _SummaryCard(
                    label: card.$1,
                    value: card.$2,
                    icon: card.$3,
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class CertificateRequestsScreen extends StatelessWidget {
  const CertificateRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) => _RequestListScreen(
    title: 'Character certificates',
    collection: 'characterCertificates',
    columns: const ['Tracking number', 'Student', 'Department', 'Status'],
  );
}

class HallTransferRequestsScreen extends StatelessWidget {
  const HallTransferRequestsScreen({super.key});
  @override
  Widget build(BuildContext context) => _RequestListScreen(
    title: 'Hall transfers',
    collection: 'hallTransfers',
    columns: const [
      'Tracking number',
      'Student',
      'Current hall',
      'Preferred hall',
      'Status',
    ],
  );
}

class ComplaintsManagementScreen extends StatelessWidget {
  const ComplaintsManagementScreen({super.key});
  @override
  Widget build(BuildContext context) => _RequestListScreen(
    title: 'Complaints',
    collection: 'complaints',
    columns: const [
      'Tracking number',
      'Category',
      'Assigned office',
      'Urgency',
      'Status',
    ],
  );
}

class _RequestListScreen extends StatefulWidget {
  final String title;
  final String collection;
  final List<String> columns;

  const _RequestListScreen({
    required this.title,
    required this.collection,
    required this.columns,
  });

  @override
  State<_RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<_RequestListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return _AdminPageScaffold(
      title: widget.title,
      subtitle: 'Review and update live Firestore requests.',
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search tracking number or student',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: AdminService.instance.streamApplications(
                widget.collection,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _ErrorState(message: 'Could not load requests.');
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  return data.values.any(
                    (value) => value.toString().toLowerCase().contains(_query),
                  );
                }).toList();

                if (docs.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final confidential =
                        widget.collection == 'complaints' &&
                        data['isConfidential'] == true;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          confidential
                              ? Icons.lock
                              : Icons.description_outlined,
                        ),
                        title: Text(
                          data['trackingNumber']?.toString() ?? docs[index].id,
                        ),
                        subtitle: Text(_subtitle(data)),
                        trailing: Chip(
                          label: Text(
                            data['status']?.toString() ?? 'Submitted',
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _AdminDetailsScreen(
                              collection: widget.collection,
                              document: docs[index],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(Map<String, dynamic> data) {
    if (widget.collection == 'complaints') {
      return '${data['category'] ?? ''} · ${data['assignedOffice'] ?? 'Unassigned'}';
    }
    return '${data['studentName'] ?? ''} · ${data['department'] ?? data['currentHall'] ?? ''}';
  }
}

class CertificateDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  const CertificateDetailsScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) => _AdminDetailsScreen(
    collection: 'characterCertificates',
    document: document,
  );
}

class HallTransferDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  const HallTransferDetailsScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) =>
      _AdminDetailsScreen(collection: 'hallTransfers', document: document);
}

class ComplaintDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  const ComplaintDetailsScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) =>
      _AdminDetailsScreen(collection: 'complaints', document: document);
}

class _AdminDetailsScreen extends StatefulWidget {
  final String collection;
  final QueryDocumentSnapshot<Map<String, dynamic>> document;

  const _AdminDetailsScreen({required this.collection, required this.document});

  @override
  State<_AdminDetailsScreen> createState() => _AdminDetailsScreenState();
}

class _AdminDetailsScreenState extends State<_AdminDetailsScreen> {
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.document.data();
    final complaint = widget.collection == 'complaints';
    final statuses = complaint
        ? ['Assigned', 'In Progress', 'Resolved', 'Closed']
        : ['Under Review', 'Correction Required', 'Approved', 'Rejected'];

    return Scaffold(
      appBar: AppBar(
        title: Text(data['trackingNumber']?.toString() ?? 'Request'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            data['studentName']?.toString() ?? data['title']?.toString() ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...data.entries
              .where((entry) => !['id', 'studentUid'].contains(entry.key))
              .map(
                (entry) => ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value.toString()),
                ),
              ),
          const Divider(),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: AdminService.instance.getStatusHistory(
              widget.collection,
              widget.document.id,
            ),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <Map<String, dynamic>>[];
              return ExpansionTile(
                title: const Text('Status history'),
                children: items
                    .map(
                      (item) => ListTile(
                        title: Text(item['status'].toString()),
                        subtitle: Text(item['note'].toString()),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Official note'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses
                .map(
                  (status) => FilledButton(
                    onPressed: _saving ? null : () => _changeStatus(status),
                    child: Text(status),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(String status) async {
    if ((status == 'Approved' || status == 'Rejected') &&
        !(await _confirm(status))) {
      return;
    }

    if (status == 'Correction Required' && _note.text.trim().isEmpty) {
      _show('A correction note is required.');
      return;
    }

    setState(() => _saving = true);
    try {
      await AdminService.instance.updateApplication(
        collection: widget.collection,
        id: widget.document.id,
        trackingNumber:
            widget.document.data()['trackingNumber']?.toString() ??
            widget.document.id,
        status: status,
        note: _note.text.trim(),
      );
      if (mounted) {
        _show('Request updated.');
      }
    } catch (_) {
      if (mounted) {
        _show('Could not update this request.');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirm(String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$status request?'),
        content: const Text(
          'This action will notify the student and add an audit log.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminPageScaffold(
      title: 'Notifications',
      subtitle: 'Recent student-facing updates.',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AdminService.instance.streamNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          return ListView(
            children: snapshot.data!.docs
                .map(
                  (doc) => ListTile(
                    title: Text(doc.data()['title']?.toString() ?? ''),
                    subtitle: Text(doc.data()['message']?.toString() ?? ''),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminPageScaffold(
      title: 'Reports',
      subtitle: 'Basic live application totals.',
      child: FutureBuilder<Map<String, int>>(
        future: AdminService.instance.getSummary(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: snapshot.data!.entries
                .map(
                  (entry) => ListTile(
                    title: Text(entry.key),
                    trailing: Text(
                      '${entry.value}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminPageScaffold(
      title: 'Audit logs',
      subtitle: 'Immutable administrative activity trail.',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: AdminService.instance.streamAuditLogs(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data();
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  '${data['action'] ?? ''} · ${data['trackingNumber'] ?? ''}',
                ),
                subtitle: Text(
                  '${data['actorName'] ?? ''}: ${data['details'] ?? ''}',
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _AdminPageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _AdminPageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(subtitle),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 18),
              Text('$value', style: Theme.of(context).textTheme.headlineMedium),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No records found.'));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
