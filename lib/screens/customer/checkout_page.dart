import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'customer_home.dart';

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
        await FirebaseFirestore.instance.collection('orders').add({
          'userId': user.uid,
          'mealType': order['mealType'],
          'food': order['food'],
          'restaurant': order['restaurant'],
          'foodPrice': order['foodPrice'],
          'paymentMethod': order['paymentMethod'],
          'location': order['location'],
          'orderTime': _getOrderTime(order['mealType']),
          'orderDate': order['orderDate'] ?? DateTime.now(),
          'clientTimestamp': DateTime.now(),
          'serverTimestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'orderSource': widget.orderSource, // Save the source
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
                          initialValue: order['paymentMethod'],
                          decoration: InputDecoration(labelText: 'Payment Method'),
                          onChanged: (val) => setState(() => order['paymentMethod'] = val),
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
                        onPressed: _editableOrders.every((order) => order['paymentMethod'] != null && order['paymentMethod'].toString().trim().isNotEmpty && order['location'] != null && order['location'].toString().trim().isNotEmpty)
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