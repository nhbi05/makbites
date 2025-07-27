import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_home.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final Map<String, DateTime?>? optimalMealTimes;
  final String orderSource; // Add this
  CheckoutPage({required this.orders, this.optimalMealTimes, required this.orderSource});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late List<Map<String, dynamic>> _editableOrders;
  bool _isSaving = false;
  String? _locationAddress;
  double? _locationLat;
  double? _locationLng;

  @override
  void initState() {
    super.initState();
    // Make a copy so edits don't affect the original list
    _editableOrders = widget.orders.map((order) => Map<String, dynamic>.from(order)).toList();
  }

  String _getOrderTime(String mealType) {
    if (widget.optimalMealTimes != null && widget.optimalMealTimes![mealType] != null) {
      final optimal = widget.optimalMealTimes![mealType]!;
      final orderTime = optimal.subtract(Duration(minutes: 20));
      return DateFormat('HH:mm').format(orderTime);
    }
    return '-';
  }

  Future<void> _saveOrdersToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    for (final order in _editableOrders) {
      try {
        // Calculate scheduled send time
        final mealType = order['mealType'];
        final optimalMealTimes = widget.optimalMealTimes;
        DateTime? scheduledSendTime;
        DateTime? optimalMealTime;
        if (optimalMealTimes != null && optimalMealTimes[mealType] != null) {
          optimalMealTime = optimalMealTimes[mealType];
          scheduledSendTime = optimalMealTime!.subtract(Duration(minutes: 30));
        }
        // Determine status and send logic
        String status;
        DateTime? sentAt;
        if (widget.orderSource == 'browse') {
          status = 'sent';
          sentAt = DateTime.now();
          scheduledSendTime = null;
        } else {
          status = 'pending';
          sentAt = null; // Explicitly do not set sentAt for scheduled orders
        }
        // Get customer phone from order or fetch from user profile
        String? customerPhone = order['customerPhone'];
        if (customerPhone == null || customerPhone.isEmpty) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          print('Fetched user doc for ${user.uid}: ${userDoc.data()}'); // <-- Add this
          customerPhone = userDoc.data()?['phone'] ?? '';
          print('Fetched phone: $customerPhone'); // <-- And this
        }
        // Get restaurant ID from restaurant name
        String? restaurantId;
        if (order['restaurant'] != null) {
          final restaurantSnapshot = await FirebaseFirestore.instance
              .collection('restaurants')
              .where('name', isEqualTo: order['restaurant'])
              .limit(1)
              .get();
          
          if (restaurantSnapshot.docs.isNotEmpty) {
            restaurantId = restaurantSnapshot.docs.first.id;
          }
        }

        // Create items array for the order
        List<Map<String, dynamic>> items = [];
        if (order['items'] != null) {
          // If items are already in the order, use them
          items = List<Map<String, dynamic>>.from(order['items']);
        } else {
          // Create a single item from the order data
          items = [{
            'name': order['food'] ?? 'Food Item',
            'price': order['foodPrice'] ?? 0,
            'quantity': 1,
            'restaurant': order['restaurant'],
            'imageUrl': order['imageUrl'],
            'description': order['description'],
          }];
        }

        await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'mealType': order['mealType'],
          'food': order['food'],
          'restaurant': order['restaurant'],
          'restaurantId': restaurantId, // Add restaurant ID for security rules
          'items': items, // Save the full list of ordered items
          'foodPrice': order['foodPrice'],
          'location': order['location'],
          'locationLat': order['locationLat'],
          'locationLng': order['locationLng'],
          'orderTime': scheduledSendTime, // This is the time to send to restaurant
          'orderDate': order['orderDate'] ?? DateTime.now(),
          'clientTimestamp': DateTime.now(),
          'serverTimestamp': FieldValue.serverTimestamp(),
          'status': status, // Set to 'sent' for browse, 'pending' for schedule
          'orderSource': widget.orderSource,
          'scheduledSendTime': scheduledSendTime, // Add this field
          'scheduledTime': scheduledSendTime != null ? Timestamp.fromDate(scheduledSendTime) : null, // <-- Add this line
          'customerLocation': {
            'latitude': order['locationLat'],
            'longitude': order['locationLng'],
          },
          'customerPhone': customerPhone, // <-- Ensure phone is saved
        });
      } catch (e) {
        print('Error saving order: $e');
        throw e;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int total = _editableOrders.fold(0, (sum, order) => (sum + (order['foodPrice'] ?? 0)) as int);
    return Scaffold(
      appBar: AppBar(title: Text('Checkout'), backgroundColor: AppColors.primary),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Summary', style: AppTextStyles.subHeader),
              ..._editableOrders.asMap().entries.map((entry) {
                int idx = entry.key;
                Map<String, dynamic> order = entry.value;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${order['mealType']}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                            Text('Order Time: ${_getOrderTime(order['mealType'])}', style: AppTextStyles.body.copyWith(fontSize: 13)),
                          ],
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: order['food'],
                          decoration: InputDecoration(labelText: 'Food'),
                          onChanged: (val) => setState(() => order['food'] = val),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: order['restaurant'],
                          decoration: InputDecoration(labelText: 'Restaurant'),
                          onChanged: (val) => setState(() => order['restaurant'] = val),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: order['foodPrice']?.toString(),
                          decoration: InputDecoration(labelText: 'Price (UGX)'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => setState(() => order['foodPrice'] = int.tryParse(val) ?? order['foodPrice']),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          initialValue: order['location'],
                          decoration: InputDecoration(labelText: 'Delivery Location'),
                          onChanged: (val) => setState(() => order['location'] = val),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              Divider(),
              ListTile(
                title: Text('Total', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                trailing: Text('UGX $total', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 32),
              Center(
                child: _isSaving
                    ? CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _editableOrders.every((order) => order['location'] != null && order['location'].toString().trim().isNotEmpty)
                            ? () async {
                                setState(() => _isSaving = true);
                                try {
                                  await _saveOrdersToFirestore();
                                  setState(() => _isSaving = false);
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Order Confirmed!'),
                                      content: Text('Your meals have been ordered.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context); // Close dialog
                                            Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(builder: (context) => CustomerHomeScreen()),
                                              (route) => false,
                                            );
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
                              }
                            : null,
                        icon: Icon(Icons.check_circle),
                        label: Text('Place Final Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 