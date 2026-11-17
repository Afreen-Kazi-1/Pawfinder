import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../app/routes.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18, color: AppColors.primary),
              label: const Text(
                'Mark All Read',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              onPressed: () => notifier.markAllAsRead(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips: All vs Unread
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: state.filterRead == null,
                  onSelected: (_) => notifier.setFilter(null),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: state.filterRead == null ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: state.filterRead == null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Unread (${state.unreadCount})'),
                  selected: state.filterRead == false,
                  onSelected: (_) => notifier.setFilter(false),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: state.filterRead == false ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: state.filterRead == false ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Notification List / States
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadNotifications(),
              child: _buildBody(context, state, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationState state,
    NotificationNotifier notifier,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.loadNotifications(),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              state.filterRead == false
                  ? Icons.mark_email_read_outlined
                  : Icons.notifications_none_outlined,
              size: 56,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              state.filterRead == false
                  ? 'All caught up! No unread notifications.'
                  : 'No notifications yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Updates regarding your matches, reports, and contact requests appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notif = state.notifications[index];
        return _buildNotificationCard(context, notif, notifier);
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    NotificationModel notif,
    NotificationNotifier notifier,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final formattedDate = dateFormat.format(notif.createdAt.toLocal());
    final isUnread = !notif.isRead;

    final iconData = _getNotificationIcon(notif.notificationTypeClean);
    final iconColor = _getNotificationColor(notif.notificationTypeClean);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isUnread ? AppColors.primary.withValues(alpha: 0.35) : AppColors.surfaceVariant,
          width: isUnread ? 1.5 : 1,
        ),
      ),
      color: isUnread ? AppColors.primary.withValues(alpha: 0.04) : AppColors.surface,
      elevation: isUnread ? 1.5 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (isUnread) {
            notifier.markAsRead(notif.id);
          }
          _handleNavigation(context, notif);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event Type Icon Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Notification Title, Message & Timestamp
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                        if (notif.relatedEntityId != null)
                          const Text(
                            'Tap to view ›',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return Icons.auto_awesome_rounded;
      case 'contact_request':
        return Icons.mail_rounded;
      case 'contact_response':
        return Icons.mark_email_read_rounded;
      case 'resolved':
        return Icons.verified_rounded;
      case 'status_update':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'match':
        return AppColors.secondary;
      case 'contact_request':
        return AppColors.info;
      case 'contact_response':
      case 'resolved':
        return AppColors.success;
      case 'status_update':
      default:
        return AppColors.primary;
    }
  }

  void _handleNavigation(BuildContext context, NotificationModel notif) {
    switch (notif.notificationTypeClean.toLowerCase()) {
      case 'match':
        Navigator.of(context).pushNamed(AppRoutes.home); // Tab 2 is Matches in shell
        break;
      case 'contact_request':
      case 'contact_response':
        Navigator.of(context).pushNamed(AppRoutes.contactRequests);
        break;
      case 'status_update':
      case 'resolved':
        Navigator.of(context).pushNamed(AppRoutes.myReports);
        break;
      default:
        break;
    }
  }
}

extension on NotificationModel {
  String get notificationTypeClean => notificationType;
}

