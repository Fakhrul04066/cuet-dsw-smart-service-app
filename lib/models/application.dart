import 'package:cloud_firestore/cloud_firestore.dart';

class Application {
  final String id;
  final String type;
  final String studentId;
  final String studentUid;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? currentReviewer;
  final String purpose;
  final String description;
  final List<Map<String, dynamic>> documents;
  final String? officerComment;
  final String? directorComment;
  final String? currentHall;
  final String? requestedHall;
  final String? reason;

  const Application({
    required this.id,
    required this.type,
    required this.studentId,
    this.studentUid = '',
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.currentReviewer,
    this.purpose = '',
    this.description = '',
    this.documents = const [],
    this.officerComment,
    this.directorComment,
    this.currentHall,
    this.requestedHall,
    this.reason,
  });

  factory Application.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return Application.fromMap(snapshot.data() ?? {}, id: snapshot.id);
  }

  factory Application.fromMap(Map<String, dynamic> data, {String? id}) {
    final now = DateTime.now();

    return Application(
      id: id ?? (data['id'] ?? '').toString(),
      type: (data['type'] ?? '').toString(),
      studentId: (data['studentId'] ?? '').toString(),
      studentUid: (data['studentUid'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      createdAt: _toDateTime(data['createdAt'], fallback: now),
      updatedAt: _toDateTime(data['updatedAt'], fallback: now),
      currentReviewer: _stringOrNull(data['currentReviewer']),
      purpose: (data['purpose'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      documents: _docList(data['documents']),
      officerComment: _stringOrNull(data['officerComment']),
      directorComment: _stringOrNull(data['directorComment']),
      currentHall: _stringOrNull(data['currentHall']),
      requestedHall: _stringOrNull(data['requestedHall']),
      reason: _stringOrNull(data['reason']),
    );
  }

  Map<String, dynamic> toFirestore({bool useServerTimestamps = false}) {
    final created = createdAt;
    final updated = updatedAt;

    return {
      'id': id,
      'type': type,
      'studentId': studentId,
      'studentUid': studentUid,
      'status': status,
      'createdAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(created),
      'updatedAt': useServerTimestamps
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(updated),
      'currentReviewer': currentReviewer,
      'purpose': purpose,
      'description': description,
      'documents': documents,
      'officerComment': officerComment,
      'directorComment': directorComment,
      'currentHall': currentHall,
      'requestedHall': requestedHall,
      'reason': reason,
    };
  }

  Application copyWith({
    String? id,
    String? type,
    String? studentId,
    String? studentUid,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentReviewer,
    String? purpose,
    String? description,
    List<Map<String, dynamic>>? documents,
    String? officerComment,
    String? directorComment,
    String? currentHall,
    String? requestedHall,
    String? reason,
  }) {
    return Application(
      id: id ?? this.id,
      type: type ?? this.type,
      studentId: studentId ?? this.studentId,
      studentUid: studentUid ?? this.studentUid,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentReviewer: currentReviewer ?? this.currentReviewer,
      purpose: purpose ?? this.purpose,
      description: description ?? this.description,
      documents: documents ?? this.documents,
      officerComment: officerComment ?? this.officerComment,
      directorComment: directorComment ?? this.directorComment,
      currentHall: currentHall ?? this.currentHall,
      requestedHall: requestedHall ?? this.requestedHall,
      reason: reason ?? this.reason,
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

  static List<Map<String, dynamic>> _docList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }
}
