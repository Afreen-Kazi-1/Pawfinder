import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/providers/auth_provider.dart';
import '../data/notification_repository.dart';
import '../models/notification_model.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});

class NotificationState {
  final bool isLoading;
  final String? errorMessage;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool? filterRead; // null = all, false = unread only, true = read only

  const NotificationState({
    this.isLoading = false,
    this.errorMessage,
    this.notifications = const [],
    this.unreadCount = 0,
    this.filterRead,
  });

  NotificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? filterRead,
    bool clearFilter = false,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      filterRead: clearFilter ? null : (filterRead ?? this.filterRead),
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  late final NotificationRepository _repository;

  @override
  NotificationState build() {
    _repository = ref.watch(notificationRepositoryProvider);
    Future.microtask(() => loadNotifications());
    return const NotificationState();
  }

  void setFilter(bool? isRead) {
    state = state.copyWith(filterRead: isRead, clearFilter: isRead == null);
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.getNotifications(isRead: state.filterRead);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        notifications: res.items,
        unreadCount: res.unreadCount,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final updated = await _repository.markAsRead(id);
      if (!ref.mounted) return;
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.id == id ? updated : n).toList(),
        unreadCount: (state.unreadCount > 0) ? state.unreadCount - 1 : 0,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      if (!ref.mounted) return;
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
        unreadCount: 0,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});

// Simple provider for unread badge count
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

