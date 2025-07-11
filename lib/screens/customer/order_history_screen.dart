import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  DateTime? _selectedDate;
  bool _showAllOrders = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    // Always fetch all orders for the user first
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();
    
    final orders = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    
    // Filter by date if needed
    if (!_showAllOrders && _selectedDate != null) {
      final start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0);
      final end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);
      
      orders.removeWhere((order) {
        final timestamp = order['clientTimestamp'] as Timestamp?;
        if (timestamp == null) return true; // Remove orders without timestamp
        final orderDate = timestamp.toDate();
        return orderDate.isBefore(start) || orderDate.isAfter(end);
      });
    }
    
    // Sort orders by clientTimestamp in descending order (newest first)
    orders.sort((a, b) {
      final aTimestamp = a['clientTimestamp'] as Timestamp?;
      final bTimestamp = b['clientTimestamp'] as Timestamp?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return bTimestamp.compareTo(aTimestamp); // Descending order
    });
    
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order History'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle between all orders and date filter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Filter Orders:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showAllOrders = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _showAllOrders ? AppColors.primary : Colors.grey[300],
                              foregroundColor: _showAllOrders ? Colors.white : Colors.black,
                            ),
                            child: Text('All Orders'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showAllOrders = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !_showAllOrders ? AppColors.primary : Colors.grey[300],
                              foregroundColor: !_showAllOrders ? Colors.white : Colors.black,
                            ),
                            child: Text('By Date'),
                          ),
                        ),
                      ],
                    ),
                    // Date picker (only show when filtering by date)
                    if (!_showAllOrders) ...[
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Select Date:', style: AppTextStyles.body),
                          SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Text(_selectedDate != null ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!) : 'Select Date'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading orders: ${snapshot.error}', 
                               style: AppTextStyles.body, textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  }
                  
                  final orders = snapshot.data ?? [];
                  if (orders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            _showAllOrders 
                              ? 'No orders found. Place your first order to see it here!' 
                              : 'No orders found for this date.',
                            style: AppTextStyles.body,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final order = orders[idx];
                      // Support both scheduled and browse orders
                      String restaurant = order['restaurant'] ?? '';
                      String food = order['food'] ?? '';
                      String payment = order['paymentMethod'] ?? '';
                      if (order['items'] != null && order['items'] is List && (order['items'] as List).isNotEmpty) {
                        final firstItem = (order['items'] as List).first;
                        restaurant = firstItem['restaurant'] ?? restaurant ?? 'Unknown';
                        food = firstItem['name'] ?? food ?? 'Unknown';
                        payment = ''; // Do not show payment for browse orders
                      }
                      return Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${order['mealType'] ?? (order['items'] != null ? 'Custom Order' : 'Unknown Meal')}',
                                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'UGX ${order['foodPrice'] ?? '0'}',
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              _buildOrderDetail('Food', food.isNotEmpty ? food : 'Unknown'),
                              _buildOrderDetail('Restaurant', restaurant.isNotEmpty ? restaurant : 'Unknown'),
                              if (payment.isNotEmpty)
                                _buildOrderDetail('Payment', payment),
                              _buildOrderDetail('Location', order['location'] ?? 'Unknown'),
                              if (order['orderTime'] != null && order['orderTime'].toString().isNotEmpty)
                                _buildOrderDetail('Order Time', order['orderTime']),
                              if (order['clientTimestamp'] != null)
                                _buildOrderDetail('Placed', DateFormat('MMM dd, yyyy HH:mm').format((order['clientTimestamp'] as Timestamp).toDate())),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            child: Text(
              '$label:',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 