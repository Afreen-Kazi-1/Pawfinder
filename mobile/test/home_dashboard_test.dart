import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/features/authentication/data/auth_repository.dart';
import 'package:pawfinder/features/authentication/models/user_model.dart';
import 'package:pawfinder/features/authentication/providers/auth_provider.dart';
import 'package:pawfinder/features/discovery/data/discovery_repository.dart';
import 'package:pawfinder/features/discovery/providers/discovery_provider.dart';
import 'package:pawfinder/features/home/screens/home_dashboard_view.dart';
import 'package:pawfinder/features/matches/data/match_repository.dart';
import 'package:pawfinder/features/matches/models/match_model.dart';
import 'package:pawfinder/features/matches/providers/match_provider.dart';
import 'package:pawfinder/features/reports/models/pet_report_model.dart';

class MockDashboardAuthRepo implements AuthRepository {
  final UserModel _user = UserModel(
    id: 'user-id-1',
    name: 'Sarah Connor',
    email: 'sarah@example.com',
    role: 'user',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  Future<UserModel> login({required String email, required String password}) async => _user;
  @override
  Future<UserModel> register({required String name, required String email, required String password}) async => _user;
  @override
  Future<UserModel> getCurrentUser() async => _user;
  @override
  Future<UserModel> updateProfile({String? name, String? phone, String? profileImageUrl}) async => _user;
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
  @override
  Future<void> logout() async {}
  @override
  Future<bool> isAuthenticated() async => true;
}

class MockDashboardDiscoveryRepo implements DiscoveryRepository {
  List<PetReportModel> returnReports = [];

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
    return DiscoveryResult(items: returnReports, total: returnReports.length, page: 1, size: 20);
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

class MockDashboardMatchRepo implements MatchRepository {
  @override
  Future<List<MatchModel>> getMyMatches({String? status, int page = 1, int size = 20}) async => [];
  @override
  Future<MatchModel> getMatchDetail(String id) async => throw UnimplementedError();
  @override
  Future<MatchModel> updateMatchStatus(String id, String newStatus) async => throw UnimplementedError();
}

void main() {
  group('HomeDashboardView Widget Tests', () {
    late MockDashboardAuthRepo mockAuth;
    late MockDashboardDiscoveryRepo mockDisc;
    late MockDashboardMatchRepo mockMatch;

    final dummyPet = PetReportModel(
      id: 'dash-pet-1',
      userId: 'user-id-1',
      reportType: 'LOST',
      petName: 'Barnaby',
      animalType: 'Dog',
      breed: 'Golden Doodle',
      color: 'Golden',
      latitude: 37.77,
      longitude: -122.41,
      locationLabel: 'Mission Dolores',
      eventDatetime: DateTime.parse('2026-11-12T10:00:00Z'),
      status: 'Open',
      createdAt: DateTime.parse('2026-11-12T10:00:00Z'),
      updatedAt: DateTime.parse('2026-11-12T10:00:00Z'),
      distinguishingFeatures: 'Red collar',
      description: 'Friendly golden doodle',
    );

    setUp(() {
      mockAuth = MockDashboardAuthRepo();
      mockDisc = MockDashboardDiscoveryRepo();
      mockMatch = MockDashboardMatchRepo();
    });

    testWidgets('Renders personalized greeting and quick report actions', (tester) async {
      mockDisc.returnReports = [dummyPet];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            discoveryRepositoryProvider.overrideWithValue(mockDisc),
            matchRepositoryProvider.overrideWithValue(mockMatch),
          ],
          child: MaterialApp(
            home: HomeDashboardView(
              onReportLost: () {},
              onReportFound: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PawFinder'), findsOneWidget);
      expect(find.text('Report Lost Pet'), findsOneWidget);
      expect(find.text('Report Found Pet'), findsOneWidget);
      expect(find.text('Recently Lost Pets'), findsOneWidget);
      expect(find.text('Recently Found Pets'), findsOneWidget);
      expect(find.text('Barnaby'), findsOneWidget);
    });
  });
}

