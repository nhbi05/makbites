import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_location.dart';
import '../models/delivery_route.dart';
import 'dart:typed_data';
import 'dart:math' as math;


class RouteVisualizationService {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  
  // Route visualization configuration
  static const double _routeWidth = 6.0;
  static const double _completedRouteWidth = 4.0;
  static const List<Color> _routeColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
  ];
  
  // Getters
  Set<Polyline> get polylines => _polylines;
  Set<Marker> get markers => _markers;
  
  // Set map controller
  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }
  
  // Visualize complete delivery route with numbered sequence
  Future<void> visualizeDeliveryRoute({
    required DeliveryRoute route,
    required LatLng driverLocation,
    int? currentLocationIndex,
  }) async {
    _polylines.clear();
    _markers.clear();
    
    // Create route polylines
    await _createRoutePolylines(route, currentLocationIndex);
    
    // Create numbered markers for delivery locations
    await _createNumberedMarkers(route.locations, currentLocationIndex);
    
    // Create driver marker
    await _createDriverMarker(driverLocation);
    
    // Create start marker
    if (route.routePoints.isNotEmpty) {
      await _createStartMarker(route.routePoints.first);
    }
  }
  
  // Create route polylines with different styles for completed/remaining segments
  Future<void> _createRoutePolylines(DeliveryRoute route, int? currentLocationIndex) async {
    if (route.routePoints.length < 2) return;
    
    List<LatLng> routePoints = route.routePoints;
    
    if (currentLocationIndex != null && currentLocationIndex > 0) {
      // Split route into completed and remaining segments
      int splitIndex = _findSplitIndex(routePoints, route.locations, currentLocationIndex);
      
      if (splitIndex > 0) {
        // Completed segment (green, dashed)
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('completed_route'),
            points: routePoints.sublist(0, splitIndex + 1),
            color: const Color(0xFF4CAF50),
            width: _completedRouteWidth.toInt(),
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      }
      
      if (splitIndex < routePoints.length - 1) {
        // Remaining segment (blue, solid)
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('remaining_route'),
            points: routePoints.sublist(splitIndex),
            color: const Color(0xFF2196F3),
            width: _routeWidth.toInt(),
            patterns: [],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      }
    } else {
      // Full route (blue, solid)
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('full_route'),
          points: routePoints,
          color: const Color(0xFF2196F3),
          width: _routeWidth.toInt(),
          patterns: [],
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }
    
    // Add route direction arrows
    await _addRouteDirectionArrows(routePoints);
  }
  
  // Find the split index in route points based on current location
  int _findSplitIndex(List<LatLng> routePoints, List<DeliveryLocation> locations, int currentLocationIndex) {
    if (currentLocationIndex >= locations.length) return routePoints.length - 1;
    
    LatLng currentLocation = locations[currentLocationIndex].coordinates;
    
    // Find the closest point in the route to the current location
    double minDistance = double.infinity;
    int closestIndex = 0;
    
    for (int i = 0; i < routePoints.length; i++) {
      double distance = _calculateDistance(routePoints[i], currentLocation);
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    return closestIndex;
  }
  
  // Add direction arrows along the route
  Future<void> _addRouteDirectionArrows(List<LatLng> routePoints) async {
    if (routePoints.length < 2) return;
    
    const int arrowInterval = 10; // Add arrow every 10 points
    
    for (int i = arrowInterval; i < routePoints.length; i += arrowInterval) {
      LatLng point1 = routePoints[i - 1];
      LatLng point2 = routePoints[i];
      
      // Calculate bearing
      double bearing = _calculateBearing(point1, point2);
      
      // Create arrow marker
      BitmapDescriptor arrowIcon = await _createArrowMarker(bearing);
      
      _markers.add(
        Marker(
          markerId: MarkerId('arrow_$i'),
          position: point2,
          icon: arrowIcon,
          anchor: const Offset(0.5, 0.5),
          zIndex: 1,
        ),
      );
    }
  }
  
  // Create numbered markers for delivery locations
  Future<void> _createNumberedMarkers(List<DeliveryLocation> locations, int? currentLocationIndex) async {
    for (int i = 0; i < locations.length; i++) {
      DeliveryLocation location = locations[i];
      bool isNext = currentLocationIndex != null && i == currentLocationIndex;
      bool isCompleted = currentLocationIndex != null && i < currentLocationIndex;
      
      BitmapDescriptor markerIcon = await _createNumberedMarker(
        sequenceNumber: i + 1,
        location: location,
        isNext: isNext,
        isCompleted: isCompleted,
      );
      
      _markers.add(
        Marker(
          markerId: MarkerId('delivery_${location.id}'),
          position: location.coordinates,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: '${i + 1}. ${location.name}',
            snippet: _getMarkerSnippet(location, i, currentLocationIndex),
          ),
          zIndex: 10,
        ),
      );
    }
  }
  
  // Get marker snippet text
  String _getMarkerSnippet(DeliveryLocation location, int index, int? currentLocationIndex) {
    String snippet = '${location.customerName} - UGX ${location.earning}';
    
    if (currentLocationIndex != null) {
      if (index < currentLocationIndex) {
        snippet += ' ✓ Completed';
      } else if (index == currentLocationIndex) {
        snippet += ' → Next Stop';
      } else {
        snippet += ' • Upcoming';
      }
    }
    
    if (location.estimatedTime != null) {
      String timeStr = _formatTime(location.estimatedTime!);
      snippet += '\nETA: $timeStr';
    }
    
    return snippet;
  }
  
  // Create numbered marker with status indication
  Future<BitmapDescriptor> _createNumberedMarker({
    required int sequenceNumber,
    required DeliveryLocation location,
    bool isNext = false,
    bool isCompleted = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = 120.0;
    const double radius = size / 2;
    
    // Determine colors based on status
    Color primaryColor;
    Color textColor;
    
    if (isCompleted) {
      primaryColor = const Color(0xFF4CAF50); // Green
      textColor = Colors.white;
    } else if (isNext) {
      primaryColor = const Color(0xFFFF9800); // Orange
      textColor = Colors.white;
    } else if (location.isPickup) {
      primaryColor = const Color(0xFF2196F3); // Blue
      textColor = Colors.white;
    } else {
      primaryColor = const Color(0xFF9C27B0); // Purple
      textColor = Colors.white;
    }
    
    // Draw shadow
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(
      const Offset(radius + 3, radius + 3),
      radius - 8,
      paint,
    );
    
    // Draw main circle
    paint.color = primaryColor;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 8,
      paint,
    );
    
    // Draw inner circle for number
    paint.color = Colors.white;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 18,
      paint,
    );
    
    // Draw sequence number
    final textPainter = TextPainter(
      text: TextSpan(
        text: sequenceNumber.toString(),
        style: TextStyle(
          color: primaryColor,
          fontSize: 28,
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
    
    // Draw status indicator
    if (isCompleted) {
      _drawCheckmark(canvas, radius, Colors.white);
    } else if (isNext) {
      _drawPulseRing(canvas, radius, primaryColor);
    }
    
    // Draw type indicator
    if (location.isPickup) {
      _drawPickupIndicator(canvas, radius, Colors.white);
    } else {
      _drawDropoffIndicator(canvas, radius, Colors.white);
    }
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
  
  // Create driver marker
  Future<void> _createDriverMarker(LatLng location) async {
    BitmapDescriptor driverIcon = await _createDriverIcon();
    
    _markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: location,
        icon: driverIcon,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Delivery in progress',
        ),
        zIndex: 15,
      ),
    );
  }
  
  // Create start marker
  Future<void> _createStartMarker(LatLng location) async {
    BitmapDescriptor startIcon = await _createStartIcon();
    
    _markers.add(
      Marker(
        markerId: const MarkerId('start_location'),
        position: location,
        icon: startIcon,
        infoWindow: const InfoWindow(
          title: 'Start Location',
          snippet: 'Route begins here',
        ),
        zIndex: 5,
      ),
    );
  }
  
  // Create driver icon
  Future<BitmapDescriptor> _createDriverIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = 80.0;
    const double radius = size / 2;
    
    // Draw shadow
    paint.color = Colors.black.withOpacity(0.4);
    canvas.drawCircle(
      const Offset(radius + 2, radius + 2),
      radius - 5,
      paint,
    );
    
    // Draw main circle
    paint.color = const Color(0xFFFF5722);
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 5,
      paint,
    );
    
    // Draw inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 12,
      paint,
    );
    
    // Draw motorcycle icon
    paint.color = const Color(0xFFFF5722);
    paint.strokeWidth = 3;
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
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
  
  // Create start icon
  Future<BitmapDescriptor> _createStartIcon() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = 100.0;
    const double radius = size / 2;
    
    // Draw shadow
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(
      const Offset(radius + 2, radius + 2),
      radius - 5,
      paint,
    );
    
    // Draw main circle
    paint.color = const Color(0xFF4CAF50);
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
    
    // Draw "S" for start
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'S',
        style: TextStyle(
          color: Color(0xFF4CAF50),
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
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
  
  // Create arrow marker for route direction
  Future<BitmapDescriptor> _createArrowMarker(double bearing) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = 40.0;
    const double radius = size / 2;
    
    // Save canvas state for rotation
    canvas.save();
    canvas.translate(radius, radius);
    canvas.rotate(bearing * (3.14159 / 180));
    canvas.translate(-radius, -radius);
    
    // Draw arrow
    paint.color = const Color(0xFF2196F3);
    paint.style = PaintingStyle.fill;
    
    final Path arrowPath = Path();
    arrowPath.moveTo(radius, radius - 12);
    arrowPath.lineTo(radius - 8, radius + 8);
    arrowPath.lineTo(radius, radius + 4);
    arrowPath.lineTo(radius + 8, radius + 8);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, paint);
    
    // Restore canvas state
    canvas.restore();
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
  
  // Draw checkmark for completed deliveries
  void _drawCheckmark(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final Path checkPath = Path();
    checkPath.moveTo(radius - 12, radius + 25);
    checkPath.lineTo(radius - 4, radius + 33);
    checkPath.lineTo(radius + 12, radius + 18);
    
    canvas.drawPath(checkPath, paint);
  }
  
  // Draw pulse ring for next delivery
  void _drawPulseRing(Canvas canvas, double radius, Color color) {
    final Paint pulsePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 5,
      pulsePaint,
    );
  }
  
  // Draw pickup indicator
  void _drawPickupIndicator(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw box
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(radius, radius + 25),
        width: 12,
        height: 8,
      ),
      paint,
    );
  }
  
  // Draw dropoff indicator
  void _drawDropoffIndicator(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw house
    canvas.drawRect(
      Rect.fromLTWH(radius - 6, radius + 20, 12, 8),
      paint,
    );
    
    // Draw roof
    final Path roofPath = Path();
    roofPath.moveTo(radius - 8, radius + 20);
    roofPath.lineTo(radius, radius + 12);
    roofPath.lineTo(radius + 8, radius + 20);
    
    canvas.drawPath(roofPath, paint);
  }
  
  // Animate camera to show entire route
  Future<void> showCompleteRoute() async {
    if (_mapController == null || _markers.isEmpty) return;
    
    List<LatLng> allPositions = _markers.map((marker) => marker.position).toList();
    
    if (allPositions.isEmpty) return;
    
    double minLat = allPositions.first.latitude;
    double maxLat = allPositions.first.latitude;
    double minLng = allPositions.first.longitude;
    double maxLng = allPositions.first.longitude;
    
    for (LatLng position in allPositions) {
      minLat = math.min(minLat, position.latitude);
      maxLat = math.max(maxLat, position.latitude);
      minLng = math.min(minLng, position.longitude);
      maxLng = math.max(maxLng, position.longitude);
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
  
  // Animate to specific delivery location
  Future<void> focusOnDelivery(int index) async {
    if (_mapController == null || index >= _markers.length) return;
    
    List<Marker> deliveryMarkers = _markers
        .where((marker) => marker.markerId.value.startsWith('delivery_'))
        .toList();
    
    if (index < deliveryMarkers.length) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: deliveryMarkers[index].position,
            zoom: 16.0,
          ),
        ),
      );
    }
  }
  
  // Calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;
    
    double lat1Rad = point1.latitude * (3.14159 / 180);
    double lat2Rad = point2.latitude * (3.14159 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159 / 180);
    
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  // Calculate bearing between two points
  double _calculateBearing(LatLng point1, LatLng point2) {
    double lat1Rad = point1.latitude * (3.14159 / 180);
    double lat2Rad = point2.latitude * (3.14159 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159 / 180);
    
    double y = math.sin(deltaLngRad) * math.cos(lat2Rad);
    double x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);
    
    double bearing = math.atan2(y, x);
    return (bearing * (180 / 3.14159) + 360) % 360;
  }
  
  // Format time for display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  
  // Clear all visualizations
  void clearVisualization() {
    _polylines.clear();
    _markers.clear();
  }
}


