import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'delivery_location.dart';

class DeliveryRoute {
  final String id;
  final List<DeliveryLocation> locations;
  final List<LatLng> routePoints;
  final double totalDistance; // in kilometers
  final Duration estimatedDuration;
  final DateTime createdAt;
  final bool isOptimized;
  final String? routePolyline; // Encoded polyline for the route

  const DeliveryRoute({
    required this.id,
    required this.locations,
    required this.routePoints,
    required this.totalDistance,
    required this.estimatedDuration,
    required this.createdAt,
    this.isOptimized = false,
    this.routePolyline,
  });

  factory DeliveryRoute.empty() {
    return DeliveryRoute(
      id: '',
      locations: [],
      routePoints: [],
      totalDistance: 0.0,
      estimatedDuration: Duration.zero,
      createdAt: DateTime.now(),
      isOptimized: false,
    );
  }

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) {
    return DeliveryRoute(
      id: json['id'] as String,
      locations: (json['locations'] as List)
          .map((loc) => DeliveryLocation.fromJson(loc as Map<String, dynamic>))
          .toList(),
      routePoints: (json['routePoints'] as List)
          .map((point) => LatLng(
                (point['latitude'] as num).toDouble(),
                (point['longitude'] as num).toDouble(),
              ))
          .toList(),
      totalDistance: (json['totalDistance'] as num).toDouble(),
      estimatedDuration: Duration(seconds: json['estimatedDurationSeconds'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isOptimized: json['isOptimized'] as bool? ?? false,
      routePolyline: json['routePolyline'] as String?,
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
      if (routePolyline != null) 'routePolyline': routePolyline,
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
    String? routePolyline,
  }) {
    return DeliveryRoute(
      id: id ?? this.id,
      locations: locations ?? this.locations,
      routePoints: routePoints ?? this.routePoints,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      isOptimized: isOptimized ?? this.isOptimized,
      routePolyline: routePolyline ?? this.routePolyline,
    );
  }

  /// Gets the next uncompleted delivery location
  DeliveryLocation? get nextLocation {
    try {
      return locations.firstWhere((location) => !location.isCompleted);
    } catch (e) {
      return null;
    }
  }

  /// Number of completed deliveries in this route
  int get completedCount => locations.where((loc) => loc.isCompleted).length;

  /// Total potential earnings from this route
  double get totalEarnings => locations.fold(0.0, (sum, loc) => sum + loc.earning);

  /// Progress percentage (0.0 to 1.0)
  double get progress => locations.isEmpty ? 0.0 : completedCount / locations.length;

  /// Estimated time remaining based on progress
  Duration get estimatedTimeRemaining {
    final secondsRemaining = estimatedDuration.inSeconds * (1 - progress);
    return Duration(seconds: secondsRemaining.round());
  }

  /// Checks if all deliveries in this route are completed
  bool get isCompleted => locations.every((loc) => loc.isCompleted);

  /// Gets the current position index in the route
  int get currentPositionIndex {
    if (locations.isEmpty) return -1;
    final firstUncompleted = locations.indexWhere((loc) => !loc.isCompleted);
    return firstUncompleted == -1 ? locations.length - 1 : firstUncompleted;
  }

  /// Gets the bounds that contain all route points
  LatLngBounds get bounds {
    if (routePoints.isEmpty) {
      return LatLngBounds(
        northeast: const LatLng(0, 0),
        southwest: const LatLng(0, 0),
      );
    }

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (final point in routePoints) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return LatLngBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );
  }
}