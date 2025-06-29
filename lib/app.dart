import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'config/routes.dart';

class MakBitesApp extends StatelessWidget {
  const MakBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MakBites',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onUnknownRoute: AppRoutes.onUnknownRoute,
    );
  }
}