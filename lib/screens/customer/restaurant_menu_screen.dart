import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/cart_model.dart';

class RestaurantMenuScreen extends StatelessWidget {
  final String restaurantDocId;
  final String restaurantName;

  RestaurantMenuScreen({required this.restaurantDocId, required this.restaurantName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$restaurantName Menu')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .doc(restaurantDocId)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          final items = snapshot.data!.docs;
          if (items.isEmpty) return Center(child: Text('No menu items found.'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: item['imageUrl'] != null && item['imageUrl'] != ''
                      ? Image.network(item['imageUrl'], width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.fastfood, size: 40, color: Colors.grey[400]),
                  title: Text(item['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('UGX ${item['price'] ?? ''}'),
                      Text('Status: ${item['status'] ?? ''}'),
                      Text('Type: ${item['type'] ?? ''}'),
                    ],
                  ),
                  onTap: () {
                    Provider.of<CartModel>(context, listen: false).addItem({
                      ...item,
                      'restaurant': restaurantName,
                      'quantity': 1,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added ${item['name']} to cart'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(bottom: 80, right: 20, left: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<CartModel>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) return SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
            icon: Icon(Icons.shopping_cart),
            label: Text('View Cart'),
            backgroundColor: Theme.of(context).primaryColor,
          );
        },
      ),
    );
  }
} 