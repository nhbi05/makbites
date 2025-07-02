import 'package:flutter/material.dart';
import 'models/orders_model.dart';//  Your model

 //  Your model

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> orders = [
    Order(
      customerName: "Khana",
      orderId: "Order #001",
      timeAgo: "1 hour ago",
      items: ["Rice", "Peas(x2)"],
      status: "Completed",
      price: 3000,
    ),
    Order(
      customerName: "Jamimah",
      orderId: "Order #002",
      timeAgo: "Just now",
      items: ["Pilau rice"],
      status: "Start Preparing",
      price: 6000,
    ),
    Order(
      customerName: "Dalton",
      orderId: "Order #003",
      timeAgo: "20 minutes ago",
      items: ["Katogo"],
      status: "Pending",
      price: 2500,
    ),
    Order(
      customerName: "Bella",
      orderId: "Order #004",
      timeAgo: "20 minutes ago",
      items: ["Rice", "meat"],
      status: "Start Preparing",
      price: 5000,
    ),
    Order(
      customerName: "Daniella",
      orderId: "Order #005",
      timeAgo: "10 minutes ago",
      items: ["Katogo"],
      status: "Pending",
      price: 2500,
    ),
  ];

  int get totalOrders => orders.length;
  int get completedOrders => orders.where((o) => o.status == "Completed").length;
  int get cancelledOrders => 1; // You can improve this later
  int get totalRevenue => orders.fold(0, (sum, o) => sum + o.price);

  void updateOrderStatus(int index) {
    setState(() {
      if (orders[index].status == "New" || orders[index].status == "Pending") {
        orders[index].status = "Start Preparing";
      } else if (orders[index].status == "Start Preparing") {
        orders[index].status = "Completed";
      }
    });
  }

  void cancelOrder(int index) {
    setState(() {
      orders.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          "Muk Bites",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: Colors.white,
          ),
        ),
      ),
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
                    onTap: () => updateOrderStatus(index),
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
            onPressed: () {
              cancelOrder(index);
              Navigator.pop(ctx);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }
}
