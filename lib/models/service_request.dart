import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequest {
  static const requestTypes = <String, String>{
    'hall_related': 'Hall-related request',
    'financial_assistance': 'Financial assistance request',
    'student_welfare': 'Student welfare complaint',
    'event_permission': 'Event permission',
    'certificate_recommendation': 'Certificate / recommendation request',
    'general_grievance': 'General grievance',
  };

  static const statuses = [
    'SUBMITTED',
    'CORRECTION_REQUIRED',
    'RESUBMITTED',
    'OFFICER_REVIEW_COMPLETE',
    'APPROVED',
    'REJECTED',
    'RESOLVED',
  ];

  static const finalStatuses = ['APPROVED', 'REJECTED', 'RESOLVED'];

  final String id;
  final String trackingNumber;
  final String studentUid;
  final String studentId;
  final String studentName;
  final String requestType;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String assignedOfficerUid;
  final String assignedOfficerName;
  final String suggestedOffice;
  final String correctionNote;
  final String officerReviewNote;
  final String resolutionNote;
  final List<Map<String, dynamic>> documents;
  final String aiSummary;
  final String aiSuggestedPriority;
  final String aiPriorityReason;
  final List<String> aiRiskTags;
  final double aiDuplicateScore;
  final String aiDuplicateRequestId;
  final String aiDuplicateReason;
  final String aiImageAssessment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const ServiceRequest({
    required this.id,
    required this.trackingNumber,
    required this.studentUid,
    required this.studentId,
    required this.studentName,
    required this.requestType,
    required this.title,
    required this.description,
    required this.status,
    this.priority = 'NORMAL',
    this.assignedOfficerUid = '',
    this.assignedOfficerName = '',
    this.suggestedOffice = '',
    this.correctionNote = '',
    this.officerReviewNote = '',
    this.resolutionNote = '',
    this.documents = const [],
    this.aiSummary = '',
    this.aiSuggestedPriority = 'NORMAL',
    this.aiPriorityReason = '',
    this.aiRiskTags = const [],
    this.aiDuplicateScore = 0,
    this.aiDuplicateRequestId = '',
    this.aiDuplicateReason = '',
    this.aiImageAssessment = '',
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  String get requestTypeLabel => requestTypes[requestType] ?? requestType;
  bool get isFinal => finalStatuses.contains(status);

  factory ServiceRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) =>
      ServiceRequest.fromMap(snapshot.data() ?? {}, id: snapshot.id);

  factory ServiceRequest.fromMap(Map<String, dynamic> data, {String? id}) {
    final now = DateTime.now();
    return ServiceRequest(
      id: id ?? (data['id'] ?? '').toString(),
      trackingNumber: (data['trackingNumber'] ?? '').toString(),
      studentUid: (data['studentUid'] ?? '').toString(),
      studentId: (data['studentId'] ?? '').toString(),
      studentName: (data['studentName'] ?? '').toString(),
      requestType: (data['requestType'] ?? 'general_grievance').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      status: (data['status'] ?? 'SUBMITTED').toString(),
      priority: (data['priority'] ?? 'NORMAL').toString(),
      assignedOfficerUid: (data['assignedOfficerUid'] ?? '').toString(),
      assignedOfficerName: (data['assignedOfficerName'] ?? '').toString(),
      suggestedOffice: (data['suggestedOffice'] ?? '').toString(),
      correctionNote: (data['correctionNote'] ?? '').toString(),
      officerReviewNote: (data['officerReviewNote'] ?? '').toString(),
      resolutionNote: (data['resolutionNote'] ?? '').toString(),
      documents: _mapList(data['documents']),
      aiSummary: (data['aiSummary'] ?? '').toString(),
      aiSuggestedPriority: (data['aiSuggestedPriority'] ?? 'NORMAL').toString(),
      aiPriorityReason: (data['aiPriorityReason'] ?? '').toString(),
      aiRiskTags: _stringList(data['aiRiskTags']),
      aiDuplicateScore: _toDouble(data['aiDuplicateScore']),
      aiDuplicateRequestId: (data['aiDuplicateRequestId'] ?? '').toString(),
      aiDuplicateReason: (data['aiDuplicateReason'] ?? '').toString(),
      aiImageAssessment: (data['aiImageAssessment'] ?? '').toString(),
      createdAt: _toDateTime(data['createdAt'], fallback: now),
      updatedAt: _toDateTime(data['updatedAt'], fallback: now),
      resolvedAt: _nullableDateTime(data['resolvedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) => {
        'id': id,
        'trackingNumber': trackingNumber,
        'studentUid': studentUid,
        'studentId': studentId,
        'studentName': studentName,
        'requestType': requestType,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'assignedOfficerUid': assignedOfficerUid,
        'assignedOfficerName': assignedOfficerName,
        'suggestedOffice': suggestedOffice,
        'correctionNote': correctionNote,
        'officerReviewNote': officerReviewNote,
        'resolutionNote': resolutionNote,
        'documents': documents,
        'aiSummary': aiSummary,
        'aiSuggestedPriority': aiSuggestedPriority,
        'aiPriorityReason': aiPriorityReason,
        'aiRiskTags': aiRiskTags,
        'aiDuplicateScore': aiDuplicateScore,
        'aiDuplicateRequestId': aiDuplicateRequestId,
        'aiDuplicateReason': aiDuplicateReason,
        'aiImageAssessment': aiImageAssessment,
        'createdAt': useServerTimestamps
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt),
        'updatedAt': useServerTimestamps
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(updatedAt),
        'resolvedAt': resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
      };

  static DateTime _toDateTime(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return fallback;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : const [];

  static List<String> _stringList(dynamic value) =>
      value is List ? value.map((item) => item.toString()).toList() : const [];

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
