import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/core/widgets/primary_button.dart';
import 'package:pawfinder/features/authentication/screens/register_screen.dart';

void main() {
  group('Register Form Validation Tests', () {
    testWidgets('Validates empty fields on submission', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      final primaryButton = find.byType(PrimaryButton);
      expect(primaryButton, findsOneWidget);
      await tester.ensureVisible(primaryButton);
      await tester.tap(primaryButton);
      await tester.pumpAndSettle();

      expect(find.text('Name must be at least 2 characters.'), findsOneWidget);
      expect(find.text('Email address is required.'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters.'), findsOneWidget);
    });

    testWidgets('Validates password policy (missing number)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      // Name, Email, Password, Confirm Password
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'john@example.com');
      await tester.enterText(fields.at(2), 'passwordonly');
      await tester.enterText(fields.at(3), 'passwordonly');

      final primaryButton = find.byType(PrimaryButton);
      await tester.ensureVisible(primaryButton);
      await tester.tap(primaryButton);
      await tester.pumpAndSettle();

      expect(find.text('Password must contain at least one number.'), findsOneWidget);
    });

    testWidgets('Validates password mismatch', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'john@example.com');
      await tester.enterText(fields.at(2), 'Password123');
      await tester.enterText(fields.at(3), 'DifferentPassword456');

      final primaryButton = find.byType(PrimaryButton);
      await tester.ensureVisible(primaryButton);
      await tester.tap(primaryButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });
}
