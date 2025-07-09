import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'delivery_location.dart';

class DeliveryRoute {
  final String id;
  final List<DeliveryLocation> locations;
  final List<LatLng> routePoints;
  final double totalDistance;
  final Duration estimatedDuration;
  final DateTime createdAt;
  final bool isOptimized;

  DeliveryRoute({
    required this.id,
    required this.locations,
    required this.routePoints,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.createdAt,
    this.isOptimized = false,
  });

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) {
    return DeliveryRoute(
      id: json['id'],
      locations: (json['locations'] as List)
          .map((loc) => DeliveryLocation.fromJson(loc))
          .toList(),
      routePoints: (json['routePoints'] as List)
          .map((point) => LatLng(point['latitude'], point['longitude']))
          .toList(),
      totalDistance: json['totalDistance'].toDouble(),
      estimatedDuration: Duration(seconds: json['estimatedDurationSeconds']),
      createdAt: DateTime.parse(json['createdAt']),
      isOptimized: json['isOptimized'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'locations': locations.map((loc) => loc.toJson()).toList(),
      'routePoints': routePoints
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(),
      'totalDistance': totalDistance,
      'estimatedDurationSeconds': estimatedDuration.inSeconds,
      'createdAt': createdAt.toIso8601String(),
      'isOptimized': isOptimized,
    };
  }

  DeliveryRoute copyWith({
    String? id,
    List<DeliveryLocation>? locations,
    List<LatLng>? routePoints,
    double? totalDistance,
    Duration? estimatedDuration,
    DateTime? createdAt,
    bool? isOptimized,
  }) {
    return DeliveryRoute(
      id: id ?? this.id,
      locations: locations ?? this.locations,
      routePoints: routePoints ?? this.routePoints,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      isOptimized: isOptimized ?? this.isOptimized,
    );
  }

  // Get the next unvisited location
  DeliveryLocation? get nextLocation {
    return locations.firstWhere(
      (location) => !location.isCompleted,
      orElse: () => locations.first,
    );
  }

  // Get completed locations count
  int get completedCount {
    return locations.where((location) => location.isCompleted).length;
  }

  // Get total earnings for the route
  double get totalEarnings {
    return locations.fold(0.0, (sum, location) => sum + location.earning);
  }
}

