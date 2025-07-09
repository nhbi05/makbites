import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_location.dart';
import '../services/location_service.dart';

class RealTimeTrackingService extends ChangeNotifier {
  final LocationService _locationService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Timer? _trackingTimer;
  Timer? _statusUpdateTimer;
  String? _currentDeliveryId;
  bool _isTracking = false;
  
  // Tracking configuration
  static const Duration _locationUpdateInterval = Duration(seconds: 10);
  static const Duration _statusUpdateInterval = Duration(seconds: 30);
  static const double _arrivalThresholdMeters = 50.0;
  
  // Current tracking state
  LatLng? _lastKnownLocation;
  double _totalDistanceTraveled = 0.0;
  DateTime? _trackingStartTime;
  List<LatLng> _trackingPath = [];
  
  // Getters
  bool get isTracking => _isTracking;
  String? get currentDeliveryId => _currentDeliveryId;
  double get totalDistanceTraveled => _totalDistanceTraveled;
  List<LatLng> get trackingPath => List.unmodifiable(_trackingPath);
  Duration? get trackingDuration {
    if (_trackingStartTime == null) return null;
    return DateTime.now().difference(_trackingStartTime!);
  }
  
  RealTimeTrackingService(this._locationService);
  
  // Start tracking for a delivery route
  Future<void> startTracking(String deliveryId) async {
    if (_isTracking) {
      await stopTracking();
    }
    
    _currentDeliveryId = deliveryId;
    _isTracking = true;
    _trackingStartTime = DateTime.now();
    _totalDistanceTraveled = 0.0;
    _trackingPath.clear();
    
    // Initialize with current location
    LatLng? currentLocation = _locationService.currentLocation;
    if (currentLocation != null) {
      _lastKnownLocation = currentLocation;
      _trackingPath.add(currentLocation);
      
      // Update initial location in Firestore
      await _updateLocationInFirestore(currentLocation);
    }
    
    // Start periodic location updates
    _trackingTimer = Timer.periodic(_locationUpdateInterval, (_) {
      _updateTrackingData();
    });
    
    // Start periodic status updates
    _statusUpdateTimer = Timer.periodic(_statusUpdateInterval, (_) {
      _updateDeliveryStatus();
    });
    
    notifyListeners();
  }
  
  // Stop tracking
  Future<void> stopTracking() async {
    _trackingTimer?.cancel();
    _statusUpdateTimer?.cancel();
    
    if (_isTracking && _currentDeliveryId != null) {
      // Final status update
      await _updateDeliveryStatus(isFinal: true);
    }
    
    _isTracking = false;
    _currentDeliveryId = null;
    _trackingStartTime = null;
    
    notifyListeners();
  }
  
  // Update tracking data with current location
  void _updateTrackingData() {
    LatLng? currentLocation = _locationService.currentLocation;
    if (currentLocation == null) return;
    
    // Calculate distance traveled since last update
    if (_lastKnownLocation != null) {
      double distance = _calculateDistance(_lastKnownLocation!, currentLocation);
      _totalDistanceTraveled += distance;
    }
    
    // Add to tracking path
    _trackingPath.add(currentLocation);
    _lastKnownLocation = currentLocation;
    
    // Update location in Firestore
    _updateLocationInFirestore(currentLocation);
    
    notifyListeners();
  }
  
