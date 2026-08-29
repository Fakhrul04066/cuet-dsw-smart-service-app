class NotificationModel {
  final String title;
  final String message;
  final String time;
  final bool isRead;

  const NotificationModel({
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  NotificationModel copyWith({
    String? title,
    String? message,
    String? time,
    bool? isRead,
  }) {
    return NotificationModel(
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}
