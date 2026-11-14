import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pawfinder/features/moderation/models/abuse_report_model.dart';
import 'package:pawfinder/features/moderation/widgets/report_abuse_dialog.dart';
import 'package:pawfinder/features/moderation/screens/admin_moderation_screen.dart';

void main() {
  group('AbuseReportModel JSON Deserialization', () {
    test('Parses full abuse report payload correctly', () {
      final json = {
        'id': 'ar-123',
        'reporter_id': 'user-1',
        'reported_user_id': 'user-2',
        'pet_report_id': 'rep-456',
        'reason': '[Suspicious listing] Asking for wired funds.',
        'status': 'under_review',
        'created_at': '2026-11-14T14:00:00.000Z',
        'reporter': {'id': 'user-1', 'name': 'Alice', 'email': 'alice@example.com', 'role': 'user'},
        'reported_user': {'id': 'user-2', 'name': 'Bob', 'email': 'bob@example.com', 'role': 'user'},
        'pet_report': {
          'id': 'rep-456',
          'pet_name': 'Rocky',
          'animal_type': 'Dog',
          'report_type': 'LOST',
          'status': 'Open',
        },
      };

      final model = AbuseReportModel.fromJson(json);

      expect(model.id, 'ar-123');
      expect(model.reporterId, 'user-1');
      expect(model.reportedUserId, 'user-2');
      expect(model.petReportId, 'rep-456');
      expect(model.status, 'under_review');
      expect(model.isUnderReview, isTrue);
      expect(model.isResolved, isFalse);
      expect(model.reporterName, 'Alice');
      expect(model.reportedUserName, 'Bob');
      expect(model.petName, 'Rocky');
    });
  });

  group('ReportAbuseDialog Widget Tests', () {
    testWidgets('Renders categories and validates reason field', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ReportAbuseDialog(
                petReportId: 'rep-456',
                entityTitle: 'Rocky Dog Listing',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Report Abuse'), findsOneWidget);
      expect(find.text('Reporting: Rocky Dog Listing'), findsOneWidget);
      expect(find.text('Submit Report'), findsOneWidget);

      // Submit without reason
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter at least 5 characters of detail'), findsOneWidget);
    });
  });

  group('AdminModerationScreen Widget Tests', () {
    testWidgets('Renders moderation queue header and chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AdminModerationScreen(),
          ),
        ),
      );

      expect(find.text('Moderation Queue'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
    });
  });
}
