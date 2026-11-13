import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawfinder/core/widgets/primary_button.dart';
import 'package:pawfinder/features/reports/data/report_repository.dart';
import 'package:pawfinder/features/reports/models/pet_image_model.dart';
import 'package:pawfinder/features/reports/models/pet_report_model.dart';
import 'package:pawfinder/features/reports/providers/report_provider.dart';
import 'package:pawfinder/features/reports/screens/create_report_screen.dart';

class MockReportRepository implements ReportRepository {
  bool shouldThrow = false;
  String errorMessage = 'Failed to submit report';

  @override
  Future<PetReportModel> createReport({
    required Map<String, dynamic> reportData,
    List<XFile>? images,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);

    return PetReportModel(
      id: 'mock-report-id',
      userId: 'mock-user-id',
      reportType: reportData['report_type'] as String,
      petName: reportData['pet_name'] as String?,
      animalType: reportData['animal_type'] as String,
      color: reportData['color'] as String,
      distinguishingFeatures: reportData['distinguishing_features'] as String? ?? '',
      description: reportData['description'] as String? ?? '',
      latitude: (reportData['latitude'] as num).toDouble(),
      longitude: (reportData['longitude'] as num).toDouble(),
      locationLabel: reportData['location_label'] as String,
      eventDatetime: DateTime.now(),
      status: 'Open',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<PetReportModel> getReport(String id) async => throw UnimplementedError();

  @override
  Future<List<PetReportModel>> getMyReports({int page = 1, int size = 50}) async => [];

  @override
  Future<PetReportModel> updateReport({required String id, required Map<String, dynamic> updateData}) async =>
      throw UnimplementedError();

  @override
  Future<PetReportModel> updateStatus({required String id, required String newStatus}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteReport(String id) async {}

  @override
  Future<List<PetImageModel>> uploadImages({required String reportId, required List<XFile> images}) async => [];

  @override
  Future<void> deleteImage(String imageId) async {}
}

void main() {
  group('Report Submission Tests', () {
    testWidgets('Submits report successfully and shows confirmation dialog', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockReportRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CreateReportScreen(isLost: true),
          ),
        ),
      );

      // Fill in required fields
      final textFields = find.byType(TextFormField);
      // Pet Name
      await tester.enterText(textFields.at(0), 'Charlie');
      // Breed
      await tester.enterText(textFields.at(1), 'Beagle');
      // Color
      await tester.enterText(textFields.at(2), 'Tri-color');
      // Approx Age
      await tester.enterText(textFields.at(3), '4 years');
      // Features
      await tester.enterText(textFields.at(4), 'White tip on tail');
      // Description
      await tester.enterText(textFields.at(5), 'Ran out during fireworks');
      // Reward
      await tester.enterText(textFields.at(6), '50.00');
      // Location Label
      await tester.enterText(textFields.at(7), 'Sunset District, SF');
      // Lat / Long
      await tester.enterText(textFields.at(8), '37.75');
      await tester.enterText(textFields.at(9), '-122.48');

      // Submit form
      final submitButton = find.byType(PrimaryButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify success dialog appears
      expect(find.text('Report Created'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Displays error feedback on submission failure', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockRepo = MockReportRepository();
      mockRepo.shouldThrow = true;
      mockRepo.errorMessage = 'Network connection dropped';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            reportRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: CreateReportScreen(isLost: false),
          ),
        ),
      );

      // Fill required fields for Found report
      final textFields = find.byType(TextFormField);
      // Breed (index 0 for Found report because no Pet Name)
      await tester.enterText(textFields.at(0), 'Husky');
      // Color
      await tester.enterText(textFields.at(1), 'Grey & White');
      // Age
      await tester.enterText(textFields.at(2), 'Young adult');
      // Features
      await tester.enterText(textFields.at(3), 'Blue eyes');
      // Description
      await tester.enterText(textFields.at(4), 'Found roaming in park');
      // Location Label
      await tester.enterText(textFields.at(5), 'Golden Gate Park');
      // Lat / Long
      await tester.enterText(textFields.at(6), '37.7690');
      await tester.enterText(textFields.at(7), '-122.4835');

      final submitButton = find.byType(PrimaryButton);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Expect ErrorDisplay with message
      expect(find.textContaining('Network connection dropped'), findsOneWidget);
      expect(find.text('Report Created'), findsNothing);
    });
  });
}

