import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/application.dart';
import '../models/application_history.dart';
import '../models/user_model.dart';
import '../services/application_service.dart';
import '../services/application_history_service.dart';
import '../services/character_certificate_service.dart';
import '../services/certificate_pdf_service.dart';
import '../services/hall_transfer_service.dart';
import '../services/user_service.dart';
import '../widgets/status_chip.dart';
import 'certificate_preview_screen.dart';

class ApplicationDetailsScreen extends StatelessWidget {
  final Application application;

  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    final isHallTransfer =
        application.type == HallTransferService.applicationType;
    final timeline = isHallTransfer
        ? HallTransferStatus.timeline(application.status)
        : CharacterCertificateService.instance.statusTimelineForApplication(
            application.status,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Application Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      application.id,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  StatusChip(label: application.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                application.type,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Application Summary',
                children: [
                  _DetailRow(
                    label: 'Submission Date',
                    value: application.createdAt.toLocal().toString(),
                  ),
                  _DetailRow(
                    label: 'Current Status',
                    value: isHallTransfer
                        ? HallTransferStatus.timelineLabel(application.status)
                        : CharacterCertificateStatus.timelineLabel(
                            application.status,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Submitted Information',
                children: [
                  _DetailRow(label: 'Student ID', value: application.studentId),
                  if (isHallTransfer) ...[
                    _DetailRow(
                      label: 'Current Hall',
                      value: application.currentHall ?? '',
                    ),
                    _DetailRow(
                      label: 'Requested Hall',
                      value: application.requestedHall ?? '',
                    ),
                    _DetailRow(
                      label: 'Reason',
                      value: application.reason ?? '',
                    ),
                  ],
                  _DetailRow(label: 'Purpose', value: application.purpose),
                  _DetailRow(
                    label: 'Description',
                    value: application.description,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Attached Documents',
                children: application.documents.isEmpty
                    ? [const Text('No documents attached.')]
                    : application.documents
                          .map(
                            (document) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attach_file_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (document['name'] ??
                                              document['fileName'] ??
                                              'Document')
                                          .toString(),
                                    ),
                                  ),
                                  if (document['url'] is String)
                                    IconButton(
                                      tooltip: 'Open document',
                                      icon: const Icon(Icons.open_in_new),
                                      onPressed: () => launchUrl(
                                        Uri.parse(document['url'] as String),
                                        mode: LaunchMode.externalApplication,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Official Notes',
                children: [
                  if ((application.officerComment ?? '').isNotEmpty)
                    _DetailRow(
                      label: 'Officer Official Note',
                      value: application.officerComment!,
                    ),
                  if ((application.directorComment ?? '').isNotEmpty)
                    _DetailRow(
                      label: 'Director Official Note',
                      value: application.directorComment!,
                    ),
                  if ((application.officerComment ?? '').isEmpty &&
                      (application.directorComment ?? '').isEmpty)
                    const Text('No notes available at this time.'),
                ],
              ),
              if (application.status == 'CORRECTION_REQUIRED') ...[
                const SizedBox(height: 16),
                FutureBuilder<StudentUser?>(
                  future: UserService.instance.getCurrentUserProfile(),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    final canResubmit = profile != null &&
                        StudentUser.normalizeRole(profile.role) == 'student' &&
                        profile.studentId == application.studentId;
                    if (!canResubmit) return const SizedBox.shrink();
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showResubmitDialog(context),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Correct and Resubmit'),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
              FutureBuilder<List<ApplicationHistory>>(
                future: ApplicationHistoryService.instance
                    .getHistoryForApplication(application.id),
                builder: (context, snapshot) => _InfoCard(
                  title: 'Application History',
                  children: (snapshot.data ?? const <ApplicationHistory>[])
                      .map(
                        (entry) => _DetailRow(
                          label: entry.action,
                          value: entry.comment,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (!isHallTransfer &&
                  application.status ==
                      CharacterCertificateStatus.certificateIssued) ...[
                const SizedBox(height: 16),
                FutureBuilder<StudentUser?>(
                  future: UserService.instance.getCurrentUserProfile(),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    if (profile == null ||
                        StudentUser.normalizeRole(profile.role) != 'student' ||
                        profile.studentId != application.studentId) {
                      return const SizedBox.shrink();
                    }
                    return _CertificateActions(
                      application: application,
                      student: profile,
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),
              Text(
                'Status Timeline',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...List.generate(timeline.length, (index) {
                final step = timeline[index];
                final isLast = index == timeline.length - 1;
                final completed = index <= timeline.indexOf(application.status);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: completed
                                ? Theme.of(context).colorScheme.primary
                                : const Color(0xFFD5DCE8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 28,
                            color: const Color(0xFFD5DCE8),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: isLast ? 0 : 10,
                          top: 0,
                        ),
                        child: Text(
                          isHallTransfer
                              ? HallTransferStatus.timelineLabel(step)
                              : CharacterCertificateStatus.timelineLabel(step),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResubmitDialog(BuildContext context) async {
    final purpose = TextEditingController(text: application.purpose);
    final description = TextEditingController(text: application.description);
    final currentHall = TextEditingController(
      text: application.currentHall ?? '',
    );
    final requestedHall = TextEditingController(
      text: application.requestedHall ?? '',
    );
    final reason = TextEditingController(text: application.reason ?? '');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Correct and resubmit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (application.type != HallTransferService.applicationType) ...[
                TextField(
                  controller: purpose,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                ),
                TextField(
                  controller: description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
              if (application.type == HallTransferService.applicationType) ...[
                TextField(
                  controller: currentHall,
                  decoration: const InputDecoration(labelText: 'Current Hall'),
                ),
                TextField(
                  controller: requestedHall,
                  decoration: const InputDecoration(
                    labelText: 'Requested Hall',
                  ),
                ),
                TextField(
                  controller: reason,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );
    if (submitted != true || !context.mounted) return;
    try {
      await ApplicationService.instance.resubmitApplication(
        application,
        purpose: purpose.text.trim(),
        description: description.text.trim(),
        currentHall: currentHall.text.trim(),
        requestedHall: requestedHall.text.trim(),
        reason: reason.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application resubmitted for officer processing.'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _CertificateActions extends StatelessWidget {
  final Application application;
  final StudentUser student;

  const _CertificateActions({
    required this.application,
    required this.student,
  });

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Certificate error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Issued Certificate',
      children: [
        const Text(
          'Your Character Certificate has been issued. You can preview it or '
          'save/share the PDF using your device.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CertificatePreviewScreen(
                    application: application,
                    student: student,
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Certificate'),
            ),
            FilledButton.icon(
              onPressed: () => _run(
                context,
                () => CertificatePdfService.instance.downloadCertificate(
                  application: application,
                  student: student,
                ),
              ),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download PDF'),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E7F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5B6B82)),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
