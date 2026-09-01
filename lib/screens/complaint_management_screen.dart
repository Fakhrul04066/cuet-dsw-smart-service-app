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
        widget.director ? 'Complaint monitoring' : 'Complaint management',
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filter('Category', _category, [
                  'All',
                  ...Complaint.categories,
                ], (value) => setState(() => _category = value)),
                _filter('Status', _status, [
                  'All',
                  ...ComplaintServiceData.statuses,
                ], (value) => setState(() => _status = value)),
                _filter('Priority', _priority, [
                  'All',
                  'LOW',
                  'NORMAL',
                  'HIGH',
                  'URGENT',
                ], (value) => setState(() => _priority = value)),
              ],
            ),
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
  ) => DropdownButton<String>(
    value: value,
    underline: const SizedBox.shrink(),
    hint: Text(label),
    items: values
        .map(
          (item) => DropdownMenuItem(value: item, child: Text('$label: $item')),
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
    final unresolved = complaints
        .where((item) => !['RESOLVED', 'CLOSED'].contains(item.status))
        .length;
    final urgent = complaints
        .where((item) => ['URGENT', 'HIGH'].contains(item.priority))
        .length;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _Stat(label: 'Total', value: complaints.length),
        _Stat(label: 'Unresolved', value: unresolved),
        _Stat(label: 'Urgent / high', value: urgent),
        _Stat(
          label: 'Resolved',
          value: complaints.where((item) => item.status == 'RESOLVED').length,
        ),
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
  State<_StaffComplaintDetails> createState() => _StaffComplaintDetailsState();
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
    _priority = widget.complaint.priority;
    _response.text = widget.complaint.officerResponse ?? '';
  }

  @override
  void dispose() {
    _response.dispose();
    super.dispose();
  }

  Future<void> _saveFields() async {
    setState(() => _saving = true);
    try {
      await ComplaintServiceData.instance.updateStaffFields(
        widget.complaint.id,
        category: _category,
        priority: _priority,
        officerResponse: _response.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Complaint updated.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeStatus(String status) async {
    setState(() => _saving = true);
    try {
      await ComplaintServiceData.instance.updateComplaintStatus(
        widget.complaint.id,
        status: status,
        note: _response.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status changed to $status.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status update failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.complaint.trackingNumber)),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.complaint.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            StatusChip(label: widget.complaint.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(widget.complaint.description),
        const SizedBox(height: 16),
        Text('Student ID: ${widget.complaint.studentId}'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: _categories
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: widget.director
              ? null
              : (value) => setState(() => _category = value ?? _category),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _priorities.contains(_priority) ? _priority : 'NORMAL',
          decoration: const InputDecoration(labelText: 'Priority'),
          items: _priorities
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: widget.director
              ? null
              : (value) => setState(() => _priority = value ?? _priority),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _response,
          enabled: !widget.director,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Officer response'),
        ),
        if (!widget.director) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _saveFields,
            child: const Text('Save complaint details'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ComplaintServiceData.statuses
                .where((status) => status != widget.complaint.status)
                .map(
                  (status) => OutlinedButton(
                    onPressed: _saving ? null : () => _changeStatus(status),
                    child: Text(status),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ComplaintServiceData.instance.getStatusHistory(
            widget.complaint.id,
          ),
          builder: (context, snapshot) => ExpansionTile(
            title: const Text('Status history'),
            children: (snapshot.data ?? const <Map<String, dynamic>>[])
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
}
