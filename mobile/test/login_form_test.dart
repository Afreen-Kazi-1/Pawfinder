import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/features/authentication/screens/login_screen.dart';

void main() {
  group('Login Form Validation Tests', () {
    testWidgets('Validates empty email and empty password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Tap Sign In button without entering any input
      final signInButton = find.text('Sign In');
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Expect validation error messages
      expect(find.text('Email address is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('Validates invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter invalid email
      final emailFields = find.byType(TextFormField);
      await tester.enterText(emailFields.first, 'invalid-email-address');
      await tester.enterText(emailFields.last, 'Password123');

      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid email address.'), findsOneWidget);
      expect(find.text('Password is required.'), findsNothing);
    });
  });
}

