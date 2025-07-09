import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Firestore data models for the delivery app

class FirebaseDeliveryOrder {
  final String id;
  final String customerId;
  final String? driverId;
  final String status; // pending, assigned, in_progress, completed, cancelled
  final Map<String, dynamic> orderDetails;
  final int totalLocations;
  final int completedLocations;
  final double totalEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final LatLng? startLocation;
  final int? estimatedDuration; // in seconds
  final int? actualDuration; // in seconds
  final double? totalDistance; // in kilometers
  final bool isOptimized;
  final List<LatLng>? routePoints;
  final String? lastLocationCompleted;
  final DateTime? lastCompletedAt;
  final String? cancellationReason;
  final String? cancelledBy;

  FirebaseDeliveryOrder({
    required this.id,
    required this.customerId,
    this.driverId,
    required this.status,
    required this.orderDetails,
    required this.totalLocations,
    required this.completedLocations,
    required this.totalEarnings,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.startLocation,
    this.estimatedDuration,
    this.actualDuration,
    this.totalDistance,
    required this.isOptimized,
    this.routePoints,
    this.lastLocationCompleted,
    this.lastCompletedAt,
    this.cancellationReason,
    this.cancelledBy,
  });

  factory FirebaseDeliveryOrder.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebaseDeliveryOrder(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      driverId: data['driverId'],
      status: data['status'] ?? 'pending',
      orderDetails: data['orderDetails'] ?? {},
      totalLocations: data['totalLocations'] ?? 0,
      completedLocations: data['completedLocations'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      startLocation: data['startLocation'] != null
          ? LatLng(data['startLocation']['latitude'], data['startLocation']['longitude'])
          : null,
      estimatedDuration: data['estimatedDuration'],
      actualDuration: data['actualDuration'],
      totalDistance: data['totalDistance']?.toDouble(),
      isOptimized: data['isOptimized'] ?? false,
      routePoints: data['routePoints'] != null
          ? (data['routePoints'] as List)
              .map((point) => LatLng(point['latitude'], point['longitude']))
              .toList()
          : null,
      lastLocationCompleted: data['lastLocationCompleted'],
      lastCompletedAt: (data['lastCompletedAt'] as Timestamp?)?.toDate(),
      cancellationReason: data['cancellationReason'],
      cancelledBy: data['cancelledBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'driverId': driverId,
      'status': status,
      'orderDetails': orderDetails,
      'totalLocations': totalLocations,
      'completedLocations': completedLocations,
      'totalEarnings': totalEarnings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'startLocation': startLocation != null
          ? {
              'latitude': startLocation!.latitude,
              'longitude': startLocation!.longitude,
            }
          : null,
      'estimatedDuration': estimatedDuration,
      'actualDuration': actualDuration,
      'totalDistance': totalDistance,
      'isOptimized': isOptimized,
      'routePoints': routePoints?.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'lastLocationCompleted': lastLocationCompleted,
      'lastCompletedAt': lastCompletedAt != null ? Timestamp.fromDate(lastCompletedAt!) : null,
      'cancellationReason': cancellationReason,
      'cancelledBy': cancelledBy,
    };
  }
}

class FirebaseDeliveryLocation {
  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final String customerName;
  final String customerPhone;
  final String items;
  final double earning;
  final bool isPickup;
  final bool isCompleted;
  final DateTime? estimatedTime;
  final int sequenceNumber;
  final int originalSequence;
  final DateTime? completedAt;
  final String? completedBy;
  final LatLng? completedLocation;
  final String notes;
  final String? photoUrl;

  FirebaseDeliveryLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.earning,
    required this.isPickup,
    required this.isCompleted,
    this.estimatedTime,
    required this.sequenceNumber,
    required this.originalSequence,
    this.completedAt,
    this.completedBy,
    this.completedLocation,
    required this.notes,
    this.photoUrl,
  });

  factory FirebaseDeliveryLocation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebaseDeliveryLocation(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      coordinates: LatLng(data['latitude'] ?? 0.0, data['longitude'] ?? 0.0),
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      items: data['items'] ?? '',
      earning: (data['earning'] ?? 0.0).toDouble(),
      isPickup: data['isPickup'] ?? false,
      isCompleted: data['isCompleted'] ?? false,
      estimatedTime: data['estimatedTime'] != null
          ? DateTime.parse(data['estimatedTime'])
          : null,
      sequenceNumber: data['sequenceNumber'] ?? 0,
      originalSequence: data['originalSequence'] ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      completedBy: data['completedBy'],
      completedLocation: data['completedLocation'] != null
          ? LatLng(data['completedLocation']['latitude'], data['completedLocation']['longitude'])
          : null,
      notes: data['notes'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items,
      'earning': earning,
      'isPickup': isPickup,
      'isCompleted': isCompleted,
      'estimatedTime': estimatedTime?.toIso8601String(),
      'sequenceNumber': sequenceNumber,
      'originalSequence': originalSequence,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'completedLocation': completedLocation != null
          ? {
              'latitude': completedLocation!.latitude,
              'longitude': completedLocation!.longitude,
            }
          : null,
      'notes': notes,
      'photoUrl': photoUrl,
    };
  }
}

class FirebaseDeliveryTracking {
  final String deliveryId;
  final String driverId;
  final String status;
  final LatLng? currentLocation;
  final DateTime lastUpdated;
  final bool isActive;
  final double totalDistance;
  final List<LatLng> trackingPath;

