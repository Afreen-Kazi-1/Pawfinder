import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Support custom base URL via compile-time definition (--dart-define=API_BASE_URL=...)
  static const String _customBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    // Android emulator loops back to host machine on 10.0.2.2
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000/api';
      }
    } catch (_) {
      // Fallback if Platform check fails in unit tests
    }
    return 'http://127.0.0.1:8000/api';
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Reports & Discovery endpoints
  static const String reports = '/reports';
  static const String myReports = '/reports/mine';
  static const String discovery = '/discovery';
  static const String discoveryNearby = '/discovery/nearby';
  static const String discoveryMap = '/discovery/map';

  // Matches endpoints
  static const String matches = '/matches';

  // Contact & Notifications endpoints
  static const String contactRequests = '/contact-requests';
  static const String notifications = '/notifications';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}

