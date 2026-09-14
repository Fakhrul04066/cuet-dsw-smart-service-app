import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/service_request.dart';
import '../services/service_request_service.dart';
import '../widgets/backend_setup_notice.dart';
import '../widgets/status_chip.dart';

class MyServiceRequestsScreen extends StatelessWidget {
  final String studentUid;
  const MyServiceRequestsScreen({super.key, required this.studentUid});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Track Service Requests')),
        body: StreamBuilder<List<ServiceRequest>>(
          stream: ServiceRequestService.instance.streamForStudent(studentUid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final errorText = snapshot.error.toString();
              if (errorText.contains('permission-denied') ||
                  errorText.contains('PERMISSION_DENIED')) {
                return const BackendSetupNotice(
                  title: 'Service request access is not enabled yet',
                  message:
                      'Deploy the updated Firestore rules, then reopen this screen.',
                );
              }
              return Center(child: Text('Could not load requests: $errorText'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return const Center(
                child: Text('No service requests submitted yet.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    title: Text(item.title),
                    subtitle: Text(
                      '${item.trackingNumber}\n${item.requestTypeLabel}',
                    ),
                    isThreeLine: true,
                    trailing: StatusChip(label: item.status),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceRequestDetailsScreen(request: item),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}

class ServiceRequestDetailsScreen extends StatelessWidget {
  final ServiceRequest request;
  const ServiceRequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceRequest?>(
      stream: ServiceRequestService.instance.streamById(request.id),
      builder: (context, snapshot) {
        final current = snapshot.data ?? request;
        return Scaffold(
          appBar: AppBar(title: Text(current.trackingNumber)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(current.requestTypeLabel),
                      ],
                    ),
                  ),
                  StatusChip(label: current.status),
                ],
              ),
              const SizedBox(height: 20),
              Text(current.description),
              const SizedBox(height: 20),
              _InfoCard(
                title: 'Processing',
                children: [
                  Text('Official priority: ${current.priority}'),
                  const Text('Officer queue: Visible to all DSW Officers'),
                  if (current.suggestedOffice.isNotEmpty)
                    Text('Suggested office: ${current.suggestedOffice}'),
                  if (current.correctionNote.isNotEmpty)
                    Text('Resubmission requested: ${current.correctionNote}'),
                  if (current.officerReviewNote.isNotEmpty)
                    Text('Officer review: ${current.officerReviewNote}'),
                  if (current.resolutionNote.isNotEmpty)
                    Text('Director decision note: ${current.resolutionNote}'),
                ],
              ),
              if (current.status == 'CORRECTION_REQUIRED' &&
                  FirebaseAuth.instance.currentUser?.uid == current.studentUid) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showResubmitDialog(context, current),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Correct and Resubmit'),
                  ),
                ),
              ],
              if (current.aiSummary.isNotEmpty ||
                  current.aiImageAssessment.isNotEmpty ||
                  current.aiDuplicateScore > 0) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'AI advisory',
                  children: [
                    if (current.aiSummary.isNotEmpty)
                      Text('Summary: ${current.aiSummary}'),
                    Text('Predicted priority: ${current.aiSuggestedPriority}'),
                    if (current.aiPriorityReason.isNotEmpty)
                      Text('Priority reason: ${current.aiPriorityReason}'),
                    if (current.aiRiskTags.isNotEmpty)
                      Text('Risk tags: ${current.aiRiskTags.join(', ')}'),
                    if (current.aiImageAssessment.isNotEmpty)
                      Text('Image evidence: ${current.aiImageAssessment}'),
                    if (current.aiDuplicateScore > 0)
                      Text(
                        'Potential duplicate confidence: ${(current.aiDuplicateScore * 100).round()}%',
                      ),
                    const SizedBox(height: 6),
                    const Text(
                      'AI output is advisory only and never makes an official DSW decision.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
              if (current.documents.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Documents',
                  children: current.documents
                      .map(
                        (document) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.attach_file),
                          title: Text(
                            (document['fileName'] ??
                                    document['name'] ??
                                    'Document')
                                .toString(),
                          ),
                          trailing: document['url'] is String
                              ? IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () => launchUrl(
                                    Uri.parse(document['url'] as String),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                )
                              : null,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: ServiceRequestService.instance.history(current.id),
                builder: (context, historySnapshot) => _InfoCard(
                  title: 'Application history',
                  children:
                      (historySnapshot.data ?? const <Map<String, dynamic>>[])
                          .map((item) {
                    final ts = item['timestamp'];
                    final time = ts is Timestamp ? ts.toDate().toLocal() : null;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timeline),
                      title: Text(
                        (item['action'] ?? item['status'] ?? '').toString(),
                      ),
                      subtitle: Text(
                        '${item['note'] ?? ''}${time == null ? '' : '\n$time'}',
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showResubmitDialog(
    BuildContext context,
    ServiceRequest current,
  ) async {
    final title = TextEditingController(text: current.title);
    final description = TextEditingController(text: current.description);
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Correct and resubmit'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Request title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Corrected description',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Resubmit'),
          ),
        ],
      ),
    );

    if (submitted != true || !context.mounted) {
      title.dispose();
      description.dispose();
      return;
    }

    final titleText = title.text.trim();
    final descriptionText = description.text.trim();
    title.dispose();
    description.dispose();

    try {
      await ServiceRequestService.instance.resubmit(
        requestId: current.id,
        title: titleText,
        description: descriptionText,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request resubmitted successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resubmission failed: $error')),
      );
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...children,
            ],
          ),
        ),
      );
}
