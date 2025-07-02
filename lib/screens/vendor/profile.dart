import 'package:flutter/material.dart';
import 'edit_profile_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Initial profile values
  String restaurantName = "Mak Bites";
  String cuisineType = "Local foods, only";
  String description = "Dealers in delicious local food....";
  String phoneNumber = "07767676777";
  String email = "makbites@gmail.com";

  // Simulate editing (later, you'll connect this to an Edit Profile screen)
  void updateProfile({
    String? newRestaurantName,
    String? newCuisineType,
    String? newDescription,
    String? newPhone,
    String? newEmail,
  }) {
    setState(() {
      if (newRestaurantName != null) restaurantName = newRestaurantName;
      if (newCuisineType != null) cuisineType = newCuisineType;
      if (newDescription != null) description = newDescription;
      if (newPhone != null) phoneNumber = newPhone;
      if (newEmail != null) email = newEmail;
    });
  }
