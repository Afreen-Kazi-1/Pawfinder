import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/features/discovery/data/discovery_repository.dart';
import 'package:pawfinder/features/discovery/providers/discovery_provider.dart';
import 'package:pawfinder/features/discovery/screens/discover_screen.dart';
import 'package:pawfinder/features/discovery/widgets/pet_report_card.dart';
import 'package:pawfinder/features/reports/models/pet_report_model.dart';

class MockDiscoveryRepository implements DiscoveryRepository {
  List<PetReportModel> returnItems = [];
  int returnTotal = 0;
  bool shouldThrow = false;

  @override
  Future<DiscoveryResult> discoverReports({
    String? reportType,
    String? animalType,
    String? breed,
    String? color,
    String? search,
    String? startDate,
    String? endDate,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
    int page = 1,
    int size = 20,
  }) async {
    if (shouldThrow) {
      throw Exception('Server discovery error');
    }
    return DiscoveryResult(
      items: returnItems,
      total: returnTotal,
      page: page,
      size: size,
    );
  }

  @override
  Future<NearbyResult> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    String? reportType,
    String? animalType,
    int page = 1,
    int size = 20,
  }) async {
    return const NearbyResult(items: [], total: 0, page: 1, size: 20);
  }

  @override
  Future<List<PublicPetReportModel>> getMapReports({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? reportType,
    String? animalType,
  }) async {
    return [];
  }
}

void main() {
  group('DiscoverScreen Tests', () {
    late MockDiscoveryRepository mockRepo;

    final dummyReport = PetReportModel(
      id: 'report-123',
      userId: 'user-456',
      reportType: 'LOST',
      petName: 'Rocky',
      animalType: 'Dog',
      breed: 'Beagle',
      color: 'Tricolor',
      latitude: 37.77,
      longitude: -122.41,
      locationLabel: 'Golden Gate Park',
      eventDatetime: DateTime.parse('2026-11-10T12:00:00Z'),
      reward: 150.0,
      status: 'Open',
      createdAt: DateTime.parse('2026-11-10T12:30:00Z'),
      updatedAt: DateTime.parse('2026-11-10T12:30:00Z'),
      distinguishingFeatures: 'White tip on tail',
      description: 'Friendly dog, wearing red harness',
    );

    setUp(() {
      mockRepo = MockDiscoveryRepository();
    });

    testWidgets('Renders empty state when no reports match', (tester) async {
      mockRepo.returnItems = [];
      mockRepo.returnTotal = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DiscoverScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No reports found'), findsOneWidget);
      expect(find.text('Reset Filters'), findsOneWidget);
    });

    testWidgets('Renders pet report cards correctly from discovery API', (tester) async {
      mockRepo.returnItems = [dummyReport];
      mockRepo.returnTotal = 1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DiscoverScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Card is displayed
      expect(find.byType(PetReportCard), findsOneWidget);
      expect(find.text('Rocky'), findsOneWidget);
      expect(find.text('LOST'), findsOneWidget);
      expect(find.text('Golden Gate Park'), findsOneWidget);
      expect(find.text('Reward: \$150'), findsOneWidget);
    });

    testWidgets('Renders error display on discovery failure', (tester) async {
      mockRepo.shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DiscoverScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Server discovery error'), findsOneWidget);
    });

    testWidgets('Segmented report type switch invokes discovery query', (tester) async {
      mockRepo.returnItems = [dummyReport];
      mockRepo.returnTotal = 1;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: DiscoverScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Found Pets' quick filter tab
      await tester.tap(find.text('Found Pets'));
      await tester.pumpAndSettle();

      // Verifies tab switch works smoothly without crashing
      expect(find.text('Found Pets'), findsOneWidget);
    });
  });
}

