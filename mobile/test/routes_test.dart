import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/app/routes.dart';
import 'package:pawfinder/features/home/screens/splash_screen.dart';
import 'package:pawfinder/features/home/screens/onboarding_screen.dart';
import 'package:pawfinder/features/authentication/screens/login_screen.dart';
import 'package:pawfinder/features/authentication/screens/register_screen.dart';
import 'package:pawfinder/features/home/screens/main_shell_screen.dart';
import 'package:pawfinder/features/reports/screens/create_report_screen.dart';
import 'package:pawfinder/features/reports/screens/my_reports_screen.dart';

void main() {
  group('AppRoutes Tests', () {
    test('Route constants have correct paths', () {
      expect(AppRoutes.splash, '/');
      expect(AppRoutes.onboarding, '/onboarding');
      expect(AppRoutes.login, '/login');
      expect(AppRoutes.register, '/register');
      expect(AppRoutes.home, '/home');
      expect(AppRoutes.createLostReport, '/reports/create-lost');
      expect(AppRoutes.createFoundReport, '/reports/create-found');
      expect(AppRoutes.myReports, '/reports/mine');
    });

    test('onGenerateRoute resolves each route correctly', () {
      final splashRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.splash)) as MaterialPageRoute;
      expect(splashRoute.builder(MockBuildContext()), isA<SplashScreen>());

      final onboardingRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.onboarding)) as MaterialPageRoute;
      expect(onboardingRoute.builder(MockBuildContext()), isA<OnboardingScreen>());

      final loginRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.login)) as MaterialPageRoute;
      expect(loginRoute.builder(MockBuildContext()), isA<LoginScreen>());

      final registerRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.register)) as MaterialPageRoute;
      expect(registerRoute.builder(MockBuildContext()), isA<RegisterScreen>());

      final homeRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.home)) as MaterialPageRoute;
      expect(homeRoute.builder(MockBuildContext()), isA<MainShellScreen>());

      final createLostRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.createLostReport)) as MaterialPageRoute;
      expect(createLostRoute.builder(MockBuildContext()), isA<CreateReportScreen>());

      final createFoundRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.createFoundReport)) as MaterialPageRoute;
      expect(createFoundRoute.builder(MockBuildContext()), isA<CreateReportScreen>());

      final myReportsRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: AppRoutes.myReports)) as MaterialPageRoute;
      expect(myReportsRoute.builder(MockBuildContext()), isA<MyReportsScreen>());

      final unknownRoute = AppRoutes.onGenerateRoute(const RouteSettings(name: '/unknown_path')) as MaterialPageRoute;
      expect(unknownRoute.builder(MockBuildContext()), isA<Scaffold>());
    });
  });
}

class MockBuildContext extends Fake implements BuildContext {}
