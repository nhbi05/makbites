import 'package:flutter/material.dart';

class RestaurantProfile with ChangeNotifier {
  String restaurantName;
  String cuisineType;
  String description;
  String phoneNumber;
  String email;

  RestaurantProfile({
    this.restaurantName = '',
    this.cuisineType = '',
    this.description = '',
    this.phoneNumber = '',
    this.email = '',
  });

  void updateProfile({
    String? restaurantName,
    String? cuisineType,
    String? description,
    String? phoneNumber,
    String? email,
  }) {
    if (restaurantName != null) this.restaurantName = restaurantName;
    if (cuisineType != null) this.cuisineType = cuisineType;
    if (description != null) this.description = description;
    if (phoneNumber != null) this.phoneNumber = phoneNumber;
    if (email != null) this.email = email;
    notifyListeners(); // Notify widgets to rebuild
  }
}
