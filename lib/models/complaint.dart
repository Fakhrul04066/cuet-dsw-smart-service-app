import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  static const categories = [
    'Hall Facilities',
    'Academic',
    'Student Welfare',
    'Harassment / Safety',
    'Administrative',
    'Other',
  ];

  final String id;
  final String trackingNumber;
  final String studentId;
  final String studentUid;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String? aiSuggestedCategory;
  final String? aiSuggestedPriority;
  final String? aiSummary;
  final String? aiSuggestedDepartment;
  final double aiDuplicateScore;
  final String aiDuplicateComplaintId;
  final String aiDuplicateReason;
  final String aiImageAssessment;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? officerResponse;
  final String? directorResponse;
  final String? correctionNote;
  final String assignedOfficerUid;
  final String assignedOfficerName;
  final bool isConfidential;
  final List<Map<String, dynamic>> attachments;

  const Complaint({
    required this.id,
    this.trackingNumber = '',
    required this.studentId,
    this.studentUid = '',
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    this.aiSuggestedCategory,
    this.aiSuggestedPriority,
    this.aiSummary,
    this.aiSuggestedDepartment,
    this.aiDuplicateScore = 0,
    this.aiDuplicateComplaintId = '',
    this.aiDuplicateReason = '',
    this.aiImageAssessment = '',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.officerResponse,
    this.directorResponse,
    this.correctionNote,
    this.assignedOfficerUid = '',
    this.assignedOfficerName = '',
    this.isConfidential = false,
    this.attachments = const [],
  });

  factory Complaint.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) => Complaint.fromMap(snapshot.data() ?? {}, id: snapshot.id);

  factory Complaint.fromMap(Map<String, dynamic> data, {String? id}) {
    final now = DateTime.now();
    return Complaint(
      id: id ?? (data['id'] ?? '').toString(),
      trackingNumber: (data['trackingNumber'] ?? '').toString(),
      studentId: (data['studentId'] ?? '').toString(),
      studentUid: (data['studentUid'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      priority: (data['priority'] ?? 'NORMAL').toString().toUpperCase(),
      aiSuggestedCategory: _stringOrNull(data['aiSuggestedCategory']),
      aiSuggestedPriority: _stringOrNull(data['aiSuggestedPriority']),
      aiSummary: _stringOrNull(data['aiSummary']),
      aiSuggestedDepartment: _stringOrNull(data['aiSuggestedDepartment']),
      aiDuplicateScore: _toDouble(data['aiDuplicateScore']),
      aiDuplicateComplaintId: (data['aiDuplicateComplaintId'] ?? '').toString(),
      aiDuplicateReason: (data['aiDuplicateReason'] ?? '').toString(),
      aiImageAssessment: (data['aiImageAssessment'] ?? '').toString(),
      status: (data['status'] ?? 'SUBMITTED').toString(),
      createdAt: _toDateTime(data['createdAt'], fallback: now),
      updatedAt: _toDateTime(data['updatedAt'], fallback: now),
      officerResponse: _stringOrNull(data['officerResponse']),
      directorResponse: _stringOrNull(data['directorResponse']),
      correctionNote: _stringOrNull(data['correctionNote']),
      assignedOfficerUid: (data['assignedOfficerUid'] ?? '').toString(),
      assignedOfficerName: (data['assignedOfficerName'] ?? '').toString(),
      isConfidential: data['isConfidential'] == true,
      attachments: _attachmentList(data['attachments']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) => {
        'id': id,
        'trackingNumber': trackingNumber,
        'studentId': studentId,
        'studentUid': studentUid,
        'title': title,
        'description': description,
        'category': category,
        'priority': priority,
        'aiSuggestedCategory': aiSuggestedCategory,
        'aiSuggestedPriority': aiSuggestedPriority,
        'aiSummary': aiSummary,
        'aiSuggestedDepartment': aiSuggestedDepartment,
        'aiDuplicateScore': aiDuplicateScore,
        'aiDuplicateComplaintId': aiDuplicateComplaintId,
        'aiDuplicateReason': aiDuplicateReason,
        'aiImageAssessment': aiImageAssessment,
        'status': status,
        'createdAt': useServerTimestamps
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt),
        'updatedAt': useServerTimestamps
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(updatedAt),
        'officerResponse': officerResponse,
        'directorResponse': directorResponse,
        'correctionNote': correctionNote,
        'assignedOfficerUid': assignedOfficerUid,
        'assignedOfficerName': assignedOfficerName,
        'isConfidential': isConfidential,
        'attachments': attachments,
      };

  Complaint copyWith({
    String? id,
    String? trackingNumber,
    String? studentId,
    String? studentUid,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? aiSuggestedCategory,
    String? aiSuggestedPriority,
    String? aiSummary,
    String? aiSuggestedDepartment,
    double? aiDuplicateScore,
    String? aiDuplicateComplaintId,
    String? aiDuplicateReason,
    String? aiImageAssessment,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? officerResponse,
    String? directorResponse,
    String? correctionNote,
    String? assignedOfficerUid,
    String? assignedOfficerName,
    bool? isConfidential,
    List<Map<String, dynamic>>? attachments,
  }) => Complaint(
        id: id ?? this.id,
        trackingNumber: trackingNumber ?? this.trackingNumber,
        studentId: studentId ?? this.studentId,
        studentUid: studentUid ?? this.studentUid,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        aiSuggestedCategory: aiSuggestedCategory ?? this.aiSuggestedCategory,
        aiSuggestedPriority: aiSuggestedPriority ?? this.aiSuggestedPriority,
        aiSummary: aiSummary ?? this.aiSummary,
        aiSuggestedDepartment: aiSuggestedDepartment ?? this.aiSuggestedDepartment,
        aiDuplicateScore: aiDuplicateScore ?? this.aiDuplicateScore,
        aiDuplicateComplaintId:
            aiDuplicateComplaintId ?? this.aiDuplicateComplaintId,
        aiDuplicateReason: aiDuplicateReason ?? this.aiDuplicateReason,
        aiImageAssessment: aiImageAssessment ?? this.aiImageAssessment,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        officerResponse: officerResponse ?? this.officerResponse,
        directorResponse: directorResponse ?? this.directorResponse,
        correctionNote: correctionNote ?? this.correctionNote,
        assignedOfficerUid: assignedOfficerUid ?? this.assignedOfficerUid,
        assignedOfficerName: assignedOfficerName ?? this.assignedOfficerName,
        isConfidential: isConfidential ?? this.isConfidential,
        attachments: attachments ?? this.attachments,
      );

  static DateTime _toDateTime(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return fallback;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final result = value.toString();
    return result.isEmpty ? null : result;
  }

  static List<Map<String, dynamic>> _attachmentList(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : const [];

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
