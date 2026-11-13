import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/core/widgets/primary_button.dart';
import 'package:pawfinder/features/reports/screens/create_report_screen.dart';

void main() {
  group('Report Form Validation Tests', () {
    testWidgets('Validates required fields on Lost Pet report', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateReportScreen(isLost: true),
          ),
        ),
      );

      // Verify header and lost pet name field
      expect(find.text('Report Lost Pet'), findsOneWidget);
      expect(find.text('Pet Name *'), findsOneWidget);

      // Tap submit button without filling form
      final submitButton = find.byType(PrimaryButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Expect validations
      expect(find.text('Pet name is required for lost reports.'), findsOneWidget);
      expect(find.text('Pet color is required.'), findsOneWidget);
      expect(find.text('Please describe any distinguishing marks or features.'), findsOneWidget);
      expect(find.text('Description is required.'), findsOneWidget);
      expect(find.text('Location description is required.'), findsOneWidget);
    });

    testWidgets('Found report does not require pet name and accepts unknown characteristics', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateReportScreen(isLost: false),
          ),
        ),
      );

      expect(find.text('Report Found Animal'), findsOneWidget);
      // Pet Name should NOT be present on Found report
      expect(find.text('Pet Name *'), findsNothing);

      // Gender chips should include "Unknown"
      expect(find.text('Unknown'), findsOneWidget);
      await tester.tap(find.text('Unknown'));
      await tester.pumpAndSettle();

      // Tap submit to check remaining required fields
      final submitButton = find.byType(PrimaryButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Pet name is required for lost reports.'), findsNothing);
      expect(find.text('Pet color is required.'), findsOneWidget);
    });

    testWidgets('Validates negative reward amount', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CreateReportScreen(isLost: true),
          ),
        ),
      );

      // Enter negative reward
      final rewardFinder = find.widgetWithText(TextFormField, 'e.g. 100.00');
      expect(rewardFinder, findsOneWidget);
      await tester.ensureVisible(rewardFinder);
      await tester.enterText(rewardFinder, '-50');

      final submitButton = find.byType(PrimaryButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Reward must be a positive number.'), findsOneWidget);
    });
  });
}
