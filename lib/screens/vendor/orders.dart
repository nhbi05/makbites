import 'package:flutter/material.dart';
import 'package:clonemukbites/models/orders_model.dart'; //  the model

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
      customerName: "Trevor",
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