  FirebaseDeliveryTracking({
    required this.deliveryId,
    required this.driverId,
    required this.status,
    this.currentLocation,
    required this.lastUpdated,
    required this.isActive,
    required this.totalDistance,
    required this.trackingPath,
  });

  factory FirebaseDeliveryTracking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebaseDeliveryTracking(
      deliveryId: data['deliveryId'] ?? doc.id,
      driverId: data['driverId'] ?? '',
      status: data['status'] ?? 'unknown',
      currentLocation: data['currentLocation'] != null
          ? LatLng(data['currentLocation']['latitude'], data['currentLocation']['longitude'])
          : null,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
      totalDistance: (data['totalDistance'] ?? 0.0).toDouble(),
      trackingPath: data['trackingPath'] != null
          ? (data['trackingPath'] as List)
              .map((point) => LatLng(point['latitude'], point['longitude']))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'deliveryId': deliveryId,
      'driverId': driverId,
      'status': status,
      'currentLocation': currentLocation != null
          ? {
              'latitude': currentLocation!.latitude,
              'longitude': currentLocation!.longitude,
            }
          : null,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isActive': isActive,
      'totalDistance': totalDistance,
      'trackingPath': trackingPath.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
    };
  }
}

class FirebaseDriver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String vehicleType;
  final String vehicleNumber;
  final bool isOnline;
  final LatLng? currentLocation;
  final DateTime lastStatusUpdate;
  final double rating;
  final int totalDeliveries;
  final bool isVerified;
  final String? profilePhotoUrl;

  FirebaseDriver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.isOnline,
    this.currentLocation,
    required this.lastStatusUpdate,
    required this.rating,
    required this.totalDeliveries,
    required this.isVerified,
    this.profilePhotoUrl,
  });

  factory FirebaseDriver.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebaseDriver(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
      isOnline: data['isOnline'] ?? false,
      currentLocation: data['currentLocation'] != null
          ? LatLng(data['currentLocation']['latitude'], data['currentLocation']['longitude'])
          : null,
      lastStatusUpdate: (data['lastStatusUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      profilePhotoUrl: data['profilePhotoUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'isOnline': isOnline,
      'currentLocation': currentLocation != null
          ? {
              'latitude': currentLocation!.latitude,
              'longitude': currentLocation!.longitude,
            }
          : null,
      'lastStatusUpdate': Timestamp.fromDate(lastStatusUpdate),
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'isVerified': isVerified,
      'profilePhotoUrl': profilePhotoUrl,
    };
  }
}

class FirebaseNotification {
  final String id;
  final String customerId;
  final String deliveryId;
  final String driverId;
  final String type; // driver_assigned, delivery_started, location_completed, delivery_completed, delivery_cancelled
  final String message;
  final DateTime timestamp;
  final bool isRead;

  FirebaseNotification({
    required this.id,
    required this.customerId,
    required this.deliveryId,
    required this.driverId,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory FirebaseNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebaseNotification(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      deliveryId: data['deliveryId'] ?? '',
      driverId: data['driverId'] ?? '',
      type: data['type'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'deliveryId': deliveryId,
      'driverId': driverId,
      'type': type,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class FirebaseDriverStatistics {
  final String driverId;
  final DateTime date;
  final int totalDeliveries;
  final int totalLocations;
  final double totalEarnings;
  final double totalDistance;
  final int totalDuration; // in minutes
  final double averageRating;
  final int onlineTime; // in minutes

  FirebaseDriverStatistics({
    required this.driverId,
    required this.date,
    required this.totalDeliveries,
    required this.totalLocations,
    required this.totalEarnings,
    required this.totalDistance,
    required this.totalDuration,
    required this.averageRating,
    required this.onlineTime,
  });

  factory FirebaseDriverStatistics.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FirebaseDriverStatistics(
      driverId: data['driverId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalDeliveries: data['totalDeliveries'] ?? 0,
      totalLocations: data['totalLocations'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      totalDistance: (data['totalDistance'] ?? 0.0).toDouble(),
      totalDuration: data['totalDuration'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      onlineTime: data['onlineTime'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'date': Timestamp.fromDate(date),
      'totalDeliveries': totalDeliveries,
      'totalLocations': totalLocations,
      'totalEarnings': totalEarnings,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'averageRating': averageRating,
      'onlineTime': onlineTime,
    };
  }
}

// Helper class for Firestore queries
class FirestoreQueries {
  static const String deliveriesCollection = 'deliveries';
  static const String driversCollection = 'drivers';
  static const String trackingCollection = 'delivery_tracking';
  static const String notificationsCollection = 'notifications';
  static const String statisticsCollection = 'driver_statistics';
  
  // Common query filters
  static Query pendingDeliveries(CollectionReference collection) {
    return collection
        .where('status', isEqualTo: 'pending')
        .where('driverId', isNull: true)
        .orderBy('createdAt');
  }
  
  static Query driverDeliveries(CollectionReference collection, String driverId) {
    return collection
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true);
  }
  
  static Query activeDeliveries(CollectionReference collection, String driverId) {
    return collection
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['assigned', 'in_progress']);
  }
  
  static Query onlineDrivers(CollectionReference collection) {
    return collection
        .where('isOnline', isEqualTo: true)
        .where('isVerified', isEqualTo: true);
  }
  
  static Query unreadNotifications(CollectionReference collection, String userId) {
    return collection
        .where('customerId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .orderBy('timestamp', descending: true);
  }
}

