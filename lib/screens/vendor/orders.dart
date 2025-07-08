import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:makbites/screens/vendor/set_preparation_time.dart';

class OrdersPage extends StatefulWidget {
  final String vendorRestaurantId;

  // OrdersPage({String? vendorRestaurantId})
  //     : vendorRestaurantId = (vendorRestaurantId == null || vendorRestaurantId.trim().isEmpty)
  //     ? "Ssalongo's"
  //     : vendorRestaurantId;

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
    if (currentStatus == "Start Preparing") {
      newStatus = "Completed";
    } else {
      return;
    }

    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': newStatus});
    setState(() {});
  }

  void cancelOrder(String orderId) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': 'Cancelled'});
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
    String newId = 'ORDER-${DateTime.now().millisecondsSinceEpoch.toString()}';

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

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test order $newId created')));
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

            final orders = snapshot.data!.docs;

            int totalOrders = orders.length;
            int completedOrders = orders
                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == "Completed")
                .length;
            int cancelledOrders = orders
                .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == "Cancelled")
                .length;
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
                      final displayOrderId = '#ORD${(index + 1).toString().padLeft(3, '0')}';
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
                        onTap: () {
                          print('🟡 Order tapped with status: $status');

                          if (status == "Pending") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SetPreparationTimePage(
                                  orderId: orderId,
                                  vendorRestaurantId: widget.vendorRestaurantId,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Order marked as "Start Preparing"!')),
                                );
                              }
                            });
                          } else if (status == "Start Preparing") {
                            updateOrderStatus(orderId, status); // mark as Completed
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Order marked as "Completed"!')),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderDetailPage(
                                  orderId: orderId,
                                  displayOrderId: displayOrderId,
                                  orderData: orderData,
                                  customerName: customerName,
                                ),
                              ),
                            );
                          }
                        },

                        //     ).then((result) {
                        //       setState(() {}); // Refresh after prep time set
                        //     });
                        //   } else if (status == "Start Preparing") {
                        //     updateOrderStatus(orderId, status); // Move to Completed
                        //   } else {
                        //     Navigator.push(
                        //       context,
                        //       MaterialPageRoute(
                        //         builder: (_) => OrderDetailPage(
                        //           orderId: orderId,
                        //           displayOrderId: displayOrderId,
                        //           orderData: orderData,
                        //           customerName: customerName,
                        //         ),
                        //       ),
                        //     );
                        //   }
                        // },
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

class OrderDetailPage extends StatelessWidget {
  final String orderId;
  final String displayOrderId;
  final Map<String, dynamic> orderData;
  final String customerName;

  const OrderDetailPage({
    required this.orderId,
    required this.displayOrderId,
    required this.orderData,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = orderData['clientTimestamp'];
    final orderTime = (timestamp != null && timestamp is Timestamp)
        ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
        : 'Unknown time';

    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID: $displayOrderId", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 12),
                  Text("Customer: $customerName"),
                  Text("Food: ${orderData['food'] ?? 'N/A'}"),
                  Text("Meal Type: ${orderData['mealType'] ?? 'N/A'}"),
                  Text("Price: Shs. ${orderData['foodPrice'] ?? 'N/A'}"),
                  Text("Payment Method: ${orderData['paymentMethod'] ?? 'N/A'}"),
                  Text("Status: ${orderData['status'] ?? 'N/A'}"),
                  Text("Time: $orderTime"),
                  SizedBox(height: 20),
                  if (orderData.containsKey('notes') && (orderData['notes'] as String).trim().isNotEmpty)
                    Text("Customer Notes:\n${orderData['notes']}", style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}