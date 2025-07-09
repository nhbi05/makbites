import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'edit_profile_page.dart';  // Make sure this path is correct

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String restaurantName = "...";
  String cuisineType = "...";
  String description = "...";
  String phoneNumber = "...";
  String email = "...";
  String location = "...";
  bool isOpen = true;
  String? profileImageUrl;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    setState(() {
      restaurantName = data['name'] ?? restaurantName;
      cuisineType = data['cuisine'] ?? cuisineType;
      description = data['description'] ?? description;
      phoneNumber = data['phone'] ?? phoneNumber;
      email = data['email'] ?? email;
      location = data['location'] ?? location;
      isOpen = data['isOpen'] ?? true;
      profileImageUrl = data['profileImage'];
    });
  }

  Future<void> _pickCropAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (cropped == null) return;

    setState(() => isUploading = true);

    final file = File(cropped.path);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance.ref('profile_images/$userId.jpg');
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(userId)
        .update({'profileImage': url});

    setState(() {
      profileImageUrl = url;
      isUploading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile image updated!')));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickCropAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickCropAndUpload(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges({
    required String name,
    required String description,
    required String cuisine,
    required String phone,
    required String email,
  }) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('restaurants').doc(userId).update({
      'name': name,
      'description': description,
      'cuisine': cuisine,
      'phone': phone,
      'email': email,
    });

    // Refresh local state
    setState(() {
      restaurantName = name;
      this.description = description;
      cuisineType = cuisine;
      phoneNumber = phone;
      this.email = email;
    });
  }

  Future<void> _toggleStatus(bool newStatus) async {
    setState(() {
      isOpen = newStatus;
    });

    final userId = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(userId)
        .update({'isOpen': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Restaurant Profile')),
      body: isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(Icons.restaurant, size: 50)
                        : null,
                  ),
                  Positioned(
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.orange),
                      onPressed: _showImageSourceSheet,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            _infoTile("Restaurant Name", restaurantName),
            _infoTile("Cuisine Type", cuisineType),
            _infoTile("Description", description),
            _infoTile("Phone Number", phoneNumber),
            _infoTile("Email", email),
            _infoTile("Location", location),

            // Status toggle widget
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Status",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Row(
                    children: [
                      Text(isOpen ? "Open" : "Closed",
                          style: const TextStyle(fontSize: 15)),
                      Switch(
                        value: isOpen,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.red,
                        onChanged: _toggleStatus,
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text("Edit Profile",
                    style: TextStyle(color: Colors.black, fontSize: 16)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        name: restaurantName,
                        description: description,
                        cuisine: cuisineType,
                        phone: phoneNumber,
                        email: email,
                        onSave: ({

                          required String name,
                          required String description,
                          required String cuisine,
                          required String phone,
                          required String email,
                        }) async {
                          await _saveProfileChanges(
                            name: name,
                            description: description,
                            cuisine: cuisine,
                            phone: phone,
                            email: email,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
