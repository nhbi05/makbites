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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<List<Map<String, dynamic>>> _fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    Query query = FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: user.uid);
    if (_selectedDate != null) {
      final start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0);
      final end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);
      query = query.where('clientTimestamp', isGreaterThanOrEqualTo: start).where('clientTimestamp', isLessThanOrEqualTo: end);
    }
    final snapshot = await query.orderBy('clientTimestamp', descending: true).get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final orders = snapshot.data ?? [];
                  if (orders.isEmpty) {
                    return Center(child: Text('No orders found for this date.', style: AppTextStyles.body));
                  }
                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final order = orders[idx];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${order['mealType']}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                                  Text('Order Time: ${order['orderTime'] ?? '-'}', style: AppTextStyles.body.copyWith(fontSize: 13)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text('Food: ${order['food']}', style: AppTextStyles.body),
                              Text('Restaurant: ${order['restaurant']}', style: AppTextStyles.body),
                              Text('Price: UGX ${order['foodPrice']}', style: AppTextStyles.body),
                              Text('Payment: ${order['paymentMethod']}', style: AppTextStyles.body),
                              Text('Location: ${order['location']}', style: AppTextStyles.body),
                              if (order['clientTimestamp'] != null)
                                Text('Placed: ${DateFormat('yyyy-MM-dd HH:mm').format((order['clientTimestamp'] as Timestamp).toDate())}', style: AppTextStyles.body.copyWith(fontSize: 12, color: Colors.grey)),
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
} 