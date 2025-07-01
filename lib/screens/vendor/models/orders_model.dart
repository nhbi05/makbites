//import 'package:makbites/models/orders_model.dart';



class Order {
  final String customerName;
  final String orderId;
  final String timeAgo;
  final List<String> items;
  String status; // "Completed", "start preparing" but we can update later
  final int price;

  Order({
    required this.customerName,
    required this.orderId,
    required this.timeAgo,
    required this.items,
    required this.status,
    required this.price,
  });
}
