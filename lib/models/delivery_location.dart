import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeliveryLocation {
  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final String customerName;
  final String customerPhone;
  final String items;
  final double earning;
  final bool isPickup;
  final bool isCompleted;
  final DateTime? estimatedTime;
  final int? priority; // New field
  final int? routeIndex; // New field

  DeliveryLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.earning,
    this.isPickup = false,
    this.isCompleted = false,
    this.estimatedTime,
    this.priority,
    this.routeIndex,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      coordinates: LatLng(json['latitude'], json['longitude']),
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      items: json['items'],
      earning: json['earning'].toDouble(),
      isPickup: json['isPickup'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      estimatedTime: json['estimatedTime'] != null 
          ? DateTime.parse(json['estimatedTime']) 
          : null,
      priority: json['priority'],
      routeIndex: json['routeIndex'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items,
      'earning': earning,
      'isPickup': isPickup,
      'isCompleted': isCompleted,
      'estimatedTime': estimatedTime?.toIso8601String(),
      'priority': priority,
      'routeIndex': routeIndex,
    };
  }

  DeliveryLocation copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? coordinates,
    String? customerName,
    String? customerPhone,
    String? items,
    double? earning,
    bool? isPickup,
    bool? isCompleted,
    DateTime? estimatedTime,
    int? priority,
    int? routeIndex,
  }) {
    return DeliveryLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      earning: earning ?? this.earning,
      isPickup: isPickup ?? this.isPickup,
      isCompleted: isCompleted ?? this.isCompleted,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      priority: priority ?? this.priority,
      routeIndex: routeIndex ?? this.routeIndex,
    );
  }
}


