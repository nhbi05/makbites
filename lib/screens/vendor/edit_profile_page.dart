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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTextField("Restaurant Name", nameController),
            _buildTextField("Description", descriptionController),
            _buildTextField("Cuisine Type", cuisineController),
            _buildTextField("Phone Number", phoneController),
            _buildTextField("Email", emailController),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                      setState(() => isLoading = true);

                      await Future.delayed(Duration(seconds: 1)); // Simulate saving

                      widget.onSave(
                        name: nameController.text,
                        description: descriptionController.text,
                        cuisine: cuisineController.text,
                        phone: phoneController.text,
                        email: emailController.text,
                      );

                      setState(() => isLoading = false);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: isLoading
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text("Save changes", style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Cancel"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