  // Update location in Firestore
  Future<void> _updateLocationInFirestore(LatLng location) async {
    if (_currentDeliveryId == null) return;
    
    try {
      await _firestore
          .collection('delivery_tracking')
          .doc(_currentDeliveryId)
          .set({
        'driverId': 'current_driver_id', // Replace with actual driver ID
        'currentLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': _isTracking,
        'totalDistance': _totalDistanceTraveled,
        'trackingPath': _trackingPath.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }
  
  // Update delivery status
  Future<void> _updateDeliveryStatus({bool isFinal = false}) async {
    if (_currentDeliveryId == null) return;
    
    try {
      Map<String, dynamic> statusData = {
        'lastStatusUpdate': FieldValue.serverTimestamp(),
        'totalDistance': _totalDistanceTraveled,
        'trackingDuration': trackingDuration?.inSeconds ?? 0,
        'isTracking': _isTracking && !isFinal,
      };
      
      if (isFinal) {
        statusData['completedAt'] = FieldValue.serverTimestamp();
        statusData['finalDistance'] = _totalDistanceTraveled;
        statusData['finalDuration'] = trackingDuration?.inSeconds ?? 0;
      }
      
      await _firestore
          .collection('deliveries')
          .doc(_currentDeliveryId)
          .update(statusData);
    } catch (e) {
      print('Error updating delivery status: $e');
    }
  }
  
  // Check if driver has arrived at a location
  bool hasArrivedAt(LatLng destination) {
    LatLng? currentLocation = _locationService.currentLocation;
    if (currentLocation == null) return false;
    
    double distance = _calculateDistance(currentLocation, destination);
    return distance <= _arrivalThresholdMeters;
  }
  
  // Mark delivery location as completed
  Future<void> markLocationCompleted(String locationId, LatLng location) async {
    if (_currentDeliveryId == null) return;
    
    try {
      // Update the specific location status
      await _firestore
          .collection('deliveries')
          .doc(_currentDeliveryId)
          .collection('locations')
          .doc(locationId)
          .update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'completedLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
      });
      
      // Update main delivery document
      await _firestore
          .collection('deliveries')
          .doc(_currentDeliveryId)
          .update({
        'lastLocationCompleted': locationId,
        'lastCompletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking location as completed: $e');
    }
  }
  
  // Get estimated arrival time for a location
  Future<DateTime?> getEstimatedArrival(LatLng destination) async {
    LatLng? currentLocation = _locationService.currentLocation;
    if (currentLocation == null) return null;
    
    double distance = _calculateDistance(currentLocation, destination);
    
    // Calculate estimated time based on average speed
    // Assuming average delivery speed of 25 km/h in urban areas
    double averageSpeedKmh = 25.0;
    double estimatedHours = distance / averageSpeedKmh;
    
    return DateTime.now().add(Duration(
      milliseconds: (estimatedHours * 3600 * 1000).round(),
    ));
  }
  
  // Get real-time delivery updates stream
  Stream<DocumentSnapshot> getDeliveryUpdatesStream(String deliveryId) {
    return _firestore
        .collection('delivery_tracking')
        .doc(deliveryId)
        .snapshots();
  }
  
  // Get delivery locations stream
  Stream<QuerySnapshot> getDeliveryLocationsStream(String deliveryId) {
    return _firestore
        .collection('deliveries')
        .doc(deliveryId)
        .collection('locations')
        .orderBy('sequenceNumber')
        .snapshots();
  }
  
  // Calculate distance between two points in kilometers
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);
    
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  // Get tracking statistics
  Map<String, dynamic> getTrackingStats() {
    return {
      'isTracking': _isTracking,
      'deliveryId': _currentDeliveryId,
      'totalDistance': _totalDistanceTraveled,
      'duration': trackingDuration?.inMinutes ?? 0,
      'pathPoints': _trackingPath.length,
      'averageSpeed': _calculateAverageSpeed(),
    };
  }
  
  // Calculate average speed in km/h
  double _calculateAverageSpeed() {
    if (_trackingStartTime == null || _totalDistanceTraveled == 0) return 0.0;
    
    Duration elapsed = DateTime.now().difference(_trackingStartTime!);
    double hoursElapsed = elapsed.inMilliseconds / (1000 * 60 * 60);
    
    return hoursElapsed > 0 ? _totalDistanceTraveled / hoursElapsed : 0.0;
  }
  
  // Send delivery notification to customer
  Future<void> sendDeliveryNotification({
    required String customerId,
    required String message,
    required String type, // 'on_way', 'arrived', 'completed'
  }) async {
    if (_currentDeliveryId == null) return;
    
    try {
      await _firestore.collection('notifications').add({
        'customerId': customerId,
        'deliveryId': _currentDeliveryId,
        'driverId': 'current_driver_id', // Replace with actual driver ID
        'type': type,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
  
  // Pause tracking (for breaks, etc.)
  void pauseTracking() {
    _trackingTimer?.cancel();
    _statusUpdateTimer?.cancel();
    notifyListeners();
  }
  
  // Resume tracking
  void resumeTracking() {
    if (!_isTracking || _currentDeliveryId == null) return;
    
    _trackingTimer = Timer.periodic(_locationUpdateInterval, (_) {
      _updateTrackingData();
    });
    
    _statusUpdateTimer = Timer.periodic(_statusUpdateInterval, (_) {
      _updateDeliveryStatus();
    });
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

