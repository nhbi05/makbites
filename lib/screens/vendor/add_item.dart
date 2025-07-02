import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class AddMenuItemForm extends StatefulWidget {
  const AddMenuItemForm({super.key});

  @override
  State<AddMenuItemForm> createState() => _AddMenuItemFormState();
}

class _AddMenuItemFormState extends State<AddMenuItemForm> {
  String? selectedCategory;
  String? selectedAvailability = "Available";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Add New Menu Item", style: AppTextStyles.subHeader),
            const SizedBox(height: 20),

            // Item Name
            Text("Item Name", style: AppTextStyles.body),
            const SizedBox(height: 4),
            TextField(
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: "e.g., Margherita Pizza",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Price
            Text("Price (UGX)", style: AppTextStyles.body),
            const SizedBox(height: 4),
            TextField(
              style: AppTextStyles.body,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Category
            Text("Category", style: AppTextStyles.body),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              style: AppTextStyles.body,
              value: selectedCategory,
              items: ['food', 'drink'].map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category[0].toUpperCase() + category.substring(1),
                    style: AppTextStyles.body,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Availability
            Text("Availability", style: AppTextStyles.body),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              style: AppTextStyles.body,
              value: selectedAvailability,
              items: ['Available', 'Unavailable'].map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status, style: AppTextStyles.body),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAvailability = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Upload Image Button
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement image picker
              },
              icon: const Icon(Icons.image),
              label: Text("Upload Image", style: AppTextStyles.button),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel", style: AppTextStyles.body),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Save logic
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: Text("Add Item", style: AppTextStyles.button),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
