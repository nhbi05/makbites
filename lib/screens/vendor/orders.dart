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