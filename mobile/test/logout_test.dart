import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/app/routes.dart';
import 'package:pawfinder/features/authentication/data/auth_repository.dart';
import 'package:pawfinder/features/authentication/models/user_model.dart';
import 'package:pawfinder/features/authentication/providers/auth_provider.dart';
import 'package:pawfinder/features/profile/screens/profile_screen.dart';

class MockLogoutAuthRepository implements AuthRepository {
  bool logoutCalled = false;
  final UserModel _user = UserModel(
    id: 'test-user-id',
    name: 'Jane Doe',
    email: 'jane@example.com',
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
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<bool> isAuthenticated() async => true;
}

void main() {
  group('Logout Flow Tests', () {
    testWidgets('Triggers confirmation dialog and logs out on confirm', (WidgetTester tester) async {
      final mockRepo = MockLogoutAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            initialRoute: '/profile',
            routes: {
              '/profile': (context) => const ProfileScreen(),
              AppRoutes.login: (context) => const Scaffold(
                    body: Center(child: Text('Login Screen Target')),
                  ),
            },
          ),
        ),
      );

      // Allow initial checkAuthStatus microtask to complete and set authenticated user
      await tester.pumpAndSettle();

      // Profile shows user info
      expect(find.text('Jane Doe'), findsWidgets);
      expect(find.text('jane@example.com'), findsWidgets);

      // Tap Sign Out button
      final signOutButton = find.text('Sign Out');
      expect(signOutButton, findsWidgets);
      await tester.tap(signOutButton.first);
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog is shown
      expect(find.text('Are you sure you want to sign out of PawFinder?'), findsOneWidget);

      // Confirm sign out in dialog
      final confirmButton = find.widgetWithText(ElevatedButton, 'Sign Out').last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify logout was called and user navigated to Login screen
      expect(mockRepo.logoutCalled, isTrue);
      expect(find.text('Login Screen Target'), findsOneWidget);
    });
  });
}
