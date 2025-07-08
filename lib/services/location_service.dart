import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;
  bool _isInitialized = false;
  String _statusMessage = '';
  
  // Location settings
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
    timeLimit: Duration(seconds: 30),
  );
  
  // Getters
  Position? get currentPosition => _currentPosition;
  LatLng? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;
  String get statusMessage => _statusMessage;
  
  // Initialize location service
  Future<bool> initialize() async {
    try {
      _updateStatus('Checking location permissions...');
      
      // Check and request location permissions
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        _updateStatus('Location permission denied');
        return false;
      }
      
      _updateStatus('Checking location services...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _updateStatus('Location services are disabled');
        return false;
      }
      
      _updateStatus('Getting initial location...');
      
      // Get initial location
      Position? position = await getCurrentLocation();
      if (position == null) {
        _updateStatus('Failed to get initial location');
        return false;
      }
      
      _isInitialized = true;
      _updateStatus('Location service initialized');
      notifyListeners();
      
      return true;
    } catch (e) {
      _updateStatus('Location initialization failed: $e');
      return false;
    }
  }
  
  // Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    // Check current permission status
    PermissionStatus permission = await Permission.location.status;
    
    if (permission.isDenied) {
      // Request permission
      permission = await Permission.location.request();
    }
    
    if (permission.isPermanentlyDenied) {
      // Open app settings if permanently denied
      await openAppSettings();
      return false;
    }
    
    return permission.isGranted;
  }
  
  // Request location permission (public method for UI)
  Future<bool> requestLocationPermission() async {
    return await _checkLocationPermission();
  }
  
  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      _currentPosition = position;
      _currentLocation = LatLng(position.latitude, position.longitude);
      
      notifyListeners();
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }
  
  // Start location tracking
  Future<void> startTracking() async {
    if (_isTracking) return;
    
    try {
      _updateStatus('Starting location tracking...');
      
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _currentLocation = LatLng(position.latitude, position.longitude);
          
          _updateStatus('Location updated: ${position.accuracy.toStringAsFixed(1)}m accuracy');
          notifyListeners();
        },
        onError: (error) {
          _updateStatus('Location tracking error: $error');
          print('Location tracking error: $error');
        },
      );
      
      _isTracking = true;
      _updateStatus('Location tracking started');
      notifyListeners();
    } catch (e) {
      _updateStatus('Failed to start location tracking: $e');
      print('Error starting location tracking: $e');
    }
  }
  
  // Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    
    _updateStatus('Location tracking stopped');
    notifyListeners();
  }
  
  // Calculate distance to a destination
  double calculateDistanceTo(LatLng destination) {
    if (_currentLocation == null) return 0.0;
    
    return Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      destination.latitude,
      destination.longitude,
    ) / 1000; // Convert to kilometers
  }
  
  // Calculate bearing to a destination
  double calculateBearingTo(LatLng destination) {
    if (_currentLocation == null) return 0.0;
    
    return Geolocator.bearingBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      destination.latitude,
      destination.longitude,
    );
  }
  
  // Check if user is near a location (within specified radius in meters)
  bool isNearLocation(LatLng location, {double radiusInMeters = 50.0}) {
    if (_currentLocation == null) return false;
    
    double distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      location.latitude,
      location.longitude,
    );
    
    return distance <= radiusInMeters;
  }
  
  // Get location accuracy description
  String getAccuracyDescription() {
    if (_currentPosition == null) return 'Unknown';
    
    double accuracy = _currentPosition!.accuracy;
    
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 20) return 'Fair';
    return 'Poor';
  }
  
  // Update status message
  void _updateStatus(String message) {
    _statusMessage = message;
    print('LocationService: $message');
  }
  
  // Get location update frequency
  Duration get updateFrequency {
    return const Duration(seconds: 5); // Update every 5 seconds
  }
  
  // Check if location is stale (hasn't been updated recently)
  bool get isLocationStale {
    if (_currentPosition == null) return true;
    
    DateTime now = DateTime.now();
    DateTime positionTime = _currentPosition!.timestamp;
    
    return now.difference(positionTime).inMinutes > 2; // Stale after 2 minutes
  }
  
  // Force location refresh
  Future<void> refreshLocation() async {
    _updateStatus('Refreshing location...');
    await getCurrentLocation();
  }
  
  // Get location as formatted string
  String getLocationString() {
    if (_currentLocation == null) return 'Location unavailable';
    
    return '${_currentLocation!.latitude.toStringAsFixed(6)}, '
           '${_currentLocation!.longitude.toStringAsFixed(6)}';
  }
  
  // Simulate location for testing (only use in development)
  void simulateLocation(LatLng location) {
    if (kDebugMode) {
      _currentLocation = location;
      _currentPosition = Position(
        latitude: location.latitude,
        longitude: location.longitude,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      
      _updateStatus('Simulated location: ${getLocationString()}');
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

