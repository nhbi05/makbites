import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
class AnalyticsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analytics"),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Text("Analytics content goes here"),
      ),
    );
  }
}
