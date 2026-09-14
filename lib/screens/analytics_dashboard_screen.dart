import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../widgets/backend_setup_notice.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late Future<DswAnalyticsSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = AnalyticsService.instance.load();
  }

  void _refresh() => setState(() => _future = AnalyticsService.instance.load());

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('DSW Analytics'),
          actions: [
            IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: FutureBuilder<DswAnalyticsSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final errorText = snapshot.error.toString();
              if (errorText.contains('permission-denied') ||
                  errorText.contains('PERMISSION_DENIED')) {
                return BackendSetupNotice(
                  title: 'Analytics access is not enabled yet',
                  message:
                      'Analytics reads the protected service_requests and complaints collections. Deploy this project’s Firebase security rules, then retry as a DSW Officer or Director.',
                  onRetry: _refresh,
                );
              }
              return Center(child: Text('Could not load analytics: $errorText'));
            }
            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Operations overview',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    _Metric('Open requests', data.openRequests, Icons.inbox_outlined),
                    _Metric('Resolved', data.resolvedRequests, Icons.task_alt_outlined),
                    _Metric('High / urgent', data.urgentRequests, Icons.priority_high),
                    _Metric('Open complaints', data.unresolvedComplaints, Icons.report_outlined),
                    _Metric('Duplicate flags', data.duplicateFlags, Icons.content_copy_outlined),
                    _Metric(
                      'Avg resolution',
                      data.averageResolutionHours.round(),
                      Icons.schedule,
                      suffix: 'h',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Breakdown(title: 'Requests by status', values: data.requestsByStatus),
                const SizedBox(height: 12),
                _Breakdown(title: 'Requests by service', values: data.requestsByType),
                const SizedBox(height: 12),
                _Breakdown(title: 'Complaints by category', values: data.complaintsByCategory),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_outlined),
                            const SizedBox(width: 8),
                            Text('AI management insights',
                                style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...data.aiInsights.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $item'),
                          ),
                        ),
                        const Text(
                          'Insights use aggregated metrics only and are advisory.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final String suffix;
  const _Metric(this.label, this.value, this.icon, {this.suffix = ''});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('$value$suffix',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(label),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _Breakdown extends StatelessWidget {
  final String title;
  final Map<String, int> values;
  const _Breakdown({required this.title, required this.values});

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (entries.isEmpty) const Text('No data yet.'),
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key.replaceAll('_', ' '))),
                    Text('${entry.value}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
