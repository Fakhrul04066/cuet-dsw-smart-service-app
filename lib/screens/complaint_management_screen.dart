import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../services/complaint_service_data.dart';
import '../widgets/status_chip.dart';

class ComplaintManagementScreen extends StatefulWidget {
  final bool director;
  const ComplaintManagementScreen({super.key, this.director = false});

  @override
  State<ComplaintManagementScreen> createState() =>
      _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> {
  String _query = '';
  String _category = 'All';
  String _status = 'All';
  String _priority = 'All';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.director ? 'Complaint oversight' : 'DSW Officer Complaints',
          ),
        ),
        body: StreamBuilder<List<Complaint>>(
          stream: ComplaintServiceData.instance.streamAllComplaints(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Could not load complaints: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final complaints = snapshot.data!;
            final visible = complaints.where(_matches).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Statistics(complaints: complaints),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.toLowerCase()),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search complaints',
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final filters = [
                      _filter(
                        'Category',
                        _category,
                        ['All', ...Complaint.categories],
                        (value) => setState(() => _category = value),
                      ),
                      _filter(
                        'Status',
                        _status,
                        ['All', ...ComplaintServiceData.statuses],
                        (value) => setState(() => _status = value),
                      ),
                      _filter(
                        'Priority',
                        _priority,
                        const ['All', 'LOW', 'NORMAL', 'HIGH', 'URGENT'],
                        (value) => setState(() => _priority = value),
                      ),
                    ];
                    if (constraints.maxWidth < 720) {
                      return Column(
                        children: [
                          filters[0],
                          const SizedBox(height: 8),
                          filters[1],
                          const SizedBox(height: 8),
                          filters[2],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: filters[0]),
                        const SizedBox(width: 8),
                        Expanded(child: filters[1]),
                        const SizedBox(width: 8),
                        Expanded(child: filters[2]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No complaints match these filters.'),
                    ),
                  ),
                ...visible.map(
                  (complaint) => Card(
                    child: ListTile(
                      title: Text(complaint.title),
                      subtitle: Text(
                        '${complaint.trackingNumber}  |  ${complaint.category}  |  ${complaint.priority}',
                      ),
                      trailing: StatusChip(label: complaint.status),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _StaffComplaintDetails(
                            complaint: complaint,
                            director: widget.director,
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

  bool _matches(Complaint complaint) {
    final text =
        '${complaint.title} ${complaint.description} ${complaint.trackingNumber} ${complaint.studentId}'
            .toLowerCase();
    return (_query.isEmpty || text.contains(_query)) &&
        (_category == 'All' || complaint.category == _category) &&
        (_status == 'All' || complaint.status == _status) &&
        (_priority == 'All' || complaint.priority == _priority);
  }

  Widget _filter(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> onChanged,
  ) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      );
}

class _Statistics extends StatelessWidget {
  final List<Complaint> complaints;
  const _Statistics({required this.complaints});

  @override
  Widget build(BuildContext context) {
    final unresolved =
        complaints.where((item) => item.status != 'RESOLVED').length;
    final urgent = complaints
        .where((item) => ['URGENT', 'HIGH'].contains(item.priority))
        .length;
    final waitingDirector = complaints
        .where((item) => item.status == 'OFFICER_REVIEW_COMPLETE')
        .length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Stat(label: 'Total', value: complaints.length),
        _Stat(label: 'Open', value: unresolved),
        _Stat(label: 'Urgent / high', value: urgent),
        _Stat(label: 'Waiting Director', value: waitingDirector),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Chip(label: Text('$label: $value'));
}

class _StaffComplaintDetails extends StatefulWidget {
  final Complaint complaint;
  final bool director;
  const _StaffComplaintDetails({
    required this.complaint,
    required this.director,
  });

  @override
  State<_StaffComplaintDetails> createState() =>
      _StaffComplaintDetailsState();
}

class _StaffComplaintDetailsState extends State<_StaffComplaintDetails> {
  late String _category;
  late String _priority;
  final _response = TextEditingController();
  bool _saving = false;
  final _categories = Complaint.categories;
  final _priorities = const ['LOW', 'NORMAL', 'HIGH', 'URGENT'];

  @override
  void initState() {
    super.initState();
    _category = _categories.contains(widget.complaint.category)
        ? widget.complaint.category
        : 'Other';
    _priority = _priorities.contains(widget.complaint.priority)
        ? widget.complaint.priority
        : 'NORMAL';
    _response.text = widget.complaint.officerResponse ?? '';
  }

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  Future<void> _saveFields(Complaint complaint) async {
    setState(() => _saving = true);
    try {
      await ComplaintServiceData.instance.updateStaffFields(
        complaint.id,
        category: _category,
        priority: _priority,
        officerResponse: _response.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint review details saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _runAiAnalysis(Complaint complaint) async {
    setState(() => _saving = true);
    try {
      await ComplaintServiceData.instance.analyzeComplaintForStaff(
        complaint.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI complaint analysis updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI analysis failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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

  Future<void> _requestResubmission(Complaint complaint) async {
    final note = await _askForNote(
      title: 'Request resubmission',
      label: 'What information must the student correct or add?',
      button: 'Request resubmission',
    );
    if (note == null || !mounted) return;
    await _run(
      () => ComplaintServiceData.instance.requestCorrection(
        complaint.id,
        note: note,
      ),
    );
  }

  Future<void> _sendToDirector(Complaint complaint) async {
    final note = await _askForNote(
      title: 'Complete Officer review',
      label: 'Officer review note / recommendation',
      button: 'Send to Director',
    );
    if (note == null || !mounted) return;
    await _run(
      () => ComplaintServiceData.instance.completeOfficerReview(
        complaint.id,
        note: note,
      ),
    );
  }

  Future<void> _resolve(Complaint complaint) async {
    final note = await _askForNote(
      title: 'Resolve complaint',
      label: 'Official Director resolution note',
      button: 'Resolve',
    );
    if (note == null || !mounted) return;
    await _run(
      () => ComplaintServiceData.instance.resolveByDirector(
        complaint.id,
        note: note,
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint updated successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Complaint?>(
        stream: ComplaintServiceData.instance.streamComplaintById(
          widget.complaint.id,
        ),
        builder: (context, snapshot) {
          final complaint = snapshot.data ?? widget.complaint;
          return Scaffold(
            appBar: AppBar(title: Text(complaint.trackingNumber)),
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    StatusChip(label: complaint.status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(complaint.description),
                const SizedBox(height: 16),
                if (complaint.aiSummary != null ||
                    complaint.aiSuggestedCategory != null ||
                    complaint.aiSuggestedPriority != null ||
                    complaint.aiSuggestedDepartment != null ||
                    complaint.aiDuplicateScore > 0 ||
                    complaint.aiImageAssessment.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Suggestion',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (complaint.aiSummary != null)
                            Text('Summary: ${complaint.aiSummary}'),
                          if (complaint.aiSuggestedCategory != null)
                            Text(
                              'Suggested Category: ${complaint.aiSuggestedCategory}',
                            ),
                          if (complaint.aiSuggestedPriority != null)
                            Text(
                              'Suggested Priority: ${complaint.aiSuggestedPriority}',
                            ),
                          if (complaint.aiSuggestedDepartment != null)
                            Text(
                              'Suggested Department: ${complaint.aiSuggestedDepartment}',
                            ),
                          if (complaint.aiDuplicateScore > 0)
                            Text(
                              'Duplicate confidence: ${(complaint.aiDuplicateScore * 100).round()}%',
                            ),
                          if (complaint.aiDuplicateReason.isNotEmpty)
                            Text(
                              'Duplicate analysis: ${complaint.aiDuplicateReason}',
                            ),
                          if (complaint.aiImageAssessment.isNotEmpty)
                            Text(
                              'Image evidence analysis: ${complaint.aiImageAssessment}',
                            ),
                          const SizedBox(height: 6),
                          const Text(
                            'AI output is advisory only. Officers verify information; only the Director makes the final decision.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text('Student ID: ${complaint.studentId}'),
                if ((complaint.correctionNote ?? '').isNotEmpty)
                  Text('Resubmission request: ${complaint.correctionNote}'),
                if ((complaint.officerResponse ?? '').isNotEmpty)
                  Text('Officer review: ${complaint.officerResponse}'),
                if ((complaint.directorResponse ?? '').isNotEmpty)
                  Text('Director decision: ${complaint.directorResponse}'),
                const SizedBox(height: 16),
                if (!widget.director) ...[
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: ['SUBMITTED', 'RESUBMITTED']
                            .contains(complaint.status)
                        ? (value) =>
                            setState(() => _category = value ?? _category)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: _priorities
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: ['SUBMITTED', 'RESUBMITTED']
                            .contains(complaint.status)
                        ? (value) =>
                            setState(() => _priority = value ?? _priority)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _response,
                    enabled: ['SUBMITTED', 'RESUBMITTED']
                        .contains(complaint.status),
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Officer working note',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => _runAiAnalysis(complaint),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Run AI complaint analysis'),
                  ),
                  const SizedBox(height: 8),
                  if (['SUBMITTED', 'RESUBMITTED'].contains(complaint.status))
                    FilledButton(
                      onPressed:
                          _saving ? null : () => _saveFields(complaint),
                      child: const Text('Save review details'),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (['SUBMITTED', 'RESUBMITTED']
                          .contains(complaint.status)) ...[
                        OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => _requestResubmission(complaint),
                          child: const Text('Request resubmission'),
                        ),
                        FilledButton(
                          onPressed: _saving
                              ? null
                              : () => _sendToDirector(complaint),
                          child: const Text('Send to Director'),
                        ),
                      ],
                      if (complaint.status == 'CORRECTION_REQUIRED')
                        const Chip(
                          label: Text('Waiting for student resubmission'),
                        ),
                      if (complaint.status == 'OFFICER_REVIEW_COMPLETE')
                        const Chip(
                          label: Text('Waiting for Director decision'),
                        ),
                    ],
                  ),
                ] else ...[
                  if (complaint.status == 'OFFICER_REVIEW_COMPLETE')
                    FilledButton(
                      onPressed: _saving ? null : () => _resolve(complaint),
                      child: const Text('Resolve complaint'),
                    )
                  else if (complaint.status == 'SUBMITTED' ||
                      complaint.status == 'RESUBMITTED')
                    const Chip(label: Text('Waiting for Officer review'))
                  else if (complaint.status == 'CORRECTION_REQUIRED')
                    const Chip(
                      label: Text('Waiting for student resubmission'),
                    ),
                ],
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: ComplaintServiceData.instance.getStatusHistory(
                    complaint.id,
                  ),
                  builder: (context, historySnapshot) => ExpansionTile(
                    title: const Text('Status history'),
                    children: (historySnapshot.data ??
                            const <Map<String, dynamic>>[])
                        .map(
                          (item) => ListTile(
                            title: Text(item['status']?.toString() ?? ''),
                            subtitle: Text(item['note']?.toString() ?? ''),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
