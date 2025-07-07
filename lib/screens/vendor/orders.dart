import 'package:flutter/material.dart';
import 'models/orders_model.dart';//  Your model
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

 //  Your model

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    final snapshot = await firestore.FirebaseFirestore.instance.collection('orders').get();
    setState(() {
      orders = snapshot.docs.map((doc) {
        final data = doc.data();
        return Order(
          customerName: data['userId'] ?? '',
          orderId: doc.id,
          timeAgo: '', // You can format this using timestamps
          items: [data['food']?.toString() ?? ''],
          status: data['status'] ?? 'pending',
          price: data['foodPrice'] ?? 0,
        );
      }).toList();
    });
  }

  Future<void> updateOrderStatus(int index, String newStatus) async {
    final order = orders[index];
    await firestore.FirebaseFirestore.instance.collection('orders').doc(order.orderId).update({'status': newStatus});
    setState(() {
      orders[index].status = newStatus;
    });
  }

  Future<void> cancelOrder(int index) async {
    final order = orders[index];
    await firestore.FirebaseFirestore.instance.collection('orders').doc(order.orderId).update({'status': 'cancelled'});
    setState(() {
      orders[index].status = 'cancelled';
    });
  }

  int get totalOrders => orders.length;
  int get completedOrders => orders.where((o) => o.status == "Completed").length;
  int get cancelledOrders => 1; // You can improve this later
  int get totalRevenue => orders.fold(0, (sum, o) => sum + o.price);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Colors.red,
      //   title: Text(
      //     "Muk Bites",
      //     style: TextStyle(
      //       fontWeight: FontWeight.bold,
      //       fontSize: 30,
      //       color: Colors.white,
      //     ),
      //   ),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
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
                  final order = orders[index];
                  return GestureDetector(
                    onTap: () {
                      if (order.status == "New" || order.status == "Pending") {
                        updateOrderStatus(index, "Start Preparing");
                      } else if (order.status == "Start Preparing") {
                        updateOrderStatus(index, "Completed");
                      }
                    },
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
                                Text(order.customerName, style: TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _showCancelDialog(context, index),
                                ),
                              ],
                            ),
                            Text("${order.orderId} • ${order.timeAgo}"),
                            SizedBox(height: 4),
                            ...order.items.map((item) => Text(item)).toList(),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order.status == "Completed"
                                        ? Colors.green
                                        : order.status == "Start Preparing"
                                        ? Colors.orange
                                        : Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        order.status == "Completed"
                                            ? Icons.check
                                            : order.status == "Start Preparing"
                                            ? Icons.access_time
                                            : Icons.fiber_new,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(order.status, style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                                Text("Shs. ${order.price}", style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showCancelDialog(BuildContext context, int index) {
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
            onPressed: () async {
              await cancelOrder(index);
              Navigator.pop(ctx);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }
}
