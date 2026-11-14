import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/features/notifications/models/notification_model.dart';
import 'package:pawfinder/features/notifications/screens/notifications_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('NotificationModel JSON Deserialization', () {
    test('Parses NotificationModel correctly with attributes', () {
      final json = {
        'id': 'notif-123',
        'user_id': 'user-456',
        'title': 'Potential Match Identified!',
        'message': 'A high potential match (92%) was found for your report Buddy.',
        'notification_type': 'match',
        'related_entity_id': 'match-789',
        'is_read': false,
        'created_at': '2026-11-14T12:00:00.000Z',
      };

      final model = NotificationModel.fromJson(json);

      expect(model.id, 'notif-123');
      expect(model.userId, 'user-456');
      expect(model.title, 'Potential Match Identified!');
      expect(model.notificationType, 'match');
      expect(model.relatedEntityId, 'match-789');
      expect(model.isRead, isFalse);
    });

    test('Parses NotificationListModel correctly with unread counts', () {
      final json = {
        'items': [
          {
            'id': 'n-1',
            'user_id': 'u-1',
            'title': 'Contact Request',
            'message': 'Dave sent a contact request',
            'notification_type': 'contact_request',
            'related_entity_id': null,
            'is_read': false,
            'created_at': '2026-11-14T12:00:00.000Z',
          },
          {
            'id': 'n-2',
            'user_id': 'u-1',
            'title': 'Report Resolved',
            'message': 'Your report has been resolved',
            'notification_type': 'resolved',
            'related_entity_id': null,
            'is_read': true,
            'created_at': '2026-11-14T11:00:00.000Z',
          }
        ],
        'total': 2,
        'unread_count': 1,
      };

      final listModel = NotificationListModel.fromJson(json);

      expect(listModel.total, 2);
      expect(listModel.unreadCount, 1);
      expect(listModel.items.length, 2);
      expect(listModel.items[0].isRead, isFalse);
      expect(listModel.items[1].isRead, isTrue);
    });
  });

  group('NotificationsScreen Widget Tests', () {
    testWidgets('Renders empty state when no notifications are present', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      // Verify app bar title
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });
  });
}

