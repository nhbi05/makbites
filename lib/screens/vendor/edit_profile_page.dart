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
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController cuisineController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    descriptionController = TextEditingController(text: widget.description);
    cuisineController = TextEditingController(text: widget.cuisine);
    phoneController = TextEditingController(text: widget.phone);
    emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    cuisineController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }
