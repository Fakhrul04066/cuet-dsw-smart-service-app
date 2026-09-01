import 'package:flutter/material.dart';

import '../services/ai_assistant_service.dart';
import '../services/auth_service.dart';
import '../services/character_certificate_service.dart';
import '../services/firebase_storage_service.dart';
import '../widgets/custom_text_field.dart';

class CharacterCertificateScreen extends StatefulWidget {
  const CharacterCertificateScreen({super.key});

  @override
  State<CharacterCertificateScreen> createState() =>
      _CharacterCertificateScreenState();
}

class _CharacterCertificateScreenState
    extends State<CharacterCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _levelController = TextEditingController();
  final _termController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purposeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _documentsController = TextEditingController();
  bool _declarationAccepted = false;
  bool _checkingForm = false;
  bool _isSubmitting = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  final _uploadedDocuments = <Map<String, dynamic>>[];
  late final String _applicationId;
  Map<String, dynamic>? _aiCheckResult;

  @override
  void initState() {
    super.initState();
    _applicationId = DateTime.now().microsecondsSinceEpoch.toString();
    _loadStudentProfile();
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _levelController.dispose();
    _termController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _purposeController.dispose();
    _descriptionController.dispose();
    _documentsController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentProfile() async {
    final profile = await AuthService.instance.getCurrentUserProfile();
    if (!mounted || profile == null) {
      return;
    }

    setState(() {
      _studentNameController.text = profile.name;
      _studentIdController.text = profile.studentId;
      _departmentController.text = profile.department;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
    });
  }

  Future<void> _runAiCheck() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _checkingForm = true);
    try {
      final result = GeminiAssistantService.instance.checkApplicationForm(
        applicationType: 'Character Certificate',
        formFields: {
          'studentName': _studentNameController.text,
          'studentId': _studentIdController.text,
          'department': _departmentController.text,
          'level': _levelController.text,
          'term': _termController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'purpose': _purposeController.text,
          'description': _descriptionController.text,
        },
      );
      setState(() => _aiCheckResult = result);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI Form Check'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(GeminiAssistantService.advisoryNotice),
                const SizedBox(height: 12),
                if ((result['missingFields'] as List).isNotEmpty) ...[
                  const Text('Missing:'),
                  ...((result['missingFields'] as List).map(
                    (item) => Text('• $item'),
                  )),
                  const SizedBox(height: 8),
                ],
                if ((result['unclearStatements'] as List).isNotEmpty) ...[
                  const Text('Suggestions:'),
                  ...((result['unclearStatements'] as List).map(
                    (item) => Text('• $item'),
                  )),
                  const SizedBox(height: 8),
                ],
                if ((result['possibleInconsistencies'] as List).isNotEmpty) ...[
                  const Text('Potential inconsistency:'),
                  ...((result['possibleInconsistencies'] as List).map(
                    (item) => Text('• $item'),
                  )),
                  const SizedBox(height: 8),
                ],
                const Text('Suggestions:'),
                ...((result['suggestions'] as List).map(
                  (item) => Text('• $item'),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI assistance is currently unavailable. You may continue manually.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checkingForm = false);
      }
    }
  }

  Future<void> _previewAndSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the declaration before submitting.'),
        ),
      );
      return;
    }

    final documents = _documentsController.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final preview = AlertDialog(
      title: const Text('Preview Character Certificate'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Student: ${_studentNameController.text}'),
            const SizedBox(height: 4),
            Text('Student ID: ${_studentIdController.text}'),
            const SizedBox(height: 4),
            Text('Department: ${_departmentController.text}'),
            const SizedBox(height: 4),
            Text(
              'Level / Term: ${_levelController.text} / ${_termController.text}',
            ),
            const SizedBox(height: 12),
            const Text('Purpose:'),
            Text(_purposeController.text),
            const SizedBox(height: 12),
            const Text('Description:'),
            Text(_descriptionController.text),
            const SizedBox(height: 12),
            const Text('Supporting Documents:'),
            if (documents.isEmpty)
              const Text('No supporting document list provided.')
            else
              ...documents.map((doc) => Text('• $doc')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Edit'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _submitForm();
          },
          child: const Text('Submit'),
        ),
      ],
    );

    await showDialog<void>(context: context, builder: (_) => preview);
  }

  Future<void> _submitForm() async {
    final purpose = _purposeController.text.trim();
    final description = _descriptionController.text.trim();
    if (purpose.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the purpose and description.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final documents = _documentsController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .where(
            (item) =>
                !_uploadedDocuments.any((file) => file['fileName'] == item),
          )
          .toList();

      final application = await CharacterCertificateService.instance
          .submitCharacterCertificate(
            purpose: purpose,
            description: description,
            applicationId: _applicationId,
            documents: [
              ..._uploadedDocuments,
              ...documents.map(
                (document) => {'name': document, 'type': 'supporting_document'},
              ),
            ],
          );

      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Application Submitted'),
          content: Text(
            'Your character certificate application has been submitted successfully.\n\nApplication ID: ${application.id}\nStatus: ${CharacterCertificateStatus.timelineLabel(application.status)}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _pickDocuments() async {
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
        folder: 'applications/$_applicationId/documents',
        onProgress: (progress) => setState(() => _uploadProgress = progress),
      );
      _uploadedDocuments.addAll(files);
      _documentsController.text = _uploadedDocuments
          .map((file) => file['fileName'])
          .join(', ');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Character Certificate')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply for a character certificate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _studentNameController,
                  labelText: 'Student Name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _studentIdController,
                  labelText: 'Student ID',
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your student ID'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _departmentController,
                  labelText: 'Department',
                  prefixIcon: Icons.school_outlined,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your department'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _levelController,
                        labelText: 'Level',
                        prefixIcon: Icons.format_list_numbered_rounded,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _termController,
                        labelText: 'Term',
                        prefixIcon: Icons.calendar_month_outlined,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Required'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _purposeController,
                  labelText: 'Purpose of Certificate',
                  prefixIcon: Icons.help_outline_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please explain the purpose'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Additional Details',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please tell us more about the request'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _documentsController,
                  labelText: 'Supporting Documents',
                  hintText: 'Student ID Card, transcript, etc.',
                  prefixIcon: Icons.attach_file_rounded,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _pickDocuments,
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
                        : 'Choose supporting files',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _declarationAccepted,
                      onChanged: (value) {
                        setState(() {
                          _declarationAccepted = value ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'I confirm the information above is accurate and complete.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checkingForm ? null : _runAiCheck,
                    icon: _checkingForm
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.smart_toy_outlined),
                    label: Text(
                      _checkingForm ? 'Checking Form...' : 'AI Check',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_aiCheckResult != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          GeminiAssistantService.advisoryNotice,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        ...(((_aiCheckResult!['suggestions'] as List?) ?? [])
                            .map((item) => Text('• $item'))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSubmitting ? null : _previewAndSubmit,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
