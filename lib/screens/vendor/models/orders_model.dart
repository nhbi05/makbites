//import 'package:makbites/models/orders_model.dart';



class Order {
  final String food;
  final int foodPrice;
  final String restaurant;
  final String mealType;
  final String orderDate;
  final String dueTime;
  final String paymentMethod;
  final String userId;


  Order({
    required this.food,
    required this.foodPrice,
    required this.restaurant,
    required this.mealType,
    required this.orderDate,
    required this.dueTime,
    required this.paymentMethod,
    required this.userId,
  });

  factory Order.fromFirestore(Map<String,dynamic> data){
    return Order(
      food: data['food'] ?? '',
      foodPrice: data ['foodPrice'] ?? 0,
      restaurant: data['restaurant'] ?? '',
      mealType: data['mealType'] ?? '',
      orderDate: data['orderDate']?.toString() ?? '',
      dueTime: data['dueTime'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      userId: data['userId'] ?? '',
    );

  }
}
