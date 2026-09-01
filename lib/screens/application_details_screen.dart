import 'package:flutter/material.dart';

import '../models/application.dart';
import '../services/character_certificate_service.dart';
import '../services/hall_transfer_service.dart';
import '../widgets/status_chip.dart';

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

    final documentNames = application.documents
        .map(
          (document) => (document['name'] ?? document['fileName'] ?? 'Document')
              .toString(),
        )
        .toList();

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
                children: documentNames.isEmpty
                    ? [const Text('No documents attached.')]
                    : documentNames
                          .map(
                            (name) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.attach_file_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(name)),
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
                  Text(
                    application.officerComment ??
                        application.directorComment ??
                        'No notes available at this time.',
                  ),
                ],
              ),
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
