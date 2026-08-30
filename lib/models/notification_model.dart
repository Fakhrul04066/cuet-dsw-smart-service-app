import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userUid;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final Timestamp? createdAt;

  const NotificationModel({
    this.id = '',
    this.userUid = '',
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final createdAt = data['createdAt'];

    return NotificationModel(
      id: id ?? data['id']?.toString() ?? '',
      userUid: data['userUid']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      time: _formatTime(createdAt),
      isRead: data['isRead'] == true,
      createdAt: createdAt is Timestamp ? createdAt : null,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userUid,
    String? title,
    String? message,
    String? time,
    bool? isRead,
    Timestamp? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userUid: userUid ?? this.userUid,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String _formatTime(Object? createdAt) {
    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) {
        return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
      }
      if (diff.inHours > 0) {
        return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
      }
      if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
      }
      return 'Just now';
    }
    return 'Recently';
  }
}
