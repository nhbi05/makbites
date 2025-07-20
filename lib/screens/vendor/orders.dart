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

  void updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order marked as "$newStatus"!')),
    );

    setState(() {});
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

  void _showStatusChangeOptions(String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Order Status"),
        content: Text("Do you want to change the order status?"),
        actions: [
          if (currentStatus == "start preparing") ...[
            TextButton(
              onPressed: () {
                updateOrderStatus(orderId, "Pending");
                Navigator.pop(ctx);
              },
              child: Text("Revert to Pending"),
            ),
            TextButton(
              onPressed: () {
                updateOrderStatus(orderId, "Completed");
                Navigator.pop(ctx);
              },
              child: Text("Mark as Completed"),
            ),
          ] else if (currentStatus == "completed") ...[
            TextButton(
              onPressed: () {
                updateOrderStatus(orderId, "Start Preparing");
                Navigator.pop(ctx);
              },
              child: Text("Revert to Start Preparing"),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
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
              return data.containsKey('status') &&
                  data['status'] != null &&
                  data['status'].toString().trim().isNotEmpty;
            }).toList();

            // Sort orders by timestamp (latest first)
            validOrders.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;

              final aTimestamp = aData['clientTimestamp'];
              final bTimestamp = bData['clientTimestamp'];

              if (aTimestamp == null && bTimestamp == null) return 0;
              if (aTimestamp == null) return 1;
              if (bTimestamp == null) return -1;

              if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
                return bTimestamp.compareTo(aTimestamp); // Latest first
              }

              return 0;
            });

            int totalOrders = validOrders.length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Track and manage all your restaurant orders here!\n",
                  style: TextStyle(fontSize: 16),
                ),
                Text("Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: validOrders.length,
                    itemBuilder: (context, index) {
                      final orderDoc = validOrders[index];
                      final orderData = orderDoc.data() as Map<String, dynamic>;

                      final orderId = orderDoc.id;
                      final userId = orderData['userId'] ?? 'Unknown';
                      final customerName = _userIdToName[userId] ?? 'Unkown Customer';
                      final displayOrderId =
                          '#ORD${(totalOrders - index).toString().padLeft(3, '0')}';
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsPage(
                                  orderData: orderData,
                                  customerName: customerName,
                                  orderId: displayOrderId,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(customerName,
                                        style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                    if (normalizedStatus == "pending")
                                      GestureDetector(
                                        onTap: () =>
                                            _showCancelDialog(context, orderId),
                                        child: Tooltip(
                                          message: "Cancel Order",
                                          child:
                                          Icon(Icons.cancel, color: Colors.red),
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
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (normalizedStatus == "pending") {
                                          _showSetPreparationTimeDialog(orderId);
                                        } else if (normalizedStatus == "start preparing" ||
                                            normalizedStatus == "completed") {
                                          _showStatusChangeOptions(orderId, normalizedStatus);
                                        }
                                        // No action for cancelled
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
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
                                              style:
                                              TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Text("Shs. $price",
                                        style: TextStyle(fontWeight: FontWeight.bold)),
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
}

// Orders Details Page
class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final String customerName;
  final String orderId;

  const OrderDetailsPage({
    required this.orderData,
    required this.customerName,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd – kk:mm');
    final timestamp = orderData['clientTimestamp'];
    final orderTime = (timestamp != null)
        ? formatter.format(timestamp.toDate())
        : 'Unknown';

    final deliveryMan = orderData['deliveryMan'];
    final deliveryInfo = deliveryMan != null && deliveryMan.toString().isNotEmpty
        ? "Assigned to: $deliveryMan"
        : "No delivery person assigned yet";

    return Scaffold(
      appBar: AppBar(title: Text("Order Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Order ID: $orderId",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Customer: $customerName"),
            Text("Food: ${orderData['food'] ?? 'N/A'}"),
            Text("Price: Shs. ${orderData['foodPrice'] ?? 'N/A'}"),
            Text("Meal Type: ${orderData['mealType'] ?? 'N/A'}"),
            Text("Payment Method: ${orderData['paymentMethod'] ?? 'N/A'}"),
            SizedBox(height: 10),
            Text("Delivery Address: ${orderData['deliveryAddress'] ?? 'N/A'}"),
            Text("Contact Info: ${orderData['contactInfo'] ?? 'N/A'}"),
            SizedBox(height: 10),
            Text("Notes: ${orderData['notes'] ?? 'No notes'}"),
            SizedBox(height: 10),
            Text("Order Time: $orderTime"),
            SizedBox(height: 10),
            Text(deliveryInfo, style: TextStyle(color: Colors.blueGrey)),
          ],
        ),
      ),
    );
  }
}
