import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:makbites/screens/vendor/set_preparation_time.dart';

class OrdersPage extends StatefulWidget {
  final String vendorRestaurantId;

  OrdersPage({required this.vendorRestaurantId});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Map<String, String> _userIdToName = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _showSetPreparationTimeDialog(String orderId) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SetPreparationTimePage(
          orderId: orderId,
          vendorRestaurantIdOrName: widget.vendorRestaurantId,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _loadUsers() async {
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final usersMap = <String, String>{};
    for (var doc in userSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('uid') && data.containsKey('name')) {
        usersMap[data['uid']] = data['name'];
      }
    }
    setState(() {
      _userIdToName = usersMap;
    });
  }

  void updateOrderStatus(String orderId, String currentStatus) async {
    if (currentStatus.trim().toLowerCase() == "start preparing") {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as "Completed"!')),
      );

      setState(() {});
    }
  }

  void cancelOrder(String orderId) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Cancelled'});

    setState(() {});
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cancel Order"),
        content: Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("No")),
          TextButton(
            onPressed: () {
              cancelOrder(orderId);
              Navigator.pop(ctx);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestOrder() async {
    String newId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

    await FirebaseFirestore.instance.collection('orders').doc(newId).set({
      'restaurant': widget.vendorRestaurantId,
      'food': 'Chapati',
      'foodPrice': 2000,
      'status': 'Pending',
      'clientTimestamp': Timestamp.now(),
      'serverTimestamp': Timestamp.now(),
      'userId': _userIdToName.keys.isNotEmpty ? _userIdToName.keys.first : 'Unknown',
      'mealType': 'Breakfast',
      'paymentMethod': 'Cash on Delivery',
      'deliveryAddress': 'Kampala, Plot 10 Makerere',
      'contactInfo': '0789-123-456',
      'notes': 'Please add ketchup and cutlery.',
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test order created')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createTestOrder,
        child: Icon(Icons.add),
        tooltip: 'Create Test Order',
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('restaurant', isEqualTo: widget.vendorRestaurantId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No orders found for this restaurant.'));
            }

            final allDocs = snapshot.data!.docs;

            final validOrders = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey('status') && data['status'] != null && data['status'].toString().trim().isNotEmpty;
            }).toList();

            int totalOrders = validOrders.length;
            int completedOrders = validOrders
                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == "Completed")
                .length;
            int cancelledOrders = validOrders
                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == "Cancelled")
                .length;
            int totalRevenue = validOrders.fold(0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              final price = data['foodPrice'] ?? 0;
              return sum + (price is num ? price.toInt() : 0);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Orders details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Text("Track and manage all your restaurant orders here!\n"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCard("Total orders", totalOrders.toString()),
                    _infoCard("Completed", completedOrders.toString()),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCard("Cancelled", cancelledOrders.toString()),
                    _infoCard("Total Revenue", "shs.${NumberFormat('#,###').format(totalRevenue)}"),
                  ],
                ),
                SizedBox(height: 16),
                Text("Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Expanded(
                  child: ListView.builder(
                    itemCount: validOrders.length,
                    itemBuilder: (context, index) {
                      final orderDoc = validOrders[index];
                      final orderData = orderDoc.data() as Map<String, dynamic>;

                      final orderId = orderDoc.id;
                      final userId = orderData['userId'] ?? 'Unknown';
                      final customerName = _userIdToName[userId] ?? userId;
                      final displayOrderId = '#ORD${(index + 1).toString().padLeft(3, '0')}';
                      final timestamp = orderData['clientTimestamp'];
                      final orderTime = (timestamp != null && timestamp is Timestamp)
                          ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
                          : 'Unknown time';

                      final foodItem = orderData['food'] ?? 'No items';
                      final status = orderData['status'].toString().trim();
                      final normalizedStatus = status.toLowerCase();
                      final price = orderData['foodPrice'] ?? 0;
                      final mealType = orderData['mealType'] ?? '';
                      final paymentMethod = orderData['paymentMethod'] ?? '';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: InkWell(
                          onTap: () {
                            if (normalizedStatus == "pending") {
                              _showSetPreparationTimeDialog(orderId);
                            } else if (normalizedStatus == "start preparing") {
                              updateOrderStatus(orderId, status);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(customerName, style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (normalizedStatus == "pending")
                                      GestureDetector(
                                        onTap: () => _showCancelDialog(context, orderId),
                                        child: Tooltip(
                                          message: "Cancel Order",
                                          child: Icon(Icons.cancel, color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                                Text("$displayOrderId • $orderTime"),
                                SizedBox(height: 4),
                                Text("Food: $foodItem"),
                                Text("Meal Type: $mealType"),
                                Text("Payment: $paymentMethod"),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: normalizedStatus == "completed"
                                            ? Colors.green
                                            : normalizedStatus == "start preparing"
                                            ? Colors.orange
                                            : normalizedStatus == "cancelled"
                                            ? Colors.grey
                                            : Colors.blueAccent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            normalizedStatus == "completed"
                                                ? Icons.check
                                                : normalizedStatus == "start preparing"
                                                ? Icons.access_time
                                                : normalizedStatus == "cancelled"
                                                ? Icons.cancel
                                                : Icons.fiber_new,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            status[0].toUpperCase() + status.substring(1),
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text("Shs. $price", style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
