import 'package:flutter/material.dart';

import '../services/ai_assistant_service.dart';
import '../services/auth_service.dart';
import '../services/hall_transfer_service.dart';
import '../widgets/custom_text_field.dart';

class HallTransferScreen extends StatefulWidget {
  const HallTransferScreen({super.key});

  @override
  State<HallTransferScreen> createState() => _HallTransferScreenState();
}

class _HallTransferScreenState extends State<HallTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _currentHallController = TextEditingController();
  final _preferredHallController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _declarationAccepted = false;
  bool _checkingForm = false;
  bool _isSubmitting = false;
  Map<String, dynamic>? _aiCheckResult;

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentIdController.dispose();
    _currentHallController.dispose();
    _preferredHallController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final profile = await AuthService.instance.getCurrentUserProfile();
    if (!mounted || profile == null) return;
    setState(() {
      _studentNameController.text = profile.name;
      _studentIdController.text = profile.studentId;
      _currentHallController.text = profile.hall;
    });
  }

  Future<void> _runAiCheck() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _checkingForm = true);
    try {
      final result = GeminiAssistantService.instance.checkApplicationForm(
        applicationType: 'Hall Transfer',
        formFields: {
          'studentName': _studentNameController.text,
          'studentId': _studentIdController.text,
          'currentHall': _currentHallController.text,
          'preferredHall': _preferredHallController.text,
          'reason': _reasonController.text,
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the declaration before submitting.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final application = await HallTransferService.instance.submitHallTransfer(
        currentHall: _currentHallController.text.trim(),
        requestedHall: _preferredHallController.text.trim(),
        reason: _reasonController.text.trim(),
        documents: const [
          {'name': 'hall_transfer_support.pdf', 'type': 'supporting_document'},
        ],
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hall Transfer Submitted'),
          content: Text(
            'Your Hall Transfer request has been submitted successfully.\n\nApplication ID: ${application.id}\nStatus: ${HallTransferStatus.timelineLabel(application.status)}',
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hall Transfer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request a hall transfer',
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
                  controller: _currentHallController,
                  labelText: 'Current Hall',
                  prefixIcon: Icons.home_work_outlined,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter current hall'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _preferredHallController,
                  labelText: 'Preferred Hall',
                  prefixIcon: Icons.location_city_outlined,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter preferred hall'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _reasonController,
                  labelText: 'Reason for Transfer',
                  hintText: 'Explain your reason for requesting transfer',
                  prefixIcon: Icons.edit_note_outlined,
                  maxLines: 5,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please state the reason'
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Supporting Evidence',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.upload_file_rounded,
                        color: Color(0xFF0D47A1),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Mock Evidence Upload',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      const Text('Selected file: hall_transfer_support.pdf'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _declarationAccepted,
                  onChanged: (value) {
                    setState(() {
                      _declarationAccepted = value ?? false;
                    });
                  },
                  title: const Text(
                    'I certify that the information provided is accurate.',
                  ),
                ),
                const SizedBox(height: 8),
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
                        : const Icon(Icons.checklist_rounded),
                    label: Text(
                      _checkingForm ? 'Checking Form...' : 'Check Form with AI',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_aiCheckResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      GeminiAssistantService.advisoryNotice,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isSubmitting ? 'Submitting...' : 'Submit Application',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
