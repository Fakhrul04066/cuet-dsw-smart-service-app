import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../widgets/application_card.dart';
import 'application_details_screen.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _selectedType = 'All';
  String _selectedStatus = 'All';

  final List<String> _types = [
    'All',
    'Character Certificate',
    'Hall Transfer',
    'Student Complaint',
  ];
  final List<String> _statuses = [
    'All',
    'Submitted',
    'Under Review',
    'Correction Required',
    'Resubmitted',
    'Approved',
    'Rejected',
    'Assigned',
    'In Progress',
    'Resolved',
    'Closed',
  ];

  @override
  Widget build(BuildContext context) {
    final applications = MockData.applications.where((application) {
      final matchesType =
          _selectedType == 'All' || application.serviceType == _selectedType;
      final matchesStatus =
          _selectedStatus == 'All' || application.status == _selectedStatus;
      return matchesType && matchesStatus;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Types'),
                    selected: _selectedType == 'All',
                    onSelected: (_) => setState(() => _selectedType = 'All'),
                  ),
                  ..._types
                      .where((type) => type != 'All')
                      .map(
                        (type) => ChoiceChip(
                          label: Text(type),
                          selected: _selectedType == type,
                          onSelected: (_) =>
                              setState(() => _selectedType = type),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: _selectedStatus == status,
                            onSelected: (_) =>
                                setState(() => _selectedStatus = status),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: applications.isEmpty
                    ? const Center(
                        child: Text(
                          'No applications match the selected filters.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final application = applications[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ApplicationCard(
                              application: application,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ApplicationDetailsScreen(
                                      application: application,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
