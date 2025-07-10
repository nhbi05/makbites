import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_location.dart';
import '../models/delivery_route.dart';

class FirebaseDeliveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection references
  CollectionReference get _deliveriesCollection => _firestore.collection('deliveries');
  CollectionReference get _driversCollection => _firestore.collection('drivers');
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _trackingCollection => _firestore.collection('delivery_tracking');
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  
  // Get current driver ID
  String? get currentDriverId => _auth.currentUser?.uid;
  
  // Create a new delivery order
  Future<String> createDeliveryOrder({
    required List<DeliveryLocation> locations,
    required String customerId,
    required Map<String, dynamic> orderDetails,
  }) async {
    try {
      // Create main delivery document
      DocumentReference deliveryRef = await _deliveriesCollection.add({
        'customerId': customerId,
        'driverId': currentDriverId,
        'status': 'pending', // pending, assigned, in_progress, completed, cancelled
        'orderDetails': orderDetails,
        'totalLocations': locations.length,
        'completedLocations': 0,
        'totalEarnings': locations.fold(0.0, (sum, loc) => sum + loc.earning),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'estimatedDuration': null,
        'actualDuration': null,
        'totalDistance': null,
        'isOptimized': false,
      });
      
      // Add delivery locations as subcollection
      WriteBatch batch = _firestore.batch();
      
      for (int i = 0; i < locations.length; i++) {
        DeliveryLocation location = locations[i];
        DocumentReference locationRef = deliveryRef.collection('locations').doc();
        
        batch.set(locationRef, {
          ...location.toJson(),
          'sequenceNumber': i + 1,
          'originalSequence': i + 1,
          'isCompleted': false,
          'completedAt': null,
          'completedBy': null,
          'notes': '',
        });
      }
      
      await batch.commit();
      
      return deliveryRef.id;
    } catch (e) {
      throw Exception('Failed to create delivery order: $e');
    }
  }
  
  // Get delivery orders for current driver
  Stream<QuerySnapshot> getDriverDeliveries({
    String status = 'all', // all, pending, assigned, in_progress, completed
  }) {
    Query query = _deliveriesCollection
        .where('driverId', isEqualTo: currentDriverId)
        .orderBy('createdAt', descending: true);
    
    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }
    
    return query.snapshots();
  }
  
  // Get available delivery orders (not assigned to any driver)
  Stream<QuerySnapshot> getAvailableDeliveries() {
    return _deliveriesCollection
        .where('status', isEqualTo: 'pending')
        .where('driverId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
  
  // Accept a delivery order
  Future<void> acceptDeliveryOrder(String deliveryId) async {
    try {
      await _deliveriesCollection.doc(deliveryId).update({
        'driverId': currentDriverId,
        'status': 'assigned',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Create tracking document
      await _trackingCollection.doc(deliveryId).set({
        'deliveryId': deliveryId,
        'driverId': currentDriverId,
        'status': 'assigned',
        'currentLocation': null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': false,
        'totalDistance': 0.0,
        'trackingPath': [],
      });
      
      // Send notification to customer
      await _sendNotification(
        deliveryId: deliveryId,
        type: 'driver_assigned',
        message: 'A driver has been assigned to your delivery',
      );
    } catch (e) {
      throw Exception('Failed to accept delivery order: $e');
    }
  }
  
  // Start delivery (begin route)
  Future<void> startDelivery(String deliveryId, LatLng startLocation) async {
    try {
      await _deliveriesCollection.doc(deliveryId).update({
        'status': 'in_progress',
        'startedAt': FieldValue.serverTimestamp(),
        'startLocation': {
          'latitude': startLocation.latitude,
          'longitude': startLocation.longitude,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update tracking
      await _trackingCollection.doc(deliveryId).update({
        'status': 'in_progress',
        'isActive': true,
        'currentLocation': {
          'latitude': startLocation.latitude,
          'longitude': startLocation.longitude,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Send notification
      await _sendNotification(
        deliveryId: deliveryId,
        type: 'delivery_started',
        message: 'Your delivery is on the way!',
      );
    } catch (e) {
      throw Exception('Failed to start delivery: $e');
    }
  }
  
  // Update delivery route with optimization
  Future<void> updateDeliveryRoute({
    required String deliveryId,
    required DeliveryRoute optimizedRoute,
  }) async {
    try {
      // Update main delivery document
      await _deliveriesCollection.doc(deliveryId).update({
        'isOptimized': true,
        'optimizedAt': FieldValue.serverTimestamp(),
        'estimatedDuration': optimizedRoute.estimatedDuration.inSeconds,
        'totalDistance': optimizedRoute.totalDistance,
        'routePoints': optimizedRoute.routePoints.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update location sequences based on optimization
      WriteBatch batch = _firestore.batch();
      
      for (int i = 0; i < optimizedRoute.locations.length; i++) {
        DeliveryLocation location = optimizedRoute.locations[i];
        
        // Find the location document by ID
        QuerySnapshot locationQuery = await _deliveriesCollection
            .doc(deliveryId)
            .collection('locations')
            .where('id', isEqualTo: location.id)
            .get();
        
        if (locationQuery.docs.isNotEmpty) {
          DocumentReference locationRef = locationQuery.docs.first.reference;
          batch.update(locationRef, {
            'sequenceNumber': i + 1,
            'estimatedTime': location.estimatedTime?.toIso8601String(),
          });
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update delivery route: $e');
    }
  }
  
  // Mark delivery location as completed
  Future<void> completeDeliveryLocation({
    required String deliveryId,
    required String locationId,
    required LatLng completionLocation,
    String? notes,
    String? photoUrl,
  }) async {
    try {
      // Update location document
      QuerySnapshot locationQuery = await _deliveriesCollection
          .doc(deliveryId)
          .collection('locations')
          .where('id', isEqualTo: locationId)
          .get();
      
      if (locationQuery.docs.isEmpty) {
        throw Exception('Location not found');
      }
      
      DocumentReference locationRef = locationQuery.docs.first.reference;
      await locationRef.update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': currentDriverId,
        'completedLocation': {
          'latitude': completionLocation.latitude,
          'longitude': completionLocation.longitude,
        },
        'notes': notes ?? '',
        'photoUrl': photoUrl,
      });
      
      // Update delivery progress
      DocumentSnapshot deliveryDoc = await _deliveriesCollection.doc(deliveryId).get();
      Map<String, dynamic> deliveryData = deliveryDoc.data() as Map<String, dynamic>;
      
      int completedLocations = (deliveryData['completedLocations'] ?? 0) + 1;
      int totalLocations = deliveryData['totalLocations'] ?? 0;
      
      Map<String, dynamic> updateData = {
        'completedLocations': completedLocations,
        'lastLocationCompleted': locationId,
        'lastCompletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Check if all locations are completed
      if (completedLocations >= totalLocations) {
        updateData['status'] = 'completed';
        updateData['completedAt'] = FieldValue.serverTimestamp();
      }
      
      await _deliveriesCollection.doc(deliveryId).update(updateData);
      
      // Send notification
      String notificationType = completedLocations >= totalLocations ? 'delivery_completed' : 'location_completed';
      String message = completedLocations >= totalLocations 
          ? 'Your delivery has been completed!'
          : 'One of your delivery locations has been completed';
      
      await _sendNotification(
        deliveryId: deliveryId,
        type: notificationType,
        message: message,
      );
    } catch (e) {
      throw Exception('Failed to complete delivery location: $e');
    }
  }
  
  // Update real-time location tracking
  Future<void> updateDriverLocation({
    required String deliveryId,
    required LatLng location,
    double? totalDistance,
    List<LatLng>? trackingPath,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'currentLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (totalDistance != null) {
        updateData['totalDistance'] = totalDistance;
      }
      
      if (trackingPath != null) {
        updateData['trackingPath'] = trackingPath.map((point) => {
          'latitude': point.latitude,
          'longitude': point.longitude,
        }).toList();
      }
      
      await _trackingCollection.doc(deliveryId).update(updateData);
    } catch (e) {
      print('Failed to update driver location: $e');
      // Don't throw exception for location updates to avoid disrupting the app
    }
  }
  
  // Get real-time tracking data
  Stream<DocumentSnapshot> getDeliveryTracking(String deliveryId) {
    return _trackingCollection.doc(deliveryId).snapshots();
  }
  
  // Get delivery locations stream
  Stream<QuerySnapshot> getDeliveryLocations(String deliveryId) {
    return _deliveriesCollection
        .doc(deliveryId)
        .collection('locations')
        .orderBy('sequenceNumber')
        .snapshots();
  }
  
  // Send notification
  Future<void> _sendNotification({
    required String deliveryId,
    required String type,
    required String message,
    String? customerId,
  }) async {
    try {
      // Get customer ID if not provided
      if (customerId == null) {
        DocumentSnapshot deliveryDoc = await _deliveriesCollection.doc(deliveryId).get();
        Map<String, dynamic> deliveryData = deliveryDoc.data() as Map<String, dynamic>;
        customerId = deliveryData['customerId'];
      }
      
      await _notificationsCollection.add({
        'customerId': customerId,
        'deliveryId': deliveryId,
        'driverId': currentDriverId,
        'type': type,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
  
  // Get driver statistics
  Future<Map<String, dynamic>> getDriverStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _deliveriesCollection
          .where('driverId', isEqualTo: currentDriverId)
          .where('status', isEqualTo: 'completed');
      
      if (startDate != null) {
        query = query.where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('completedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      QuerySnapshot snapshot = await query.get();
      
      double totalEarnings = 0.0;
      double totalDistance = 0.0;
      int totalDeliveries = snapshot.docs.length;
      int totalLocations = 0;
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

  totalEarnings += (data['totalEarnings'] ?? 0.0) is num
      ? (data['totalEarnings'] as num).toDouble()
      : 0.0;

  totalDistance += (data['totalDistance'] ?? 0.0) is num
      ? (data['totalDistance'] as num).toDouble()
      : 0.0;

  totalLocations += (data['totalLocations'] ?? 0) is num
      ? (data['totalLocations'] as num).toInt()
      : 0;
}

      
      return {
        'totalDeliveries': totalDeliveries,
        'totalLocations': totalLocations,
        'totalEarnings': totalEarnings,
        'totalDistance': totalDistance,
        'averageEarningsPerDelivery': totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0.0,
        'averageDistancePerDelivery': totalDeliveries > 0 ? totalDistance / totalDeliveries : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to get driver statistics: $e');
    }
  }
  
  // Update driver status (online/offline)
  Future<void> updateDriverStatus({
    required bool isOnline,
    LatLng? currentLocation,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'isOnline': isOnline,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      };
      
      if (currentLocation != null) {
        updateData['currentLocation'] = {
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
        };
      }
      
      await _driversCollection.doc(currentDriverId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update driver status: $e');
    }
  }
  
  // Get delivery history
  Future<List<Map<String, dynamic>>> getDeliveryHistory({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _deliveriesCollection
          .where('driverId', isEqualTo: currentDriverId)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      List<Map<String, dynamic>> deliveries = [];
      
      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        deliveries.add(data);
      }
      
      return deliveries;
    } catch (e) {
      throw Exception('Failed to get delivery history: $e');
    }
  }
  
  // Cancel delivery
  Future<void> cancelDelivery(String deliveryId, String reason) async {
    try {
      await _deliveriesCollection.doc(deliveryId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': currentDriverId,
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Update tracking
      await _trackingCollection.doc(deliveryId).update({
        'status': 'cancelled',
        'isActive': false,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Send notification
      await _sendNotification(
        deliveryId: deliveryId,
        type: 'delivery_cancelled',
        message: 'Your delivery has been cancelled. Reason: $reason',
      );
    } catch (e) {
      throw Exception('Failed to cancel delivery: $e');
    }
  }
  
  // Batch operations for better performance
  Future<void> batchUpdateLocations({
    required String deliveryId,
    required List<Map<String, dynamic>> locationUpdates,
  }) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (Map<String, dynamic> update in locationUpdates) {
        String locationId = update['id'];
        
        QuerySnapshot locationQuery = await _deliveriesCollection
            .doc(deliveryId)
            .collection('locations')
            .where('id', isEqualTo: locationId)
            .get();
        
        if (locationQuery.docs.isNotEmpty) {
          DocumentReference locationRef = locationQuery.docs.first.reference;
          batch.update(locationRef, update);
        }
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update locations: $e');
    }
  }
  
  // Listen to delivery status changes
  Stream<DocumentSnapshot> listenToDeliveryChanges(String deliveryId) {
    return _deliveriesCollection.doc(deliveryId).snapshots();
  }
  
  // Clean up old tracking data (call periodically)
  Future<void> cleanupOldTrackingData({int daysOld = 30}) async {
    try {
      DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      QuerySnapshot oldTracking = await _trackingCollection
          .where('lastUpdated', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      WriteBatch batch = _firestore.batch();
      
      for (QueryDocumentSnapshot doc in oldTracking.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Failed to cleanup old tracking data: $e');
    }
  }
}

