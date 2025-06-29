import 'package:flutter/material.dart';
import '../constants/app_colours.dart';
import '../constants/text_styles.dart';

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and Title
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  size: 60,
                  color: AppColors.white,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'MakBites',
                style: AppTextStyles.header.copyWith(
                  fontSize: 32,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Delicious meals delivered\nto your campus',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Sign In Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Sign In',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}