import 'package:flutter/material.dart';

import '../models/service_request.dart';
import '../services/service_request_service.dart';
import '../widgets/backend_setup_notice.dart';
import '../widgets/status_chip.dart';
import 'my_service_requests_screen.dart';

class ServiceRequestManagementScreen extends StatefulWidget {
  final bool directorMode;
  const ServiceRequestManagementScreen({super.key, this.directorMode = false});

  @override
  State<ServiceRequestManagementScreen> createState() =>
      _ServiceRequestManagementScreenState();
}

class _ServiceRequestManagementScreenState
    extends State<ServiceRequestManagementScreen> {
  String _status = 'All';
  String _type = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.directorMode
                ? 'DSW Request Oversight'
                : 'DSW Officer Request Queue',
          ),
        ),
        body: StreamBuilder<List<ServiceRequest>>(
          stream: ServiceRequestService.instance.streamAll(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final errorText = snapshot.error.toString();
              if (errorText.contains('permission-denied') ||
                  errorText.contains('PERMISSION_DENIED')) {
                return const BackendSetupNotice(
                  title: 'Service request access is not enabled yet',
                  message:
                      'Deploy the updated Firestore rules, then sign in again with the correct DSW role.',
                );
              }
              return Center(child: Text('Could not load requests: $errorText'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snapshot.data!;
            final visible = all.where(_matches).toList();
            final open = all.where((e) => !e.isFinal).length;
            final urgent = all
                .where(
                  (e) =>
                      ['HIGH', 'URGENT'].contains(e.aiSuggestedPriority) ||
                      ['HIGH', 'URGENT'].contains(e.priority),
                )
                .length;
            final waitingDirector = all
                .where((e) => e.status == 'OFFICER_REVIEW_COMPLETE')
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Total: ${all.length}')),
                    Chip(label: Text('Open: $open')),
                    Chip(label: Text('High / urgent: $urgent')),
                    Chip(label: Text('Waiting Director: $waitingDirector')),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.toLowerCase()),
                  decoration: const InputDecoration(
                    labelText: 'Search tracking no, student or title',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final statusFilter = _statusFilter();
                    final typeFilter = _typeFilter();
                    if (constraints.maxWidth < 620) {
                      return Column(
                        children: [
                          statusFilter,
                          const SizedBox(height: 10),
                          typeFilter,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: statusFilter),
                        const SizedBox(width: 12),
                        Expanded(child: typeFilter),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: Text('No requests match these filters.'),
                    ),
                  ),
                ...visible.map(
                  (request) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(request.title),
                            subtitle: Text(
                              '${request.trackingNumber} · ${request.studentId}\n${request.requestTypeLabel}',
                            ),
                            isThreeLine: true,
                            trailing: StatusChip(label: request.status),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ServiceRequestDetailsScreen(
                                  request: request,
                                ),
                              ),
                            ),
                          ),
                          if (request.correctionNote.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Correction requested: ${request.correctionNote}',
                              ),
                            ),
                          if (request.officerReviewNote.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Officer review: ${request.officerReviewNote}',
                              ),
                            ),
                          if (request.aiSuggestedPriority != 'NORMAL' ||
                              request.aiSummary.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'AI predicted priority: ${request.aiSuggestedPriority}'
                                '${request.aiSummary.isEmpty ? '' : '\n${request.aiSummary}'}',
                              ),
                            ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _actions(request),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

  Widget _statusFilter() => DropdownButtonFormField<String>(
        initialValue: _status,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Status'),
        items: ['All', ...ServiceRequest.statuses]
            .map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _status = value ?? 'All'),
      );

  Widget _typeFilter() => DropdownButtonFormField<String>(
        initialValue: _type,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Request type'),
        items: [
          const DropdownMenuItem(value: 'All', child: Text('All types')),
          ...ServiceRequest.requestTypes.entries.map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _type = value ?? 'All'),
      );

  bool _matches(ServiceRequest item) {
    final haystack =
        '${item.trackingNumber} ${item.studentId} ${item.studentName} ${item.title} ${item.description}'
            .toLowerCase();
    return (_query.isEmpty || haystack.contains(_query)) &&
        (_status == 'All' || item.status == _status) &&
        (_type == 'All' || item.requestType == _type);
  }

  List<Widget> _actions(ServiceRequest request) {
    final buttons = <Widget>[
      OutlinedButton.icon(
        onPressed: () => _run(
          () => ServiceRequestService.instance.analyzeRequestForStaff(
            request.id,
          ),
        ),
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('Run AI analysis'),
      ),
    ];

    if (widget.directorMode) {
      if (request.status == 'OFFICER_REVIEW_COMPLETE') {
        buttons.addAll(_directorFinalButtons(request));
      } else if (request.status == 'SUBMITTED' ||
          request.status == 'RESUBMITTED') {
        buttons.add(
          const Chip(label: Text('Waiting for Officer review')),
        );
      } else if (request.status == 'CORRECTION_REQUIRED') {
        buttons.add(
          const Chip(label: Text('Waiting for student resubmission')),
        );
      }
    } else {
      if (request.status == 'SUBMITTED' ||
          request.status == 'RESUBMITTED') {
        buttons.add(
          OutlinedButton(
            onPressed: () => _officerNoteAction(
              request,
              correction: true,
            ),
            child: const Text('Request resubmission'),
          ),
        );
        buttons.add(
          FilledButton(
            onPressed: () => _officerNoteAction(
              request,
              correction: false,
            ),
            child: const Text('Send to Director'),
          ),
        );
      } else if (request.status == 'CORRECTION_REQUIRED') {
        buttons.add(
          const Chip(label: Text('Waiting for student resubmission')),
        );
      } else if (request.status == 'OFFICER_REVIEW_COMPLETE') {
        buttons.add(
          const Chip(label: Text('Waiting for Director decision')),
        );
      }
    }

    return buttons;
  }

  List<Widget> _directorFinalButtons(ServiceRequest request) => [
        FilledButton.tonal(
          onPressed: () => _finalDecision(request, 'APPROVED'),
          child: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: () => _finalDecision(request, 'REJECTED'),
          child: const Text('Reject'),
        ),
        FilledButton(
          onPressed: () => _finalDecision(request, 'RESOLVED'),
          child: const Text('Resolve'),
        ),
      ];

  Future<void> _officerNoteAction(
    ServiceRequest request, {
    required bool correction,
  }) async {
    final note = await _askForNote(
      title: correction ? 'Request resubmission' : 'Complete officer review',
      label: correction
          ? 'What information must the student correct or add?'
          : 'Officer review note / recommendation',
      button: correction ? 'Request resubmission' : 'Send to Director',
    );
    if (note == null || !mounted) return;
    await _run(
      () => correction
          ? ServiceRequestService.instance.requestCorrection(
              request.id,
              note: note,
            )
          : ServiceRequestService.instance.completeOfficerReview(
              request.id,
              note: note,
            ),
    );
  }

  Future<void> _finalDecision(
    ServiceRequest request,
    String decision,
  ) async {
    final note = await _askForNote(
      title: '$decision request',
      label: 'Official Director note',
      button: decision,
    );
    if (note == null || !mounted) return;
    await _run(
      () => ServiceRequestService.instance.finalDecision(
        request.id,
        decision: decision,
        note: note,
      ),
    );
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

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    }
  }
}
