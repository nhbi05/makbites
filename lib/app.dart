import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'services/location_service.dart'; // Import LocationService

class MakBitesApp extends StatelessWidget {
  const MakBitesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocationService(), // Provide LocationService
      child: MaterialApp(
        title: 'MakBites',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        onUnknownRoute: AppRoutes.onUnknownRoute,
      ),
    );
  }
}

