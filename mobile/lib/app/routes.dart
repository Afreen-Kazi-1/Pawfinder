import 'package:flutter/material.dart';
import '../features/home/screens/splash_screen.dart';
import '../features/home/screens/onboarding_screen.dart';
import '../features/authentication/screens/login_screen.dart';
import '../features/authentication/screens/register_screen.dart';
import '../features/home/screens/main_shell_screen.dart';
import '../features/reports/screens/create_report_screen.dart';
import '../features/reports/screens/my_reports_screen.dart';
import '../features/discovery/screens/nearby_map_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/contact_requests/screens/contact_requests_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/moderation/screens/admin_moderation_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createLostReport = '/reports/create-lost';
  static const String createFoundReport = '/reports/create-found';
  static const String myReports = '/reports/mine';
  static const String nearbyMap = '/discovery/nearby-map';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String contactRequests = '/contact-requests';
  static const String notifications = '/notifications';
  static const String adminModeration = '/admin/moderation';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainShellScreen(),
          settings: settings,
        );
      case createLostReport:
        return MaterialPageRoute(
          builder: (_) => const CreateReportScreen(isLost: true),
          settings: settings,
        );
      case createFoundReport:
        return MaterialPageRoute(
          builder: (_) => const CreateReportScreen(isLost: false),
          settings: settings,
        );
      case myReports:
        return MaterialPageRoute(
          builder: (_) => const MyReportsScreen(),
          settings: settings,
        );
      case nearbyMap:
        return MaterialPageRoute(
          builder: (_) => const NearbyMapScreen(),
          settings: settings,
        );
      case editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
          settings: settings,
        );
      case contactRequests:
        return MaterialPageRoute(
          builder: (_) => const ContactRequestsScreen(),
          settings: settings,
        );
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationsScreen(),
          settings: settings,
        );
      case adminModeration:
        return MaterialPageRoute(
          builder: (_) => const AdminModerationScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}
