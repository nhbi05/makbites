import 'package:flutter/material.dart';
import '../constants/app_colours.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Primary theme
      primarySwatch: _createMaterialColor(AppColors.primary),
      primaryColor: AppColors.primary,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.white,
        background: AppColors.white,
      ),
      
      // AppBar theme
      appBarTheme: _appBarTheme,
      
      // Button themes
      elevatedButtonTheme: _elevatedButtonTheme,
      textButtonTheme: _textButtonTheme,
      
      // Input decoration theme
      inputDecorationTheme: _inputDecorationTheme,
      
      // Card theme
      cardTheme: _cardTheme,
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      
      // Floating action button theme
      floatingActionButtonTheme: _floatingActionButtonTheme,
      
      // Scaffold background
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      
      // Visual density
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static MaterialColor _createMaterialColor(Color color) {
    return MaterialColor(
      color.value,
      <int, Color>{
        50: const Color(0xFFFFEBEE),
        100: const Color(0xFFFFCDD2),
        200: const Color(0xFFEF9A9A),
        300: const Color(0xFFE57373),
        400: const Color(0xFFEF5350),
        500: color,
        600: const Color(0xFFE53935),
        700: const Color(0xFFD32F2F),
        800: const Color(0xFFC62828),
        900: const Color(0xFFB71C1C),
      },
    );
  }

  static AppBarTheme get _appBarTheme {
    return AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        color: AppColors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
    );
  }

  static ElevatedButtonThemeData get _elevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Not const
        ),
        elevation: 2,
      ),
    );
  }

  static TextButtonThemeData get _textButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  static InputDecorationTheme get _inputDecorationTheme {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Not const
        borderSide: BorderSide(color: Colors.grey.shade300), // Not const
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Not const
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Not const
        borderSide: BorderSide(color: Colors.grey.shade300), // Not const
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Not const
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8), // Not const
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      fillColor: AppColors.white,
      filled: true,
    );
  }

  static CardThemeData get _cardTheme {
    return CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Not const
      ),
      color: AppColors.white,
    );
  }

  static BottomNavigationBarThemeData get _bottomNavigationBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
    );
  }

  static FloatingActionButtonThemeData get _floatingActionButtonTheme {
    return const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 4,
    );
  }
}