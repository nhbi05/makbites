import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String name;
  final String description;
  final String cuisine;
  final String phone;
  final String email;
  final Function({
  required String name,
  required String description,
  required String cuisine,
  required String phone,
  required String email,
  }) onSave;

  const EditProfilePage({
    Key? key,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.phone,
    required this.email,
    required this.onSave,
  }) : super(key: key);
