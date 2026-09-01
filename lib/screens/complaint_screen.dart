import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/complaint.dart';
import '../services/complaint_service_data.dart';
import '../services/firebase_storage_service.dart';
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
  bool _isUploading = false;
  double _uploadProgress = 0;
  late final String _complaintId;
  final _uploadedAttachments = <Map<String, dynamic>>[];
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
    _complaintId = DateTime.now().microsecondsSinceEpoch.toString();
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
    final id = _complaintId;
    final complaint = Complaint(
      id: id,
      trackingNumber: 'CMP-${now.year}-${id.substring(id.length - 6)}',
      studentId: profile.studentId,
      studentUid: profile.uid,
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      priority: 'NORMAL',
      status: 'SUBMITTED',
      createdAt: now,
      updatedAt: now,
      isConfidential: _confidential,
      attachments: _uploadedAttachments,
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

  Future<void> _pickAttachments() async {
    if (!FirebaseStorageService.uploadsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File upload is not available in this demo version.'),
          ),
        );
      }
      return;
    }
    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });
    try {
      final files = await FirebaseStorageService.instance.pickAndUpload(
        folder: 'complaints/$_complaintId/attachments',
        onProgress: (progress) => setState(() => _uploadProgress = progress),
      );
      _uploadedAttachments.addAll(files);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
        return SingleChildScrollView(
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
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickAttachments,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _isUploading
                        ? 'Uploading ${(_uploadProgress * 100).round()}%'
                        : 'Add images or documents',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : () => _submit(profile),
                    child: Text(_saving ? 'Submitting...' : 'Submit Complaint'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class ComplaintHistoryScreen extends StatelessWidget {
  const ComplaintHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Complaints')),
    body: FutureBuilder<dynamic>(
      future: UserService.instance.getCurrentUserProfile(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = profileSnapshot.data;
        return StreamBuilder<List<Complaint>>(
          stream: ComplaintServiceData.instance.streamComplaintsForStudent(
            profile.studentId,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              String errorMessage = 'Could not load your complaints';
              if (snapshot.error is FirebaseException) {
                final e = snapshot.error as FirebaseException;
                errorMessage = 'Firebase Error [${e.code}]: ${e.message}';
              } else {
                errorMessage = 'Error: ${snapshot.error}';
              }
              return Center(child: Text(errorMessage));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('No complaints submitted yet.'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: snapshot.data!
                  .map(
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
                  )
                  .toList(),
            );
          },
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
        Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (complaint.attachments.isEmpty)
          const Text('No attachments.')
        else
          ...complaint.attachments.map(
            (attachment) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file),
              title: Text(
                (attachment['fileName'] ?? attachment['name'] ?? 'Attachment')
                    .toString(),
              ),
              trailing: attachment['url'] is String
                  ? IconButton(
                      tooltip: 'Open attachment',
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => launchUrl(
                        Uri.parse(attachment['url'] as String),
                        mode: LaunchMode.externalApplication,
                      ),
                    )
                  : null,
            ),
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
