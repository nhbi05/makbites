// menu_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'add_item.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String restaurantId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddMenuItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AddMenuItemForm(restaurantId: restaurantId),
    );
  }

  Future<void> _toggleItemStatus(String docId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'Available' ? 'Unavailable' : 'Available';
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .collection('items')
          .doc(docId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item marked as $newStatus'),
          backgroundColor: newStatus == 'Available' ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _deleteItem(String docId, String itemName) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$itemName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantId)
            .collection('items')
            .doc(docId)
            .delete();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: AppColors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Foods'),
                    Tab(text: 'Drinks'),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurantId)
                      .collection('items')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Your menu is empty',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add items to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    final items = snapshot.data!.docs;
                    final foodItems = items
                        .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'food')
                        .toList();
                    final drinkItems = items
                        .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'drink')
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMenuList(foodItems),
                        _buildMenuList(drinkItems),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _showAddMenuItemDialog,
              backgroundColor: AppColors.primary,
              label: Text('Add Item', style: TextStyle(color: AppColors.white)),
              icon: Icon(Icons.add, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(List<QueryDocumentSnapshot> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No items in this category',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) {
          final doc = items[index];
          final item = doc.data() as Map<String, dynamic>;
          return _menuItem(item, doc.id);
        },
      ),
    );
  }

  Widget _menuItem(Map<String, dynamic> item, String docId) {
    print('Debug - Item: ${item['name']}, ImageURL: ${item['imageUrl']}');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(item['imageUrl']),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Unknown Item',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item['description'] != null && item['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        item['description'],
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    "UGX ${item['price']?.toStringAsFixed(0) ?? '0'}",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),
                  // ✅ Status Badge Added Here:
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (item['status'] == 'Available'
                          ? Colors.green
                          : Colors.grey)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      item['status'] ?? 'Unknown',
                      style: TextStyle(
                        color: item['status'] == 'Available'
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => _toggleItemStatus(docId, item['status']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.black,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: Text(
                      item['status'] == 'Available'
                          ? "Mark Unavailable"
                          : "Mark Available",
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: () => _deleteItem(docId, item['name']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(dynamic imageUrl) {
    if (imageUrl == null) {
      print('Warning: Image URL is null');
      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
    }

    final urlString = imageUrl.toString().trim();
    if (urlString.isEmpty) {
      print('Warning: Image URL is empty');
      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
    }

    final isValid = Uri.tryParse(urlString)?.hasAbsolutePath == true && urlString.startsWith('http');
    if (!isValid) {
      print('Warning: Invalid image URL: $urlString');
      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
    }

    print('✅ Attempting to load image: $urlString');

    return CachedNetworkImage(
      imageUrl: urlString,
      fit: BoxFit.cover,
      placeholder: (context, url) =>
      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (context, url, error) {
        print('❌ Error loading image from $url : $error');
        return const Icon(Icons.broken_image, size: 40, color: Colors.red);
      },
    );
  }
}