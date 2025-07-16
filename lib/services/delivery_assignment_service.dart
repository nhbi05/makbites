import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_location.dart';

class DeliveryAssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current rider ID
  String? get currentRiderId => _auth.currentUser?.uid;

  // Listen to assigned deliveries for current rider
  Stream<QuerySnapshot> getAssignedDeliveries() {
    if (currentRiderId == null) return Stream.empty();

    return _firestore
        .collection('deliveries')
        .where('assignedRiderId', isEqualTo: 'rider_$currentRiderId')
        .where('status', whereIn: ['pending_assignment', 'assigned', 'in_progress'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Listen to available deliveries (not assigned to any rider)
  Stream<QuerySnapshot> getAvailableDeliveries() {
    return _firestore
        .collection('deliveries')
        .where('status', isEqualTo: 'pending_assignment')
        .where('assignedRiderId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Accept a delivery assignment
  Future<void> acceptDelivery(String deliveryId) async {
    if (currentRiderId == null) throw Exception('Rider not authenticated');

    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'assignedRiderId': 'rider_$currentRiderId',
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update rider's total deliveries count
      await _firestore
          .collection('delivery_riders')
          .doc('rider_$currentRiderId')
          .update({
        'total_deliveries': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to accept delivery: $e');
    }
  }

  // Start delivery (begin route)
  Future<void> startDelivery(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to start delivery: $e');
    }
  }

  // Complete delivery
  Future<void> completeDelivery(String deliveryId) async {
    try {
      await _firestore.collection('deliveries').doc(deliveryId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'actualDeliveryTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update the corresponding order status
      final deliveryDoc = await _firestore.collection('deliveries').doc(deliveryId).get();
      final deliveryData = deliveryDoc.data();
      if (deliveryData != null && deliveryData['orderId'] != null) {
        await _firestore.collection('orders').doc(deliveryData['orderId']).update({
          'status': 'Delivered',
          'deliveredAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to complete delivery: $e');
    }
  }

  // Update rider's online status
  Future<void> updateRiderStatus({required bool isOnline}) async {
    if (currentRiderId == null) return;

    try {
      await _firestore
          .collection('delivery_riders')
          .doc('rider_$currentRiderId')
          .update({
        'is_online': isOnline,
        'last_status_update': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update rider status: $e');
    }
  }

  // Update rider's current location
  Future<void> updateRiderLocation(LatLng location) async {
    if (currentRiderId == null) return;

    try {
      await _firestore
          .collection('delivery_riders')
          .doc('rider_$currentRiderId')
          .update({
        'current_location': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'last_location_update': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to update rider location: $e');
    }
  }

  // Convert delivery document to DeliveryLocation model
  DeliveryLocation deliveryToLocation(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    double? lat, lng;
    if (data['customerLocation'] != null &&
        data['customerLocation']['latitude'] != null &&
        data['customerLocation']['longitude'] != null) {
      lat = data['customerLocation']['latitude'];
      lng = data['customerLocation']['longitude'];
    } else if (data['locationLat'] != null && data['locationLng'] != null) {
      lat = data['locationLat'];
      lng = data['locationLng'];
    }

    LatLng coordinates;
    if (lat != null && lng != null) {
      coordinates = LatLng(lat, lng);
    } else {
      // Optionally: skip this delivery or use a default location
      coordinates = LatLng(0.0, 0.0);
    }

    return DeliveryLocation(
      id: doc.id,
      name: data['customerName'] ?? 'Unknown Customer',
      address: data['deliveryAddress'] ?? 'No address provided',
      coordinates: coordinates,
      customerName: data['customerName'] ?? 'Unknown',
      customerPhone: data['customerPhone'] ?? '',
      items: _formatOrderItems(data['orderItems'] ?? []),
      earning: _calculateDeliveryFee(data),
      isPickup: false,
      estimatedTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
    );
  }

  // Format order items for display
  String _formatOrderItems(List<dynamic> items) {
    if (items.isEmpty) return 'No items';
    
    return items.map((item) {
      if (item is Map<String, dynamic>) {
        String name = item['name'] ?? 'Unknown item';
        int quantity = item['quantity'] ?? 1;
        return '${quantity}x $name';
      }
      return item.toString();
    }).join(', ');
  }

  // Calculate delivery fee
  double _calculateDeliveryFee(Map<String, dynamic> data) {
    // You can implement your own delivery fee calculation logic here
    // For now, using a fixed fee or percentage of order total
    double totalAmount = (data['totalAmount'] ?? 0).toDouble();
    double deliveryFee = (data['deliveryFee'] ?? 0).toDouble();
    
    // If no delivery fee is set, use 10% of order total as default
    if (deliveryFee == 0) {
      deliveryFee = totalAmount * 0.1;
    }
    
    return deliveryFee;
  }

  // Get delivery statistics for current rider
  Future<Map<String, dynamic>> getRiderStatistics() async {
    if (currentRiderId == null) return {};

    try {
      QuerySnapshot completedDeliveries = await _firestore
          .collection('deliveries')
          .where('assignedRiderId', isEqualTo: 'rider_$currentRiderId')
          .where('status', isEqualTo: 'completed')
          .get();

      int totalDeliveries = completedDeliveries.docs.length;
      double totalEarnings = 0.0;

      for (QueryDocumentSnapshot doc in completedDeliveries.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalEarnings += _calculateDeliveryFee(data);
      }

      return {
        'totalDeliveries': totalDeliveries,
        'totalEarnings': totalEarnings,
        'averageEarnings': totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0.0,
      };
    } catch (e) {
      print('Failed to get rider statistics: $e');
      return {};
    }
  }

  // Listen to order status changes that affect deliveries
  Stream<QuerySnapshot> listenToOrderUpdates() {
    if (currentRiderId == null) return Stream.empty();

    return _firestore
        .collection('orders')
        .where('assignedRiderId', isEqualTo: 'rider_$currentRiderId')
        .snapshots();
  }
} 