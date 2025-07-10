import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery_location.dart';
import '../services/location_service.dart';

class NavigationService extends ChangeNotifier {
  static const String _googleMapsApiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  
  final LocationService _locationService;
  
  // Navigation state
  List<NavigationStep> _currentSteps = [];
  int _currentStepIndex = 0;
  DeliveryLocation? _currentDestination;
  bool _isNavigating = false;
  Timer? _navigationTimer;
  
  // Navigation configuration
  static const double _arrivalThresholdMeters = 30.0;
  static const double _stepCompletionThresholdMeters = 20.0;
  static const Duration _navigationUpdateInterval = Duration(seconds: 5);
  
  // Getters
  List<NavigationStep> get currentSteps => List.unmodifiable(_currentSteps);
  int get currentStepIndex => _currentStepIndex;
  NavigationStep? get currentStep => _currentStepIndex < _currentSteps.length 
      ? _currentSteps[_currentStepIndex] 
      : null;
  DeliveryLocation? get currentDestination => _currentDestination;
  bool get isNavigating => _isNavigating;
  bool get hasArrivedAtDestination => _isNavigating && _currentStepIndex >= _currentSteps.length;
  
  NavigationService(this._locationService);
  
  // Start navigation to a specific delivery location
  Future<void> startNavigation(DeliveryLocation destination) async {
    LatLng? currentLocation = _locationService.currentLocation;
    if (currentLocation == null) {
      throw Exception('Current location not available');
    }
    
    _currentDestination = destination;
    _isNavigating = true;
    _currentStepIndex = 0;
    
    // Get turn-by-turn directions
    await _getDirections(currentLocation, destination.coordinates);
    
    // Start navigation monitoring
    _startNavigationMonitoring();
    
    notifyListeners();
  }
  
  // Stop navigation
  void stopNavigation() {
    _navigationTimer?.cancel();
    _isNavigating = false;
    _currentDestination = null;
    _currentSteps.clear();
    _currentStepIndex = 0;
    
    notifyListeners();
  }
  
  // Get turn-by-turn directions from Google Directions API
  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    final String url = '$_directionsBaseUrl?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_googleMapsApiKey'
        '&mode=driving'
        '&alternatives=false'
        '&language=en';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'] as List;
          
          _currentSteps.clear();
          
          for (var leg in legs) {
            final steps = leg['steps'] as List;
            
            for (var step in steps) {
              _currentSteps.add(NavigationStep.fromJson(step));
            }
          }
        } else {
          throw Exception('No route found: ${data['status']}');
        }
      } else {
        throw Exception('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting directions: $e');
      // Fallback: create simple navigation step
      _createFallbackNavigation(origin, destination);
    }
  }
  
  // Create fallback navigation when API fails
  void _createFallbackNavigation(LatLng origin, LatLng destination) {
    double distance = _calculateDistance(origin, destination);
    double bearing = _calculateBearing(origin, destination);
    
    String direction = _getDirectionFromBearing(bearing);
    
    _currentSteps = [
      NavigationStep(
        instruction: 'Head $direction toward ${_currentDestination?.name ?? "destination"}',
        distance: distance * 1000, // Convert to meters
        duration: Duration(minutes: (distance / 0.5).round()), // Assume 30 km/h
        startLocation: origin,
        endLocation: destination,
        maneuver: 'straight',
      ),
    ];
  }
  
  // Start monitoring navigation progress
  void _startNavigationMonitoring() {
    _navigationTimer = Timer.periodic(_navigationUpdateInterval, (_) {
      _updateNavigationProgress();
    });
  }
  
  // Update navigation progress based on current location
  void _updateNavigationProgress() {
    LatLng? currentLocation = _locationService.currentLocation;
    if (currentLocation == null || !_isNavigating) return;
    
    // Check if arrived at destination
    if (_currentDestination != null) {
      double distanceToDestination = _calculateDistance(
        currentLocation,
        _currentDestination!.coordinates,
      ) * 1000; // Convert to meters
      
      if (distanceToDestination <= _arrivalThresholdMeters) {
        _handleArrivalAtDestination();
        return;
      }
    }
    
    // Check if current step is completed
    if (_currentStepIndex < _currentSteps.length) {
      NavigationStep currentStep = _currentSteps[_currentStepIndex];
      double distanceToStepEnd = _calculateDistance(
        currentLocation,
        currentStep.endLocation,
      ) * 1000; // Convert to meters
      
      if (distanceToStepEnd <= _stepCompletionThresholdMeters) {
        _advanceToNextStep();
      }
    }
    
    notifyListeners();
  }
  
  // Handle arrival at destination
  void _handleArrivalAtDestination() {
    _isNavigating = false;
    _navigationTimer?.cancel();
    
    // Notify about arrival
    print('Arrived at ${_currentDestination?.name}');
    
    notifyListeners();
  }
  
  // Advance to next navigation step
  void _advanceToNextStep() {
    if (_currentStepIndex < _currentSteps.length - 1) {
      _currentStepIndex++;
      print('Advanced to step ${_currentStepIndex + 1}: ${currentStep?.instruction}');
    }
  }
  
  // Launch external navigation app
  Future<void> launchExternalNavigation(DeliveryLocation destination) async {
    LatLng? currentLocation = _locationService.currentLocation;
    
    // Try Google Maps first
    String googleMapsUrl = 'https://www.google.com/maps/dir/';
    
    if (currentLocation != null) {
      googleMapsUrl += '${currentLocation.latitude},${currentLocation.longitude}/';
    }
    
    googleMapsUrl += '${destination.coordinates.latitude},${destination.coordinates.longitude}';
    googleMapsUrl += '?mode=driving';
    
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      return;
    }
    
    // Fallback to Apple Maps on iOS
    String appleMapsUrl = 'https://maps.apple.com/?daddr=${destination.coordinates.latitude},${destination.coordinates.longitude}&dirflg=d';
    
    if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
      await launchUrl(Uri.parse(appleMapsUrl), mode: LaunchMode.externalApplication);
      return;
    }
    
    // Fallback to generic maps URL
    String genericUrl = 'geo:${destination.coordinates.latitude},${destination.coordinates.longitude}?q=${destination.coordinates.latitude},${destination.coordinates.longitude}(${destination.name})';
    
    if (await canLaunchUrl(Uri.parse(genericUrl))) {
      await launchUrl(Uri.parse(genericUrl), mode: LaunchMode.externalApplication);
    }
  }
  
  // Get remaining distance to destination
  double getRemainingDistance() {
    LatLng? currentLocation = _locationService.currentLocation;
    if (currentLocation == null || _currentDestination == null) return 0.0;
    
    return _calculateDistance(currentLocation, _currentDestination!.coordinates);
  }
  
  // Get estimated time to arrival
  Duration getEstimatedTimeToArrival() {
    double remainingDistance = getRemainingDistance();
    
    // Assume average speed of 25 km/h in urban areas
    double averageSpeedKmh = 25.0;
    double estimatedHours = remainingDistance / averageSpeedKmh;
    
    return Duration(milliseconds: (estimatedHours * 3600 * 1000).round());
  }
  
  // Get navigation summary
  NavigationSummary getNavigationSummary() {
    return NavigationSummary(
      isNavigating: _isNavigating,
      destination: _currentDestination,
      currentStep: currentStep,
      totalSteps: _currentSteps.length,
      currentStepIndex: _currentStepIndex,
      remainingDistance: getRemainingDistance(),
      estimatedTimeToArrival: getEstimatedTimeToArrival(),
    );
  }
  
  // Calculate distance between two points (in kilometers)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;
    
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
  
  // Calculate bearing between two points
  double _calculateBearing(LatLng point1, LatLng point2) {
    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);
    
    double y = math.sin(deltaLngRad) * math.cos(lat2Rad);
    double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);
    
    double bearing = math.atan2(y, x);
    return (bearing * (180 / math.pi) + 360) % 360;
  }
  
  // Get direction string from bearing
  String _getDirectionFromBearing(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'north';
    if (bearing >= 22.5 && bearing < 67.5) return 'northeast';
    if (bearing >= 67.5 && bearing < 112.5) return 'east';
    if (bearing >= 112.5 && bearing < 157.5) return 'southeast';
    if (bearing >= 157.5 && bearing < 202.5) return 'south';
    if (bearing >= 202.5 && bearing < 247.5) return 'southwest';
    if (bearing >= 247.5 && bearing < 292.5) return 'west';
    if (bearing >= 292.5 && bearing < 337.5) return 'northwest';
    return 'north';
  }
  
  @override
  void dispose() {
    stopNavigation();
    super.dispose();
  }
}

