import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../models/complaint.dart';
import '../models/service_request.dart';

class DswAnalyticsSnapshot {
  final int totalRequests;
  final int openRequests;
  final int resolvedRequests;
  final int urgentRequests;
  final int totalComplaints;
  final int unresolvedComplaints;
  final int duplicateFlags;
  final Map<String, int> requestsByType;
  final Map<String, int> requestsByStatus;
  final Map<String, int> complaintsByCategory;
  final double averageResolutionHours;
  final List<String> aiInsights;

  const DswAnalyticsSnapshot({
    required this.totalRequests,
    required this.openRequests,
    required this.resolvedRequests,
    required this.urgentRequests,
    required this.totalComplaints,
    required this.unresolvedComplaints,
    required this.duplicateFlags,
    required this.requestsByType,
    required this.requestsByStatus,
    required this.complaintsByCategory,
    required this.averageResolutionHours,
    required this.aiInsights,
  });
}

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<DswAnalyticsSnapshot> load() async {
    final results = await Future.wait([
      _firestore.collection('service_requests').get(),
      _firestore.collection('complaints').get(),
    ]);
    final requests = results[0].docs
        .map((doc) => ServiceRequest.fromMap(doc.data(), id: doc.id))
        .toList();
    final complaints = results[1].docs
        .map((doc) => Complaint.fromMap(doc.data(), id: doc.id))
        .toList();

    final requestsByType = <String, int>{};
    final requestsByStatus = <String, int>{};
    final complaintsByCategory = <String, int>{};
    var totalResolutionHours = 0.0;
    var resolutionCount = 0;

    for (final request in requests) {
      requestsByType[request.requestTypeLabel] =
          (requestsByType[request.requestTypeLabel] ?? 0) + 1;
      requestsByStatus[request.status] =
          (requestsByStatus[request.status] ?? 0) + 1;
      if (request.resolvedAt != null) {
        totalResolutionHours += request.resolvedAt!
                .difference(request.createdAt)
                .inMinutes /
            60.0;
        resolutionCount++;
      }
    }
    for (final complaint in complaints) {
      complaintsByCategory[complaint.category] =
          (complaintsByCategory[complaint.category] ?? 0) + 1;
    }

    final base = DswAnalyticsSnapshot(
      totalRequests: requests.length,
      openRequests: requests.where((e) => e.status != 'RESOLVED').length,
      resolvedRequests: requests.where((e) => e.status == 'RESOLVED').length,
      urgentRequests:
          requests
              .where((e) =>
                  ['HIGH', 'URGENT'].contains(e.priority) ||
                  ['HIGH', 'URGENT'].contains(e.aiSuggestedPriority))
              .length,
      totalComplaints: complaints.length,
      unresolvedComplaints:
          complaints.where((e) => e.status != 'RESOLVED').length,
      duplicateFlags: requests.where((e) => e.aiDuplicateScore >= 0.65).length +
          complaints.where((e) => e.aiDuplicateScore >= 0.65).length,
      requestsByType: requestsByType,
      requestsByStatus: requestsByStatus,
      complaintsByCategory: complaintsByCategory,
      averageResolutionHours:
          resolutionCount == 0 ? 0 : totalResolutionHours / resolutionCount,
      aiInsights: const [],
    );

    final insights = await _generateInsights(base);
    return DswAnalyticsSnapshot(
      totalRequests: base.totalRequests,
      openRequests: base.openRequests,
      resolvedRequests: base.resolvedRequests,
      urgentRequests: base.urgentRequests,
      totalComplaints: base.totalComplaints,
      unresolvedComplaints: base.unresolvedComplaints,
      duplicateFlags: base.duplicateFlags,
      requestsByType: base.requestsByType,
      requestsByStatus: base.requestsByStatus,
      complaintsByCategory: base.complaintsByCategory,
      averageResolutionHours: base.averageResolutionHours,
      aiInsights: insights,
    );
  }

  Future<List<String>> _generateInsights(DswAnalyticsSnapshot data) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
      final payload = jsonEncode({
        'totalRequests': data.totalRequests,
        'openRequests': data.openRequests,
        'resolvedRequests': data.resolvedRequests,
        'urgentRequests': data.urgentRequests,
        'totalComplaints': data.totalComplaints,
        'unresolvedComplaints': data.unresolvedComplaints,
        'duplicateFlags': data.duplicateFlags,
        'averageResolutionHours': data.averageResolutionHours,
        'requestsByType': data.requestsByType,
        'requestsByStatus': data.requestsByStatus,
        'complaintsByCategory': data.complaintsByCategory,
      });
      final response = await model.generateContent([
        Content.text(
          '''You are a management analytics assistant for a university DSW office. Analyze only these aggregated, non-personal metrics. Return JSON only: {"insights":["...","...","..."]}. Provide 3 concise operational insights or recommendations. Do not invent facts or individuals. Metrics: $payload''',
        ),
      ]);
      final decoded = jsonDecode(response.text ?? '{}');
      if (decoded is Map && decoded['insights'] is List) {
        return (decoded['insights'] as List)
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .take(4)
            .toList();
      }
    } catch (_) {}
    return _localInsights(data);
  }

  List<String> _localInsights(DswAnalyticsSnapshot data) {
    final insights = <String>[];
    if (data.totalRequests == 0 && data.totalComplaints == 0) {
      return const [
        'No operational data is available yet. Insights will appear after requests or complaints are submitted.',
      ];
    }

    if (data.openRequests > data.resolvedRequests && data.openRequests > 0) {
      insights.add(
        'Open service requests currently exceed resolved requests; review queue capacity and assignment speed.',
      );
    }
    if (data.urgentRequests > 0) {
      insights.add(
        '${data.urgentRequests} high or urgent request(s) need priority review.',
      );
    }
    if (data.unresolvedComplaints > 0) {
      insights.add(
        '${data.unresolvedComplaints} complaint(s) remain unresolved; check for aging or repeatedly reported issues.',
      );
    }
    if (data.duplicateFlags > 0) {
      insights.add(
        '${data.duplicateFlags} potential duplicate flag(s) were detected; consider grouping related incidents before assigning work.',
      );
    }
    if (data.averageResolutionHours > 0) {
      insights.add(
        'Average request resolution time is ${data.averageResolutionHours.toStringAsFixed(1)} hours.',
      );
    }
    if (insights.isEmpty) {
      insights.add(
        'Current workload appears balanced from the available aggregate metrics.',
      );
    }
    return insights.take(4).toList();
  }
}
