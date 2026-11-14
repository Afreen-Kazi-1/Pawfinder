import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/features/matches/data/match_repository.dart';
import 'package:pawfinder/features/matches/models/match_model.dart';
import 'package:pawfinder/features/matches/providers/match_provider.dart';
import 'package:pawfinder/features/matches/screens/matches_screen.dart';
import 'package:pawfinder/features/matches/widgets/match_card.dart';
import 'package:pawfinder/features/reports/models/pet_report_model.dart';

class MockMatchRepository implements MatchRepository {
  List<MatchModel> returnMatches = [];
  bool statusUpdated = false;

  @override
  Future<List<MatchModel>> getMyMatches({String? status, int page = 1, int size = 20}) async {
    return returnMatches;
  }

  @override
  Future<MatchModel> getMatchDetail(String id) async {
    return returnMatches.firstWhere((m) => m.id == id);
  }

  @override
  Future<MatchModel> updateMatchStatus(String id, String newStatus) async {
    statusUpdated = true;
    final match = returnMatches.firstWhere((m) => m.id == id);
    return match.copyWith(status: newStatus);
  }
}

void main() {
  group('MatchesScreen & Match Management Tests', () {
    late MockMatchRepository mockRepo;

    final dummyLost = PetReportModel(
      id: 'lost-1',
      userId: 'user-1',
      reportType: 'LOST',
      petName: 'Rusty',
      animalType: 'Dog',
      breed: 'Golden Retriever',
      color: 'Golden',
      latitude: 37.77,
      longitude: -122.41,
      locationLabel: 'Golden Gate Park',
      eventDatetime: DateTime.parse('2026-11-10T10:00:00Z'),
      reward: 100.0,
      status: 'Open',
      createdAt: DateTime.parse('2026-11-10T10:00:00Z'),
      updatedAt: DateTime.parse('2026-11-10T10:00:00Z'),
      distinguishingFeatures: 'Blue collar',
      description: 'Lost friendly dog',
    );

    final dummyFound = PetReportModel(
      id: 'found-1',
      userId: 'user-2',
      reportType: 'FOUND',
      animalType: 'Dog',
      breed: 'Golden Retriever',
      color: 'Golden',
      latitude: 37.775,
      longitude: -122.415,
      locationLabel: 'Near Golden Gate Park',
      eventDatetime: DateTime.parse('2026-11-10T12:00:00Z'),
      status: 'Open',
      createdAt: DateTime.parse('2026-11-10T12:00:00Z'),
      updatedAt: DateTime.parse('2026-11-10T12:00:00Z'),
      distinguishingFeatures: 'Blue collar with tag',
      description: 'Found wandering retriever',
    );

    final dummyMatch = MatchModel(
      id: 'match-1',
      lostReportId: 'lost-1',
      foundReportId: 'found-1',
      matchScore: 94.0,
      matchCategory: 'High potential match',
      matchReasons: {
        'animal_type': {'score': 100.0, 'explanation': 'Exact match: Dog.'},
        'breed': {'score': 100.0, 'explanation': 'Exact breed: Golden Retriever.'},
      },
      status: 'Suggested',
      createdAt: DateTime.parse('2026-11-10T13:00:00Z'),
      updatedAt: DateTime.parse('2026-11-10T13:00:00Z'),
      lostReport: dummyLost,
      foundReport: dummyFound,
    );

    setUp(() {
      mockRepo = MockMatchRepository();
    });

    testWidgets('Renders empty state when user has no matches', (tester) async {
      mockRepo.returnMatches = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MatchesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No matches found'), findsOneWidget);
    });

    testWidgets('Renders match card with score indicator and report summaries', (tester) async {
      mockRepo.returnMatches = [dummyMatch];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MatchesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(MatchCard), findsOneWidget);
      expect(find.text('94% MATCH'), findsOneWidget);
      expect(find.text('Rusty'), findsOneWidget);
      expect(find.text('Mark Relevant'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('Tapping Mark Relevant updates match state', (tester) async {
      mockRepo.returnMatches = [dummyMatch];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            matchRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            home: MatchesScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark Relevant'));
      await tester.pumpAndSettle();

      expect(mockRepo.statusUpdated, isTrue);
    });
  });
}

