import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme.dart';

class PawFinderApp extends StatelessWidget {
  const PawFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawFinder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

