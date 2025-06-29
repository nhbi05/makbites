import 'package:flutter/material.dart';
import 'app_colours.dart';

class AppTextStyles {
  static const TextStyle header = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static const TextStyle subHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textDark,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static const TextStyle makBites = TextStyle(
    fontFamily: 'Creepster',
    fontSize: 40,
    color: Colors.white,
    letterSpacing: 2,
  );
}