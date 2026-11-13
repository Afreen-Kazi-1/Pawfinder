import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/core/widgets/password_text_field.dart';

void main() {
  group('PasswordTextField Tests', () {
    testWidgets('Toggles password visibility on icon tap', (WidgetTester tester) async {
      final controller = TextEditingController(text: 'secretPassword123');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PasswordTextField(
              controller: controller,
              label: 'Password',
              hint: 'Enter password',
            ),
          ),
        ),
      );

      // Verify label is displayed
      expect(find.text('Password'), findsOneWidget);

      // Verify initially obscured
      final initialEditableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(initialEditableText.obscureText, isTrue);

      // Find visibility icon button and tap it
      final visibilityButton = find.byType(IconButton);
      expect(visibilityButton, findsOneWidget);
      await tester.tap(visibilityButton);
      await tester.pump();

      // Verify text is now unobscured
      final updatedEditableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(updatedEditableText.obscureText, isFalse);

      // Tap again to obscure
      await tester.tap(visibilityButton);
      await tester.pump();

      final reobscuredEditableText = tester.widget<EditableText>(find.byType(EditableText));
      expect(reobscuredEditableText.obscureText, isTrue);
    });
  });
}

