import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting, add intl dependency in pubspec.yaml

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
    String newStatus;
    if (currentStatus == "New" || currentStatus == "Pending") {
      newStatus = "Start Preparing";
    } else if (currentStatus == "Start Preparing") {
      newStatus = "Completed";
    } else {
      newStatus = currentStatus; // No change
    }

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  void cancelOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'Cancelled',
    });
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cancel Order"),
        content: Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("No"),
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('restaurant', isEqualTo: widget.vendorRestaurantId)
              .orderBy('serverTimestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No orders found.'));
            }

            final orders = snapshot.data!.docs;

            int totalOrders = orders.length;
            int completedOrders = orders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey('status') && data['status'] == "Completed";
            }).length;

            int cancelledOrders = orders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data.containsKey('status') && data['status'] == "Cancelled";
            }).length;

            int totalRevenue = orders.fold(0, (sum, doc) {
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
                    _infoCard("Total Revenue", "shs.$totalRevenue"),
                  ],
                ),
                SizedBox(height: 16),
                Text("Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final orderDoc = orders[index];
                      final orderData = orderDoc.data() as Map<String, dynamic>;

                      final userId = orderData['userId'] ?? 'Unknown';
                      final customerName = _userIdToName[userId] ?? userId;

                      final orderId = orderDoc.id;

                      final timestamp = orderData['clientTimestamp'];
                      final orderTime = (timestamp != null && timestamp is Timestamp)
                          ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
                          : 'Unknown time';

                      final foodItem = orderData['food'] ?? 'No items';
                      final status = orderData['status'] ?? 'Pending';
                      final price = orderData['foodPrice'] ?? 0;

                      final mealType = orderData['mealType'] ?? '';
                      final paymentMethod = orderData['paymentMethod'] ?? '';

                      return GestureDetector(
                        onTap: () => updateOrderStatus(orderId, status),
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(customerName, style: TextStyle(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () => _showCancelDialog(context, orderId),
                                    ),
                                  ],
                                ),
                                Text("$orderId • $orderTime"),
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
                                        color: status == "Completed"
                                            ? Colors.green
                                            : status == "Start Preparing"
                                            ? Colors.orange
                                            : Colors.blueAccent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            status == "Completed"
                                                ? Icons.check
                                                : status == "Start Preparing"
                                                ? Icons.access_time
                                                : Icons.fiber_new,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(status, style: TextStyle(color: Colors.white)),
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
