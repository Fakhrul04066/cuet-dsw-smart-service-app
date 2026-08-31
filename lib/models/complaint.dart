import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String studentId;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String? aiSummary;
  final String? aiSuggestedDepartment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? officerResponse;
  final List<Map<String, dynamic>> attachments;

  const Complaint({
    required this.id,
    required this.studentId,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.aiSummary,
    this.aiSuggestedDepartment,
    required this.createdAt,
    required this.updatedAt,
    this.officerResponse,
    this.attachments = const [],
  });

  factory Complaint.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Complaint.fromMap(snapshot.data() ?? {}, id: snapshot.id);
  }

  factory Complaint.fromMap(Map<String, dynamic> data, {String? id}) {
    final now = DateTime.now();

    return Complaint(
      id: id ?? (data['id'] ?? '').toString(),
      studentId: (data['studentId'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      priority: (data['priority'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      aiSummary: _stringOrNull(data['aiSummary']),
      aiSuggestedDepartment: _stringOrNull(data['aiSuggestedDepartment']),
      createdAt: _toDateTime(data['createdAt'], fallback: now),
      updatedAt: _toDateTime(data['updatedAt'], fallback: now),
      officerResponse: _stringOrNull(data['officerResponse']),
      attachments: _attachmentList(data['attachments']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    final created = createdAt;
    final updated = updatedAt;

    return {
      'id': id,
      'studentId': studentId,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'status': status,
      'aiSummary': aiSummary,
      'aiSuggestedDepartment': aiSuggestedDepartment,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(created),
      'updatedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updated),
      'officerResponse': officerResponse,
      'attachments': attachments,
    };
  }

  Complaint copyWith({
    String? id,
    String? studentId,
    String? title,
    String? description,
    String? category,
    String? priority,
    String? status,
    String? aiSummary,
    String? aiSuggestedDepartment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? officerResponse,
    List<Map<String, dynamic>>? attachments,
  }) {
    return Complaint(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      aiSummary: aiSummary ?? this.aiSummary,
      aiSuggestedDepartment:
          aiSuggestedDepartment ?? this.aiSuggestedDepartment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      officerResponse: officerResponse ?? this.officerResponse,
      attachments: attachments ?? this.attachments,
    );
  }

  static DateTime _toDateTime(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final stringValue = value.toString();
    return stringValue.isEmpty ? null : stringValue;
  }

  static List<Map<String, dynamic>> _attachmentList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }
}
