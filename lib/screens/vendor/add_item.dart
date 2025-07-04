// add_item.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class AddMenuItemForm extends StatefulWidget {
  final String restaurantId;

  const AddMenuItemForm({super.key, required this.restaurantId});

  @override
  State<AddMenuItemForm> createState() => _AddMenuItemFormState();
}

class _AddMenuItemFormState extends State<AddMenuItemForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? selectedCategory;
  String? selectedAvailability = 'Available';
  File? _selectedImage;
  Uint8List? _webImage;
  String? _selectedImageName;
  bool isLoading = false;

  Future<void> _pickImage() async {
    try {
      ImageSource? source;

      if (Theme.of(context).platform == TargetPlatform.iOS ||
          Theme.of(context).platform == TargetPlatform.android) {
        source = await showDialog<ImageSource>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      } else {
        source = ImageSource.gallery;
      }

      if (source != null) {
        final pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          if (kIsWeb) {
            _webImage = await pickedFile.readAsBytes();
            _selectedImageName = pickedFile.name;
            _selectedImage = null;
          } else {
            _selectedImage = File(pickedFile.path);
            _webImage = null;
            _selectedImageName = null;
          }

          setState(() {});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    try {
      final String fileName =
          'item_${DateTime.now().millisecondsSinceEpoch}_${widget.restaurantId}.jpg';
      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('restaurant_items/${widget.restaurantId}/$fileName');

      UploadTask uploadTask;

      if (kIsWeb && _webImage != null) {
        uploadTask = ref.putData(_webImage!);
      } else if (_selectedImage != null) {
        uploadTask = ref.putFile(_selectedImage!);
      } else {
        return null;
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Image uploaded! Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }

  Future<void> _addMenuItem() async {
    final String name = _nameController.text.trim();
    final String priceText = _priceController.text.trim();

    if (name.isEmpty ||
        priceText.isEmpty ||
        selectedCategory == null ||
        (_selectedImage == null && _webImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image')),
      );
      return;
    }

    final double? price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final String? imageUrl = await _uploadImage();
      if (imageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image upload failed. Please try again.')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('items')
          .add({
        'name': name,
        'price': price,
        'type': selectedCategory,
        'status': selectedAvailability,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

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
            Text("Item Name", style: AppTextStyles.body),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              style: AppTextStyles.body,
              decoration: const InputDecoration(
                hintText: "e.g., Margherita Pizza",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text("Price (UGX)", style: AppTextStyles.body),
            const SizedBox(height: 4),
            TextField(
              controller: _priceController,
              style: AppTextStyles.body,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "e.g., 25000",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text("Category", style: AppTextStyles.body),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              style: AppTextStyles.body,
              value: selectedCategory,
              hint: const Text("Select category"),
              items: ['food', 'drink'].map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(
                    category[0].toUpperCase() + category.substring(1),
                    style: AppTextStyles.body,
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedCategory = value),
            ),
            const SizedBox(height: 16),
            Text("Availability", style: AppTextStyles.body),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              style: AppTextStyles.body,
              value: selectedAvailability,
              items: ['Available', 'Unavailable'].map((String status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status, style: AppTextStyles.body),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedAvailability = value),
            ),
            const SizedBox(height: 16),
            Text("Item Image", style: AppTextStyles.body),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: (_selectedImage != null || _webImage != null)
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb && _webImage != null
                      ? Image.memory(_webImage!, fit: BoxFit.cover, width: double.infinity)
                      : _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity)
                      : const SizedBox(),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Tap to select image", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text("Cancel", style: AppTextStyles.body),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : _addMenuItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text("Add Item", style: AppTextStyles.button),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}