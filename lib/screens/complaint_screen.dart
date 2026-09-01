import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../services/complaint_service_data.dart';
import '../services/user_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/status_chip.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});
  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late final Future<dynamic> _profile;
  String _category = 'Hall Facilities';
  bool _confidential = false;
  bool _saving = false;
  final _categories = const [
    'Hall Facilities',
    'Academic',
    'Student Welfare',
    'Harassment / Safety',
    'Administrative',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _profile = UserService.instance.getCurrentUserProfile();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit(dynamic profile) async {
    if (!_formKey.currentState!.validate()) return;
    if (profile == null || profile.studentId.isEmpty) {
      _message('Complete your student profile before submitting a complaint.');
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final complaint = Complaint(
      id: id,
      trackingNumber: 'CMP-${now.year}-${id.substring(id.length - 6)}',
      studentId: profile.studentId,
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      priority: 'NORMAL',
      status: 'SUBMITTED',
      createdAt: now,
      updatedAt: now,
      isConfidential: _confidential,
    );
    try {
      await ComplaintServiceData.instance.createComplaint(complaint);
      if (!mounted) return;
      _title.clear();
      _description.clear();
      setState(() => _saving = false);
      _message(
        'Complaint submitted. Tracking number: ${complaint.trackingNumber}',
      );
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _message('Could not submit complaint: $error');
      }
    }
  }

  void _message(String text) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Complaint'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Student Complaint')),
    body: FutureBuilder<dynamic>(
      future: _profile,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data;
        return StreamBuilder<List<Complaint>>(
          stream: ComplaintServiceData.instance.streamComplaintsForStudent(
            profile.studentId,
          ),
          builder: (context, complaints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submit a complaint to DSW',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Complaint Category',
                    ),
                    items: _categories
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _title,
                    labelText: 'Complaint Title',
                    prefixIcon: Icons.title_rounded,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a complaint title'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _description,
                    labelText: 'Detailed Description',
                    prefixIcon: Icons.description_outlined,
                    maxLines: 6,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please describe the complaint'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _confidential,
                    onChanged: (value) =>
                        setState(() => _confidential = value ?? false),
                    title: const Text('Mark as confidential complaint'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : () => _submit(profile),
                      child: Text(
                        _saving ? 'Submitting...' : 'Submit Complaint',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'My complaints',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (complaints.hasError)
                    const Text('Could not load your complaints.')
                  else if (!complaints.hasData || complaints.data!.isEmpty)
                    const Text('No complaints submitted yet.')
                  else
                    ...complaints.data!.map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.title),
                          subtitle: Text(item.trackingNumber),
                          trailing: StatusChip(label: item.status),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ComplaintDetailsScreen(complaint: item),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class ComplaintDetailsScreen extends StatelessWidget {
  final Complaint complaint;
  const ComplaintDetailsScreen({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) => Scaffold(
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
        const SizedBox(height: 20),
        Text(complaint.description),
        const SizedBox(height: 16),
        Text('Category: ${complaint.category}'),
        Text('Priority: ${complaint.priority}'),
        const SizedBox(height: 20),
        Text(
          'Officer response',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          complaint.officerResponse?.isNotEmpty == true
              ? complaint.officerResponse!
              : 'No response yet.',
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: ComplaintServiceData.instance.getStatusHistory(complaint.id),
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
