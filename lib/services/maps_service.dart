import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import '../models/delivery_location.dart';
import '../models/delivery_route.dart';
import 'dart:math' as math;

class MapsService {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Google Maps API key - Replace with your actual API key
  static const String _googleMapsApiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';
  
  // Getters
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  
  // Set map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }
  
  // Get custom map style
  Future<String> getMapStyle() async {
    return await rootBundle.loadString('assets/map_styles/delivery_style.json');
  }
  
  // Create delivery markers with custom icons and numbering
  Future<void> createDeliveryMarkers(List<DeliveryLocation> locations) async {
    _markers.clear();
    
    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];
      
      // Create custom marker icon based on delivery status and type
      BitmapDescriptor markerIcon = await _createCustomMarker(
        location: location,
        sequenceNumber: i + 1,
      );
      
      _markers.add(
        Marker(
          markerId: MarkerId(location.id),
          position: location.coordinates,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${location.name}',
            snippet: '${location.customerName} - UGX ${location.earning}',
            onTap: () => _onMarkerInfoWindowTap(location),
          ),
          onTap: () => _onMarkerTap(location),
        ),
      );
    }
  }
  
  // Create custom marker with sequence number and status
  Future<BitmapDescriptor> _createCustomMarker({
    required DeliveryLocation location,
    required int sequenceNumber,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = 120.0;
    const double radius = size / 2;
    
    // Determine marker color based on status and type
    Color markerColor;
    if (location.isCompleted) {
      markerColor = Colors.green;
    } else if (location.isPickup) {
      markerColor = Colors.orange;
    } else {
      markerColor = Colors.blue;
    }
    
    // Draw outer circle (shadow)
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(
      const Offset(radius + 2, radius + 2),
      radius - 5,
      paint,
    );
    
    // Draw main circle
    paint.color = markerColor;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 5,
      paint,
    );
    
    // Draw inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 15,
      paint,
    );
    
    // Draw sequence number
    final textPainter = TextPainter(
      text: TextSpan(
        text: sequenceNumber.toString(),
        style: TextStyle(
          color: markerColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );
    
    // Add status icon
    if (location.isCompleted) {
      _drawCheckIcon(canvas, radius, Colors.green);
    } else if (location.isPickup) {
      _drawPickupIcon(canvas, radius, Colors.orange);
    }
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }
  
  // Draw check icon for completed deliveries
  void _drawCheckIcon(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final Path path = Path();
    path.moveTo(radius - 15, radius + 5);
    path.lineTo(radius - 5, radius + 15);
    path.lineTo(radius + 15, radius - 10);
    
    canvas.drawPath(path, paint);
  }
  
  // Draw pickup icon
  void _drawPickupIcon(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw simple box icon for pickup
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(radius, radius + 20),
        width: 20,
        height: 15,
      ),
      paint,
    );
  }
  
  // Update driver's current location marker
  Future<void> updateDriverLocation(LatLng location) async {
    // Remove existing driver marker
    _markers.removeWhere((marker) => marker.markerId.value == 'driver_location');
    
    // Create driver marker
    BitmapDescriptor driverIcon = await _createDriverMarker();
    
    _markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: location,
        icon: driverIcon,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Delivery in progress',
        ),
        anchor: const Offset(0.5, 0.5),
      ),
    );
  }
  
  // Create custom driver marker
  Future<BitmapDescriptor> _createDriverMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = 80.0;
    const double radius = size / 2;
    
    // Draw outer circle (shadow)
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(
      const Offset(radius + 1, radius + 1),
      radius - 3,
      paint,
    );
    
    // Draw main circle
    paint.color = Colors.red;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 3,
      paint,
    );
    
    // Draw inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 8,
      paint,
    );
    
    // Draw motorcycle icon (simplified)
    paint.color = Colors.red;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    
    // Simple motorcycle representation
    canvas.drawCircle(Offset(radius - 8, radius + 5), 6, paint);
    canvas.drawCircle(Offset(radius + 8, radius + 5), 6, paint);
    canvas.drawLine(
      Offset(radius - 2, radius + 5),
      Offset(radius + 2, radius + 5),
      paint,
    );
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }
  
  // Create route polyline using Google Directions API
  Future<void> createRoutePolyline(List<LatLng> routePoints) async {
    if (routePoints.length < 2) return;
    
    _polylines.clear();
    
    // Create main route polyline
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
        patterns: [], // Solid line
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    );
    
    // Add dotted line for completed segments
    // This would be implemented based on delivery progress
  }
  
  // Get route from Google Directions API
  Future<List<LatLng>> getRouteFromDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    String waypointsStr = '';
    if (waypoints != null && waypoints.isNotEmpty) {
      waypointsStr = '&waypoints=' + 
          waypoints.map((point) => '${point.latitude},${point.longitude}').join('|');
    }
    
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '$waypointsStr'
        '&key=$_googleMapsApiKey'
        '&mode=driving'
        '&optimize=true'; // This optimizes waypoint order
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = route['overview_polyline']['points'];
          
          // Decode polyline
          List<List<num>> decodedPoints = decodePolyline(polylinePoints);
          
          return decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();
        }
      }
    } catch (e) {
      print('Error getting route: $e');
    }
    
    return [];
  }
  
  // Animate camera to show all markers
  Future<void> animateToShowAllMarkers() async {
    if (_mapController == null || _markers.isEmpty) return;
    
    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;
    
    for (Marker marker in _markers) {
      minLat = math.min(minLat, marker.position.latitude);
      maxLat = math.max(maxLat, marker.position.latitude);
      minLng = math.min(minLng, marker.position.longitude);
      maxLng = math.max(maxLng, marker.position.longitude);
    }
    
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        100.0, // padding
      ),
    );
  }
  
  // Animate camera to specific location
  Future<void> animateToLocation(LatLng location, {double zoom = 16.0}) async {
    if (_mapController == null) return;
    
    await _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: zoom,
        ),
      ),
    );
  }
  
  // Handle marker tap
  void _onMarkerTap(DeliveryLocation location) {
    // This can be used to show additional information or actions
    print('Marker tapped: ${location.name}');
  }
  
  // Handle marker info window tap
  void _onMarkerInfoWindowTap(DeliveryLocation location) {
    // This can be used to navigate to detailed view or call customer
    print('Info window tapped: ${location.name}');
  }
  
  // Clear all markers and polylines
  void clearMap() {
    _markers.clear();
    _polylines.clear();
  }
  
  // Calculate distance between two points (in kilometers)
  double calculateDistance(LatLng point1, LatLng point2) {
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
}


