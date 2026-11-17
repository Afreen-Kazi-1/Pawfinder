import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../app/routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Allow splash animation to show briefly then evaluate auth
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to state changes if auth status finishes checking after delay
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status != AuthStatus.initial && next.status != AuthStatus.loading) {
        if (next.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 72,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PawFinder',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lost & Found Pet Discovery',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

