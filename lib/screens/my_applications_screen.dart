import 'package:flutter/material.dart';

import '../models/application.dart';
import '../services/character_certificate_service.dart';
import '../widgets/status_chip.dart';
import 'application_details_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  Future<List<Application>> _loadApplications() async {
    return CharacterCertificateService.instance.getStudentApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: SafeArea(
        child: FutureBuilder<List<Application>>(
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
            if (applications.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No applications submitted yet.'),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                final status = application.status;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ApplicationDetailsScreen(
                              application: application,
                            ),
                          ),
                        );
                      },
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
                                StatusChip(label: status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              application.type,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              application.purpose.isNotEmpty
                                  ? application.purpose
                                  : 'No purpose provided',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              application.createdAt
                                  .toLocal()
                                  .toString()
                                  .split(' ')
                                  .first,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
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
    );
  }
}
