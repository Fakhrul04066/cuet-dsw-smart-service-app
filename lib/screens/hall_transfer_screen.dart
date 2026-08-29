import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _studentNameController.dispose();
    _studentIdController.dispose();
    _currentHallController.dispose();
    _preferredHallController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _submitForm() {
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hall Transfer Submitted'),
        content: const Text(
          'Your Hall Transfer request has been submitted successfully.\n\nTracking Number: HT-2026-0015',
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
