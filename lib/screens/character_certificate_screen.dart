import 'package:flutter/material.dart';

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
  bool _declarationAccepted = false;

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
    super.dispose();
  }

  void _submitForm() {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Application Submitted'),
        content: const Text(
          'Your Character Certificate application has been submitted successfully.\n\nTracking Number: CC-2026-0012',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
                  hintText: 'e.g. Higher studies, visa process, job',
                  prefixIcon: Icons.note_alt_outlined,
                  maxLines: 4,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please describe the purpose'
                      : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Required Documents',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE0E7F1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('• Student ID Card'),
                      SizedBox(height: 8),
                      Text('• Transcript Copy'),
                      SizedBox(height: 8),
                      Text('• Passport size photograph'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                        'Mock Document Upload',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      const Text('Selected file: Student_ID_Card.pdf'),
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
                    'I confirm that the information provided is correct and complete.',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.checklist_rounded),
                    label: const Text('Check Form'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitForm,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Submit Application'),
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
