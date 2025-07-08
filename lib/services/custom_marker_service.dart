import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_location.dart';

class CustomMarkerService {
  static const double _markerSize = 120.0;
  static const double _driverMarkerSize = 80.0;
  
  // Create numbered delivery marker with status indication
  static Future<BitmapDescriptor> createDeliveryMarker({
    required DeliveryLocation location,
    required int sequenceNumber,
    bool isNext = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = _markerSize;
    const double radius = size / 2;
    
    // Determine marker colors based on status and type
    Color primaryColor;
    Color accentColor;
    
    if (location.isCompleted) {
      primaryColor = const Color(0xFF4CAF50); // Green
      accentColor = const Color(0xFF2E7D32);
    } else if (isNext) {
      primaryColor = const Color(0xFFFF9800); // Orange for next delivery
      accentColor = const Color(0xFFE65100);
    } else if (location.isPickup) {
      primaryColor = const Color(0xFF2196F3); // Blue for pickup
      accentColor = const Color(0xFF1565C0);
    } else {
      primaryColor = const Color(0xFF9C27B0); // Purple for dropoff
      accentColor = const Color(0xFF6A1B9A);
    }
    
    // Draw shadow
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(
      const Offset(radius + 3, radius + 3),
      radius - 8,
      paint,
    );
    
    // Draw outer ring
    paint.color = accentColor;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 8,
      paint,
    );
    
    // Draw main circle
    paint.color = primaryColor;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 12,
      paint,
    );
    
    // Draw inner white circle for number
    paint.color = Colors.white;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 20,
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
          fontFamily: 'Roboto',
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
    if (location.isCompleted) {
      _drawCompletedIcon(canvas, radius, Colors.white);
    } else if (location.isPickup) {
      _drawPickupIcon(canvas, radius, Colors.white);
    } else {
      _drawDropoffIcon(canvas, radius, Colors.white);
    }
    
    // Add pulsing effect for next delivery
    if (isNext && !location.isCompleted) {
      _drawPulseEffect(canvas, radius, primaryColor);
    }
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }
  
  // Create driver location marker
  static Future<BitmapDescriptor> createDriverMarker({
    double heading = 0.0,
    bool isMoving = false,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = _driverMarkerSize;
    const double radius = size / 2;
    
    // Save canvas state for rotation
    canvas.save();
    canvas.translate(radius, radius);
    canvas.rotate(heading * (3.14159 / 180)); // Convert degrees to radians
    canvas.translate(-radius, -radius);
    
    // Draw shadow
    paint.color = Colors.black.withOpacity(0.4);
    canvas.drawCircle(
      const Offset(radius + 2, radius + 2),
      radius - 5,
      paint,
    );
    
    // Draw outer circle
    paint.color = isMoving ? const Color(0xFF4CAF50) : const Color(0xFFFF5722);
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 5,
      paint,
    );
    
    // Draw inner circle
    paint.color = Colors.white;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 10,
      paint,
    );
    
    // Draw direction arrow
    paint.color = isMoving ? const Color(0xFF4CAF50) : const Color(0xFFFF5722);
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    
    final Path arrowPath = Path();
    arrowPath.moveTo(radius, radius - 12);
    arrowPath.lineTo(radius - 8, radius + 8);
    arrowPath.lineTo(radius, radius + 4);
    arrowPath.lineTo(radius + 8, radius + 8);
    arrowPath.close();
    
    paint.style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, paint);
    
    // Restore canvas state
    canvas.restore();
    
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }
  
  // Create start location marker
  static Future<BitmapDescriptor> createStartMarker() async {
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
      radius - 12,
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
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }
  
  // Draw completed checkmark icon
  static void _drawCompletedIcon(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final Path checkPath = Path();
    checkPath.moveTo(radius - 12, radius + 15);
    checkPath.lineTo(radius - 4, radius + 23);
    checkPath.lineTo(radius + 12, radius + 8);
    
    canvas.drawPath(checkPath, paint);
  }
  
  // Draw pickup box icon
  static void _drawPickupIcon(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw box
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(radius, radius + 18),
        width: 18,
        height: 12,
      ),
      paint,
    );
    
    // Draw handle
    paint.strokeWidth = 2;
    canvas.drawLine(
      Offset(radius - 6, radius + 12),
      Offset(radius + 6, radius + 12),
      paint,
    );
  }
  
  // Draw dropoff house icon
  static void _drawDropoffIcon(Canvas canvas, double radius, Color color) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw house base
    canvas.drawRect(
      Rect.fromLTWH(radius - 8, radius + 12, 16, 12),
      paint,
    );
    
    // Draw roof
    final Path roofPath = Path();
    roofPath.moveTo(radius - 10, radius + 12);
    roofPath.lineTo(radius, radius + 2);
    roofPath.lineTo(radius + 10, radius + 12);
    
    canvas.drawPath(roofPath, paint);
    
    // Draw door
    paint.strokeWidth = 2;
    canvas.drawRect(
      Rect.fromLTWH(radius - 3, radius + 16, 6, 8),
      paint,
    );
  }
  
  // Draw pulse effect for next delivery
  static void _drawPulseEffect(Canvas canvas, double radius, Color color) {
    final Paint pulsePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    // Draw outer pulse ring
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 5,
      pulsePaint,
    );
    
    // Draw inner pulse ring
    pulsePaint.color = color.withOpacity(0.5);
    pulsePaint.strokeWidth = 2;
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 15,
      pulsePaint,
    );
  }
  
  // Create cluster marker for multiple nearby deliveries
  static Future<BitmapDescriptor> createClusterMarker({
    required int count,
    required Color color,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..isAntiAlias = true;
    
    const double size = 80.0;
    const double radius = size / 2;
    
    // Draw shadow
    paint.color = Colors.black.withOpacity(0.3);
    canvas.drawCircle(
      const Offset(radius + 2, radius + 2),
      radius - 5,
      paint,
    );
    
    // Draw main circle
    paint.color = color;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 5,
      paint,
    );
    
    // Draw inner white circle
    paint.color = Colors.white;
    canvas.drawCircle(
      const Offset(radius, radius),
      radius - 10,
      paint,
    );
    
    // Draw count
    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: TextStyle(
          color: color,
          fontSize: count > 99 ? 16 : 20,
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
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.fromBytes(uint8List);
  }
}

