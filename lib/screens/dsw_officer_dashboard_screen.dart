import 'package:flutter/material.dart';

import '../models/application.dart';
import '../services/auth_service.dart';
import '../services/character_certificate_service.dart';
import '../widgets/status_chip.dart';
import 'application_details_screen.dart';
import 'login_screen.dart';

class DSWOfficerDashboardScreen extends StatefulWidget {
  const DSWOfficerDashboardScreen({super.key});

  @override
  State<DSWOfficerDashboardScreen> createState() =>
      _DSWOfficerDashboardScreenState();
}

class _DSWOfficerDashboardScreenState extends State<DSWOfficerDashboardScreen> {
  late Future<List<Application>> _queueFuture;

  @override
  void initState() {
    super.initState();
    _queueFuture = CharacterCertificateService.instance.getOfficerQueue();
  }

  void _refreshQueue() {
    setState(() {
      _queueFuture = CharacterCertificateService.instance.getOfficerQueue();
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

    try {
      if (decision == 'review') {
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
        return 'Review Application';
      case 'request_correction':
        return 'Request Correction';
      case 'reject':
        return 'Reject Application';
      case 'approve':
        return 'Approve Application';
      default:
        return 'Update Application';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DSW Officer Dashboard'),
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
            if (applications.isEmpty) {
              return const Center(
                child: Text(
                  'No certificate applications are awaiting officer review.',
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                application.id,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            StatusChip(label: application.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(application.purpose),
                        const SizedBox(height: 8),
                        Text(
                          'Student ID: ${application.studentId}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ApplicationDetailsScreen(
                                      application: application,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View Details'),
                            ),
                            const Spacer(),
                            if (application.status == 'SUBMITTED')
                              FilledButton(
                                onPressed: () =>
                                    _handleDecision(application, 'review'),
                                child: const Text('Start Review'),
                              )
                            else ...[
                              TextButton(
                                onPressed: () => _handleDecision(
                                  application,
                                  'request_correction',
                                ),
                                child: const Text('Correction'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    _handleDecision(application, 'reject'),
                                child: const Text('Reject'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    _handleDecision(application, 'approve'),
                                child: const Text('Approve'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
