import 'package:flutter/material.dart';

import '../models/application_model.dart';
import '../widgets/service_card.dart';
import '../widgets/status_chip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<ApplicationModel> applications = const [
    ApplicationModel(
      title: 'Character Certificate',
      requestType: 'Application ID: #DSW-1024',
      status: 'Under Review',
      date: 'Submitted on 20 Aug 2026',
    ),
    ApplicationModel(
      title: 'Hall Transfer',
      requestType: 'Application ID: #DSW-1018',
      status: 'In Progress',
      date: 'Submitted on 15 Aug 2026',
    ),
    ApplicationModel(
      title: 'Student Complaint',
      requestType: 'Application ID: #DSW-1007',
      status: 'Approved',
      date: 'Resolved on 10 Aug 2026',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CUET DSW Smart Service',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome, Student',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'How can we help you today?',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Services',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ServiceCard(
                  title: 'Character Certificate',
                  subtitle: 'Apply and track your certificate',
                  icon: Icons.description_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ServiceCard(
                  title: 'Hall Transfer',
                  subtitle: 'Submit and track hall transfer requests',
                  icon: Icons.home_work_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ServiceCard(
                  title: 'Student Complaint',
                  subtitle: 'Submit complaints securely',
                  icon: Icons.report_problem_outlined,
                  onTap: () {},
                ),
                const SizedBox(height: 28),
                Text(
                  'Recent Applications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...applications.map((application) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_rounded,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      application.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF102B52),
                                      ),
                                    ),
                                  ),
                                  StatusChip(label: application.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                application.requestType,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                application.date,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
