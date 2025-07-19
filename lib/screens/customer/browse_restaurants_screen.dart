import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/cart_model.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'restaurant_menu_screen.dart';
import '../../widgets/map_picker.dart'; // Added import for MapPicker

class BrowseRestaurantsScreen extends StatefulWidget {
  @override
  _BrowseRestaurantsScreenState createState() => _BrowseRestaurantsScreenState();
}

class _BrowseRestaurantsScreenState extends State<BrowseRestaurantsScreen> {
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    listenToRestaurants();
  }

  void listenToRestaurants() {
    final names = [
      "MK-Catering Services",
      "Fresh Hot",
      "Lumumba Cafe",
      "Freddoz",
      "Ssalongo's"
    ];
    FirebaseFirestore.instance
        .collection('restaurants')
        .where('name', whereIn: names)
        .snapshots()
        .listen((snapshot) {
      final seenNames = <String>{};
    setState(() {
        restaurants = snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['docId'] = doc.id; // Attach the Firestore document ID
              return data;
            })
            .where((restaurant) => seenNames.add(restaurant['name']))
            .toList();
      isLoading = false;
      });
    });
  }

  Widget _buildModernRestaurantCard(String name, String location, String imageUrl, String docId) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 18, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantMenuScreen(
                restaurantDocId: docId,
                restaurantName: name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl != ""
                    ? Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.restaurant, size: 56, color: Colors.grey[400]),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text(location, style: TextStyle(color: Colors.black.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browse Restaurants'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : restaurants.isEmpty
              ? Center(child: Text('No restaurants found.'))
              : ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return _buildModernRestaurantCard(
                      restaurant['name'] ?? 'No Name',
                      restaurant['location'] ?? '',
                      restaurant['profileImage'] ?? '',
                      restaurant['docId'] ?? '',
                    );
                  },
                ),
    );
  }
}

// Remove the RestaurantMenuScreen class from this file entirely, so it is only defined in restaurant_menu_screen.dart

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    double total = 0;
    for (final item in cart.items) {
      final price = (item['price'] ?? 0) as num;
      final quantity = (item['quantity'] ?? 1) as num;
      total += price * quantity;
    }
    return Scaffold(
      appBar: AppBar(title: Text('Your Cart')),
      body: cart.items.isEmpty
          ? Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final price = (item['price'] ?? 0) as num;
                      final quantity = (item['quantity'] ?? 1) as num;
                      return ListTile(
                        leading: item['imageUrl'] != null && item['imageUrl'] != ''
                            ? Image.network(item['imageUrl'], width: 40, height: 40, fit: BoxFit.cover)
                            : Icon(Icons.fastfood, size: 32, color: Colors.grey[400]),
                        title: Text(item['name'] ?? 'No Name'),
                        subtitle: Text('UGX $price x $quantity = UGX ${price * quantity}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            cart.removeItem(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('UGX $total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CheckoutScreen(total: total)),
                        );
                      },
                      child: Text('Checkout'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final double total;
  CheckoutScreen({required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _locationController = TextEditingController();
  late int deliveryFee;
  late String deliveryFeeLabel;
  bool _isSaving = false;
  Map<String, dynamic>? _pickedLocationData; // To store lat/lng/address

  @override
  void initState() {
    super.initState();
    final options = [0, 500, 1000];
    deliveryFee = options[Random().nextInt(options.length)];
    deliveryFeeLabel = deliveryFee == 0 ? 'Free' : 'UGX $deliveryFee';
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPicker()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _pickedLocationData = result;
        _locationController.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _saveOrderToFirestore(List<Map<String, dynamic>> items, String location, double total, int deliveryFee) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      // Determine restaurant name from the first item (assuming all items are from the same restaurant)
      String? restaurantName;
      if (items.isNotEmpty && items[0].containsKey('restaurant')) {
        restaurantName = items[0]['restaurant'];
      }
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'items': items,
        'location': location,
        'foodPrice': total,
        'deliveryFee': deliveryFee,
        'clientTimestamp': DateTime.now(),
        'serverTimestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // Ready for vendor assignment
        'sentAt': DateTime.now(), // Add sent timestamp
        'orderSource': 'browse',
        if (restaurantName != null) 'restaurant': restaurantName, // <-- Add top-level restaurant field
        if (_pickedLocationData != null) ...{
          'customerLocation': {
            'latitude': _pickedLocationData!['lat'],
            'longitude': _pickedLocationData!['lng'],
          },
          'customerAddress': _pickedLocationData!['address'],
        },
      });
    } catch (e) {
      print('Error saving order: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    double itemsTotal = 0;
    for (final item in cart.items) {
      final price = (item['price'] ?? 0) as num;
      final quantity = (item['quantity'] ?? 1) as num;
      itemsTotal += price * quantity;
    }
    double grandTotal = itemsTotal + deliveryFee;
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  final price = (item['price'] ?? 0) as num;
                  final quantity = (item['quantity'] ?? 1) as num;
                  return ListTile(
                    leading: item['imageUrl'] != null && item['imageUrl'] != ''
                        ? Image.network(item['imageUrl'], width: 40, height: 40, fit: BoxFit.cover)
                        : Icon(Icons.fastfood, size: 32, color: Colors.grey[400]),
                    title: Text(item['name'] ?? 'No Name'),
                    subtitle: Text('UGX $price x $quantity = UGX ${price * quantity}'),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Fee:', style: TextStyle(fontSize: 16)),
                Text(deliveryFeeLabel, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: 'Delivery Location',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.map),
                label: Text('Pick on Map'),
                onPressed: _openMapPicker,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('UGX $grandTotal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _isSaving
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_locationController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please enter a delivery location.')),
                          );
                          return;
                        }
                        setState(() => _isSaving = true);
                        try {
                          await _saveOrderToFirestore(
                            cart.items,
                            _locationController.text.trim(),
                            itemsTotal,
                            deliveryFee,
                          );
                          setState(() => _isSaving = false);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Order Confirmed'),
                              content: Text('Your order has been sent to the restaurant!'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // Close dialog
                                    Navigator.pop(context); // Back to cart
                                    Navigator.pop(context); // Back to menu
                                    cart.clear();
                                  },
                                  child: Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          setState(() => _isSaving = false);
                          print('Order placement failed: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to place order. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: Text('Confirm Order'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 