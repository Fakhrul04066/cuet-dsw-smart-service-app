import 'package:flutter/material.dart';

import '../models/application.dart';
import '../services/application_service.dart';
import '../services/user_service.dart';
import '../widgets/status_chip.dart';
import 'application_details_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});
  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _filter = 'All';

  Future<List<Application>> _loadApplications() async {
    final profile = await UserService.instance.getCurrentUserProfile();
    if (profile == null || profile.studentId.isEmpty) return const [];
    return ApplicationService.instance.getApplicationsByStudentId(
      profile.studentId,
    );
  }

  Future<void> _openDetails(Application application) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationDetailsScreen(application: application),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Applications')),
    body: FutureBuilder<List<Application>>(
      future: _loadApplications(),
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
        final filtered = applications.where((application) {
          if (_filter == 'Character Certificate') {
            return application.type == 'character_certificate';
          }
          if (_filter == 'Hall Transfer') {
            return application.type == 'hall_transfer';
          }
          return true;
        }).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'All', label: Text('All')),
                ButtonSegment(
                  value: 'Character Certificate',
                  label: Text('Certificate'),
                ),
                ButtonSegment(
                  value: 'Hall Transfer',
                  label: Text('Hall Transfer'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (value) =>
                  setState(() => _filter = value.first),
            ),
            const SizedBox(height: 16),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No applications in this category.')),
              )
            else
              ...filtered.map(
                (application) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () => _openDetails(application),
                      borderRadius: BorderRadius.circular(18),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                StatusChip(label: application.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              application.type == 'hall_transfer'
                                  ? 'Hall Transfer'
                                  : 'Character Certificate',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              application.createdAt
                                  .toLocal()
                                  .toString()
                                  .split(' ')
                                  .first,
                            ),
                            if (application.status == 'CORRECTION_REQUIRED' &&
                                (application.officerComment ?? '')
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Correction: ${application.officerComment}'),
                            ],
                            if (application.status == 'REJECTED' &&
                                ((application.directorComment ?? '').isNotEmpty ||
                                    (application.officerComment ?? '').isNotEmpty)) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Reason: ${(application.directorComment ?? '').isNotEmpty ? application.directorComment : application.officerComment}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
