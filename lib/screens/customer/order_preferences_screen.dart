import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import '../../services/automation_service.dart';

class OrderPreferencesScreen extends StatefulWidget {
  @override
  _OrderPreferencesScreenState createState() => _OrderPreferencesScreenState();
}

class _OrderPreferencesScreenState extends State<OrderPreferencesScreen> {
  String? selectedMeal;
  String? selectedRestaurant;
  String? deliveryLocation;
  bool _isLoading = false;

  final List<String> mealOptions = ['Breakfast', 'Lunch', 'Supper'];
  final List<String> restaurantOptions = [
    'Campus Grill',
    'Healthy Bites',
    'Pizza Corner',
    'Mama\'s Kitchen',
    'Quick Eats',
  ];

  final _formKey = GlobalKey<FormState>();
  final AutomationService _automationService = AutomationService();

  void _savePreferences() async {
    if (_formKey.currentState!.validate() && selectedMeal != null && selectedRestaurant != null) {
      setState(() { _isLoading = true; });
      await _automationService.scheduleSimpleSmartOrderForUser(
        userId: 'current_user_id',
        preferredMeal: selectedMeal!,
        preferredRestaurant: selectedRestaurant!,
        deliveryLocation: deliveryLocation ?? '',
      );
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preferences saved! Automation will schedule your orders.')),
      );
      Future.delayed(Duration(seconds: 1), () {
        Navigator.pushNamedAndRemoveUntil(context, '/customer-home', (route) => false);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select all options.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Preferences'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Select your preferred meal:', style: AppTextStyles.subHeader),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedMeal,
                items: mealOptions.map((meal) => DropdownMenuItem(
                  value: meal,
                  child: Text(meal),
                )).toList(),
                onChanged: (val) => setState(() => selectedMeal = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Meal',
                ),
                validator: (val) => val == null ? 'Select a meal' : null,
              ),
              SizedBox(height: 24),
              Text('Select your preferred restaurant:', style: AppTextStyles.subHeader),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedRestaurant,
                items: restaurantOptions.map((rest) => DropdownMenuItem(
                  value: rest,
                  child: Text(rest),
                )).toList(),
                onChanged: (val) => setState(() => selectedRestaurant = val),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Restaurant',
                ),
                validator: (val) => val == null ? 'Select a restaurant' : null,
              ),
              SizedBox(height: 24),
              Text('Enter delivery location:', style: AppTextStyles.subHeader),
              SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Delivery Location',
                ),
                onChanged: (val) => deliveryLocation = val,
                validator: (val) => val == null || val.isEmpty ? 'Enter a location' : null,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _savePreferences,
                child: Text('Save Preferences'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 