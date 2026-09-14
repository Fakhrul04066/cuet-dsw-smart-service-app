import 'package:flutter/material.dart';

import '../models/service_request.dart';
import '../models/user_model.dart';
import '../services/firebase_storage_service.dart';
import '../services/service_request_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text_field.dart';

class ServiceRequestSubmissionScreen extends StatefulWidget {
  final String? initialType;
  const ServiceRequestSubmissionScreen({super.key, this.initialType});

  @override
  State<ServiceRequestSubmissionScreen> createState() =>
      _ServiceRequestSubmissionScreenState();
}

class _ServiceRequestSubmissionScreenState
    extends State<ServiceRequestSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  late final Future<StudentUser?> _profileFuture;
  late final String _requestId;
  late String _type;
  bool _saving = false;
  bool _uploading = false;
  double _uploadProgress = 0;
  final List<Map<String, dynamic>> _documents = [];

  @override
  void initState() {
    super.initState();
    _profileFuture = UserService.instance.getCurrentUserProfile();
    _requestId = DateTime.now().microsecondsSinceEpoch.toString();
    _type = ServiceRequest.requestTypes.containsKey(widget.initialType)
        ? widget.initialType!
        : ServiceRequest.requestTypes.keys.first;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDocuments() async {
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
    });
    try {
      final files = await FirebaseStorageService.instance.pickAndUpload(
        folder: 'service_requests/$_requestId/documents',
        onProgress: (value) {
          if (mounted) setState(() => _uploadProgress = value);
        },
      );
      if (mounted) setState(() => _documents.addAll(files));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit(StudentUser profile) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final tracking = ServiceRequestService.instance.buildTrackingNumber();
    final request = ServiceRequest(
      id: _requestId,
      trackingNumber: tracking,
      studentUid: profile.uid,
      studentId: profile.studentId,
      studentName: profile.name,
      requestType: _type,
      title: _title.text.trim(),
      description: _description.text.trim(),
      status: 'SUBMITTED',
      documents: _documents,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ServiceRequestService.instance.submit(request);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Request submitted'),
          content: Text(
            'Tracking number: $tracking\n\n'
            'Your request is now visible to all DSW Officers for information checking. AI triage is advisory only.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit request: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('New DSW Service Request')),
        body: FutureBuilder<StudentUser?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final profile = snapshot.data;
            if (profile == null) {
              return const Center(child: Text('Student profile not found.'));
            }
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Official DSW workflow',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Submitted → Officer Review → Resubmission if needed → '
                          'Officer Review Complete → Director Final Decision',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All DSW Officers can review requests. Only the DSW Director can approve, reject, resolve, or make a final decision.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Request type',
                          prefixIcon: Icon(Icons.business_center_outlined),
                        ),
                        items: ServiceRequest.requestTypes.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _type = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _title,
                        labelText: 'Request title',
                        prefixIcon: Icons.title,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a clear request title'
                                : null,
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        controller: _description,
                        labelText: 'Detailed description',
                        prefixIcon: Icons.notes_outlined,
                        maxLines: 7,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.length < 20) {
                            return 'Please provide at least 20 characters of detail';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Supporting documents',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed:
                                        _uploading ? null : _pickDocuments,
                                    icon: _uploading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.upload_file_outlined,
                                          ),
                                    label: Text(
                                      _uploading
                                          ? '${(_uploadProgress * 100).round()}%'
                                          : 'Upload',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'PDF, JPG or PNG, maximum 5 MB per file. Images can be used for advisory AI evidence analysis.',
                              ),
                              if (_documents.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ..._documents.map(
                                  (file) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.attach_file),
                                    title: Text(
                                      (file['fileName'] ??
                                              file['name'] ??
                                              'File')
                                          .toString(),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : () => _submit(profile),
                          icon: const Icon(Icons.send_outlined),
                          label: Text(
                            _saving ? 'Submitting...' : 'Submit request',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
}
