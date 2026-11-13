import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/features/reports/models/pet_report_model.dart';
import 'package:pawfinder/features/reports/providers/report_provider.dart';
import 'package:pawfinder/features/reports/screens/my_reports_screen.dart';

void main() {
  group('MyReportsScreen Tests', () {
    testWidgets('Renders empty state when user has no reports', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myReportsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: MyReportsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Reports Submitted'), findsOneWidget);
      expect(find.text('You have not submitted any lost or found pet reports yet.'), findsOneWidget);
    });

    testWidgets('Renders list of reports with status badges and details', (WidgetTester tester) async {
      final sampleReports = [
        PetReportModel(
          id: 'report-1',
          userId: 'user-1',
          reportType: 'LOST',
          petName: 'Rusty',
          animalType: 'Dog',
          breed: 'Golden Retriever',
          color: 'Golden',
          distinguishingFeatures: 'Red bandana',
          description: 'Friendly dog',
          latitude: 37.77,
          longitude: -122.41,
          locationLabel: 'Mission Dolores Park',
          eventDatetime: DateTime(2026, 11, 12, 14, 0),
          reward: 200,
          status: 'Open',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        PetReportModel(
          id: 'report-2',
          userId: 'user-1',
          reportType: 'FOUND',
          animalType: 'Cat',
          color: 'Black and White',
          distinguishingFeatures: 'Green collar',
          description: 'Found outside grocery store',
          latitude: 37.78,
          longitude: -122.42,
          locationLabel: 'Valencia St',
          eventDatetime: DateTime(2026, 11, 13, 9, 30),
          status: 'Reunited / Resolved',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myReportsProvider.overrideWith((ref) => Future.value(sampleReports)),
          ],
          child: const MaterialApp(
            home: MyReportsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify report cards
      expect(find.text('Rusty'), findsOneWidget);
      expect(find.text('LOST'), findsOneWidget);
      expect(find.text('FOUND'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Reunited / Resolved'), findsOneWidget);
      expect(find.text('Mission Dolores Park'), findsOneWidget);
      expect(find.text('Valencia St'), findsOneWidget);
    });
  });
}