// Navigation step model
class NavigationStep {
  final String instruction;
  final double distance; // in meters
  final Duration duration;
  final LatLng startLocation;
  final LatLng endLocation;
  final String maneuver;
  final String? htmlInstructions;
  
  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.maneuver,
    this.htmlInstructions,
  });
  
  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      instruction: json['html_instructions'] ?? json['instructions'] ?? '',
      distance: (json['distance']['value'] as num).toDouble(),
      duration: Duration(seconds: json['duration']['value']),
      startLocation: LatLng(
        json['start_location']['lat'],
        json['start_location']['lng'],
      ),
      endLocation: LatLng(
        json['end_location']['lat'],
        json['end_location']['lng'],
      ),
      maneuver: json['maneuver'] ?? 'straight',
      htmlInstructions: json['html_instructions'],
    );
  }
  
  // Get clean instruction text (remove HTML tags)
  String get cleanInstruction {
    return instruction
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();
  }
  
  // Get distance in human-readable format
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
  
  // Get duration in human-readable format
  String get formattedDuration {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds} sec';
    } else {
      return '${duration.inMinutes} min';
    }
  }
  
  // Get maneuver icon
  String get maneuverIcon {
    switch (maneuver.toLowerCase()) {
      case 'turn-left':
        return '↰';
      case 'turn-right':
        return '↱';
      case 'turn-slight-left':
        return '↖';
      case 'turn-slight-right':
        return '↗';
      case 'turn-sharp-left':
        return '↙';
      case 'turn-sharp-right':
        return '↘';
      case 'uturn-left':
      case 'uturn-right':
        return '↶';
      case 'merge':
        return '⤴';
      case 'fork-left':
        return '↖';
      case 'fork-right':
        return '↗';
      case 'ferry':
        return '⛴';
      case 'roundabout-left':
      case 'roundabout-right':
        return '↻';
      default:
        return '↑';
    }
  }
}

// Navigation summary model
class NavigationSummary {
  final bool isNavigating;
  final DeliveryLocation? destination;
  final NavigationStep? currentStep;
  final int totalSteps;
  final int currentStepIndex;
  final double remainingDistance; // in kilometers
  final Duration estimatedTimeToArrival;
  
  NavigationSummary({
    required this.isNavigating,
    this.destination,
    this.currentStep,
    required this.totalSteps,
    required this.currentStepIndex,
    required this.remainingDistance,
    required this.estimatedTimeToArrival,
  });
  
  // Get progress percentage
  double get progressPercentage {
    if (totalSteps == 0) return 0.0;
    return (currentStepIndex / totalSteps) * 100;
  }
  
  // Get remaining steps count
  int get remainingSteps {
    return math.max(0, totalSteps - currentStepIndex);
  }
}

