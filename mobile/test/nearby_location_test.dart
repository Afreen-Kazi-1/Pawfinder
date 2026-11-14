import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/features/discovery/data/discovery_repository.dart';
import 'package:pawfinder/features/discovery/providers/discovery_provider.dart';
import 'package:pawfinder/features/discovery/screens/nearby_map_screen.dart';

class MockNearbyRepository implements DiscoveryRepository {
  List<PublicPetReportModel> returnNearby = [];

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
    return const DiscoveryResult(items: [], total: 0, page: 1, size: 20);
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
    return NearbyResult(
      items: returnNearby,
      total: returnNearby.length,
      page: 1,
      size: 20,
    );
  }

  @override
  Future<List<PublicPetReportModel>> getMapReports({
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? reportType,
    String? animalType,
  }) async {
    return returnNearby;
  }
}

void main() {
  group('NearbyMapScreen Location Tests', () {
    late MockNearbyRepository mockRepo;

    final dummyNearby = PublicPetReportModel(
      id: 'nearby-1',
      userId: 'user-nearby',
      reportType: 'FOUND',
      petName: 'Milo',
      animalType: 'Cat',
      breed: 'Tabby',
      color: 'Orange',
      approxLatitude: 37.775,
      approxLongitude: -122.419,
      locationLabel: 'Mission District',
      eventDatetime: DateTime.parse('2026-11-12T08:00:00Z'),
      status: 'Open',
      createdAt: DateTime.parse('2026-11-12T08:00:00Z'),
      updatedAt: DateTime.parse('2026-11-12T08:00:00Z'),
      distinguishingFeatures: 'White paws',
      description: 'Found wandering near corner cafe',
      distanceKm: 1.25,
    );

    setUp(() {
      mockRepo = MockNearbyRepository();
    });

    testWidgets('Renders nearby reports with approximate coordinates and distance badge', (tester) async {
      mockRepo.returnNearby = [dummyNearby];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NearbyMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nearby Pet Reports'), findsOneWidget);
      expect(find.text('Milo'), findsOneWidget);
      expect(find.text('1.3 km away'), findsOneWidget);
      expect(find.textContaining('Approx. area: 37.78, -122.42'), findsOneWidget);
    });

    testWidgets('Allows selecting different search radii', (tester) async {
      mockRepo.returnNearby = [dummyNearby];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NearbyMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('25 km'), findsOneWidget);
      await tester.tap(find.text('25 km'));
      await tester.pumpAndSettle();
    });

    testWidgets('Opens manual location fallback dialog', (tester) async {
      mockRepo.returnNearby = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: NearbyMapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap manual location action button in AppBar
      await tester.tap(find.byIcon(Icons.edit_location_alt_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Enter Location Manually'), findsOneWidget);
      expect(find.text('Set Location'), findsOneWidget);
    });
  });
}

