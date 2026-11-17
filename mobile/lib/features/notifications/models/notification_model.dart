class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String notificationType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? notificationType,
    String? relatedEntityId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: json['notification_type'] as String,
      relatedEntityId: json['related_entity_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class NotificationListModel {
  final List<NotificationModel> items;
  final int total;
  final int unreadCount;

  NotificationListModel({
    required this.items,
    required this.total,
    required this.unreadCount,
  });

  factory NotificationListModel.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?) ?? [];
    return NotificationListModel(
      items: list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}

