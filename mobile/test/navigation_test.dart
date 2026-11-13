import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/app/routes.dart';
import 'package:pawfinder/features/authentication/data/auth_repository.dart';
import 'package:pawfinder/features/authentication/models/user_model.dart';
import 'package:pawfinder/features/authentication/providers/auth_provider.dart';
import 'package:pawfinder/features/authentication/screens/login_screen.dart';

class MockNavigationAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login({required String email, required String password}) async {
    return UserModel(
      id: 'test-user-id',
      name: 'Test Navigator',
      email: email,
      role: 'user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel> register({required String name, required String email, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    throw UnimplementedError();
  }

  @override
  Future<UserModel> updateProfile({String? name, String? phone, String? profileImageUrl}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;
}

void main() {
  group('Navigation Tests', () {
    testWidgets('Navigates to home route after successful login', (WidgetTester tester) async {
      final mockRepo = MockNavigationAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            initialRoute: AppRoutes.login,
            routes: {
              AppRoutes.login: (context) => const LoginScreen(),
              AppRoutes.home: (context) => const Scaffold(
                    body: Center(child: Text('Home Screen Target')),
                  ),
            },
          ),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);

      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, 'user@example.com');
      await tester.enterText(textFields.last, 'Secret123');

      final signInButton = find.text('Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Verify that we navigated to the Home screen
      expect(find.text('Home Screen Target'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}

