import 'package:flutter/material.dart';

import '../widgets/custom_text_field.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Hall Facilities';
  bool _confidential = false;

  final List<String> _categories = [
    'Hall Facilities',
    'Academic',
    'Student Welfare',
    'Harassment / Safety',
    'Administrative',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitComplaint() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complaint Submitted'),
        content: const Text(
          'Your complaint has been submitted successfully.\n\nTracking Number: CMP-2026-0021',
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
      appBar: AppBar(title: const Text('Student Complaint')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Complaint Category',
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value ?? _selectedCategory;
                    });
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _titleController,
                  labelText: 'Complaint Title',
                  prefixIcon: Icons.title_rounded,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a complaint title'
                      : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
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
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _confidential,
                  onChanged: (value) {
                    setState(() {
                      _confidential = value ?? false;
                    });
                  },
                  title: const Text('Mark as confidential complaint'),
                ),
                if (_confidential) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'Confidential complaints will have restricted visibility to authorized officials.',
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE0E7F1)),
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
                        'Attachment Area',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Upload screenshots, evidence, or supporting documents.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.smart_toy_outlined,
                            color: Color(0xFF0D47A1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Complaint Assistance',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'AI support for complaint drafting and issue classification will be added in a future update.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitComplaint,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Submit Complaint'),
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
