import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/app/theme.dart';
import 'package:pawfinder/core/constants/colors.dart';

void main() {
  group('AppTheme Tests', () {
    test('lightTheme initializes with correct brand colors and styles', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.colorScheme.error, AppColors.error);
      expect(theme.colorScheme.surface, AppColors.surface);
    });

    test('lightTheme has customized button, card, and app bar themes', () {
      final theme = AppTheme.lightTheme;

      expect(theme.appBarTheme.backgroundColor, AppColors.background);
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.cardTheme.color, AppColors.surface);
      expect(theme.elevatedButtonTheme.style, isNotNull);
      expect(theme.outlinedButtonTheme.style, isNotNull);
      expect(theme.inputDecorationTheme.filled, isTrue);
    });
  });
}
