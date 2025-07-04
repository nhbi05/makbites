import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WeeklySchedule {
  final String id;
  final String userId;
  final List<DaySchedule> days;
  final DateTime createdAt;
  final bool isActive;

  WeeklySchedule({
    required this.id,
    required this.userId,
    required this.days,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'days': days.map((day) => day.toMap()).toList(),
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }

  factory WeeklySchedule.fromMap(Map<String, dynamic> map) {
    return WeeklySchedule(
      id: map['id'],
      userId: map['userId'],
      days: (map['days'] as List).map((day) => DaySchedule.fromMap(day)).toList(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }
}

class DaySchedule {
  final String dayName;
  final List<MealSchedule> meals;
  bool isEnabled;

  DaySchedule({
    required this.dayName,
    required this.meals,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayName': dayName,
      'meals': meals.map((meal) => meal.toMap()).toList(),
      'isEnabled': isEnabled,
    };
  }

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    return DaySchedule(
      dayName: map['dayName'],
      meals: (map['meals'] as List).map((meal) => MealSchedule.fromMap(meal)).toList(),
      isEnabled: map['isEnabled'] ?? true,
    );
  }
}

class MealSchedule {
  final String mealType; // breakfast, lunch, dinner
  TimeOfDay time;
  String? restaurantId;
  String? mealId;
  bool isEnabled;

  MealSchedule({
    required this.mealType,
    required this.time,
    this.restaurantId,
    this.mealId,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'mealType': mealType,
      'time': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'restaurantId': restaurantId,
      'mealId': mealId,
      'isEnabled': isEnabled,
    };
  }

  factory MealSchedule.fromMap(Map<String, dynamic> map) {
    final timeParts = map['time'].split(':');
    return MealSchedule(
      mealType: map['mealType'],
      time: TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1])),
      restaurantId: map['restaurantId'],
      mealId: map['mealId'],
      isEnabled: map['isEnabled'] ?? true,
    );
  }
}

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final String deliveryTime;
  final String imageUrl;
  final bool isAvailable;

  Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    this.imageUrl = '',
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'rating': rating,
      'deliveryTime': deliveryTime,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'],
      name: map['name'],
      cuisine: map['cuisine'],
      rating: map['rating'].toDouble(),
      deliveryTime: map['deliveryTime'],
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}

class Meal {
  final String id;
  final String name;
  final String description;
  final double price;
  final String restaurantId;
  final String category; // breakfast, lunch, dinner
  final String imageUrl;
  final bool isAvailable;

  Meal({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.restaurantId,
    required this.category,
    this.imageUrl = '',
    this.isAvailable = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'restaurantId': restaurantId,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: map['price'].toDouble(),
      restaurantId: map['restaurantId'],
      category: map['category'],
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
    );
  }
}

class AutomatedOrder {
  final String id;
  final String userId;
  final String restaurantId;
  final String mealId;
  final DateTime scheduledTime;
  final DateTime orderTime;
  final String status; // pending, confirmed, preparing, delivered, cancelled
  final double totalAmount;

  AutomatedOrder({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.mealId,
    required this.scheduledTime,
    required this.orderTime,
    required this.status,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'restaurantId': restaurantId,
      'mealId': mealId,
      'scheduledTime': scheduledTime,
      'orderTime': orderTime,
      'status': status,
      'totalAmount': totalAmount,
    };
  }

  factory AutomatedOrder.fromMap(Map<String, dynamic> map) {
    return AutomatedOrder(
      id: map['id'],
      userId: map['userId'],
      restaurantId: map['restaurantId'],
      mealId: map['mealId'],
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      orderTime: (map['orderTime'] as Timestamp).toDate(),
      status: map['status'],
      totalAmount: map['totalAmount'].toDouble(),
    );
  }
} 