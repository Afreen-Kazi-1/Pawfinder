import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawfinder/features/reports/widgets/multi_image_picker_widget.dart';

void main() {
  group('MultiImagePickerWidget Tests', () {
    testWidgets('Renders empty add photo button and counter', (WidgetTester tester) async {
      List<XFile> images = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiImagePickerWidget(
              images: images,
              onImagesChanged: (updated) => images = updated,
              maxImages: 5,
            ),
          ),
        ),
      );

      expect(find.text('Pet Photos'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);
      expect(find.text('Add Photo'), findsOneWidget);
    });

    testWidgets('Renders image thumbnail preview and removes on delete tap', (WidgetTester tester) async {
      // Mock 100-byte fake image file
      final mockBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final mockImage = XFile.fromData(mockBytes, name: 'dog.jpg');
      List<XFile> images = [mockImage];

      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return MultiImagePickerWidget(
                  images: images,
                  onImagesChanged: (updated) {
                    setState(() {
                      images = updated;
                      removed = true;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify counter
      expect(find.text('1/5'), findsOneWidget);

      // Verify close/remove icon button is present
      final closeIcon = find.byIcon(Icons.close);
      expect(closeIcon, findsOneWidget);

      // Tap close icon
      await tester.tap(closeIcon);
      await tester.pumpAndSettle();

      expect(removed, isTrue);
      expect(images.isEmpty, isTrue);
      expect(find.text('0/5'), findsOneWidget);
    });
  });
}

