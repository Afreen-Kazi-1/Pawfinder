import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfinder/features/contact_requests/models/contact_request_model.dart';
import 'package:pawfinder/features/contact_requests/widgets/contact_request_dialog.dart';

void main() {
  group('ContactRequestDialog Widget Tests', () {
    testWidgets('Renders dialog form and validates required message', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ContactRequestDialog(
                reportId: 'rep-123',
                petDisplayName: 'Buddy',
              ),
            ),
          ),
        ),
      );

      // Verify header and fields exist
      expect(find.text('Contact Regarding Buddy'), findsOneWidget);
      expect(find.text('Message *'), findsOneWidget);
      expect(find.text('Send Request'), findsOneWidget);

      // Tap Send Request without entering message
      await tester.tap(find.text('Send Request'));
      await tester.pumpAndSettle();

      // Form validation error appears
      expect(find.text('Please enter a message'), findsOneWidget);
    });
  });

  group('ContactRequestModel Deserialization Tests', () {
    test('Parses complete contact request json and reflects states', () {
      final json = {
        'id': 'cr-100',
        'report_id': 'rep-200',
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'message': 'I spotted your dog at the park',
        'status': 'accepted',
        'created_at': '2026-11-14T10:00:00.000Z',
        'updated_at': '2026-11-14T10:30:00.000Z',
        'sender_contact_info': '+14155550199',
        'receiver_contact_info': 'owner@example.com',
        'sender': {
          'id': 'user-1',
          'name': 'Samaritan',
          'email': 'samaritan@example.com',
          'phone': '+14155550199',
          'profile_image_url': null,
        },
        'receiver': {
          'id': 'user-2',
          'name': 'Pet Owner',
          'email': 'owner@example.com',
          'phone': '+19876543210',
          'profile_image_url': null,
        },
        'report': {
          'id': 'rep-200',
          'report_type': 'LOST',
          'pet_name': 'Milo',
          'animal_type': 'Cat',
          'breed': 'Tabby',
          'status': 'Open',
          'primary_image_url': null,
        }
      };

      final model = ContactRequestModel.fromJson(json);

      expect(model.id, 'cr-100');
      expect(model.isAccepted, isTrue);
      expect(model.isPending, isFalse);
      expect(model.sender.name, 'Samaritan');
      expect(model.receiver.name, 'Pet Owner');
      expect(model.report?.petName, 'Milo');
      expect(model.senderContactInfo, '+14155550199');
      expect(model.receiverContactInfo, 'owner@example.com');
    });
  });
}
