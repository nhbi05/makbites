import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import '../../config/routes.dart';
import './delivery_map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/delivery_location.dart'; // Import DeliveryLocation model
import '../../services/delivery_assignment_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DeliveryHomeScreen extends StatefulWidget {
  @override
  _DeliveryHomeScreenState createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  bool _isOnline = true;
  bool _hasActiveDelivery = false; // Changed to false initially
  int _currentNavIndex = 0;
  
  // Service for handling delivery assignments
  final DeliveryAssignmentService _deliveryService = DeliveryAssignmentService();
  
  // Real data from Firebase
  Map<String, dynamic> _todayStats = {
    'deliveries': 0,
    'distance': 0
  };

  List<DeliveryLocation> _availableDeliveries = [];
  List<DeliveryLocation> _acceptedDeliveries = []; // New list to hold accepted deliveries

  DeliveryLocation? _currentDelivery; // Will be set when a route is optimized and started

  List<Map<String, dynamic>> _recentDeliveries = [
    {
      'route': 'Healthy Bites → Africa Hall',
      'earning': 3800,
      'status': 'Delivered',
    },
    {
      'route': 'Campus Grill → Complex Hall',
      'earning': 4200,
      'status': 'Delivered',
    },
  ];

  LatLng? _currentLocation;
  List<LatLng> _optimizedPolyline = [];
  List<int>? _waypointOrder = [];
  Set<Marker> _markers = {};
  int _currentOptimizedIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation().then((_) => _getOptimizedRoute());
    _loadTodayStats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _viewMultiDeliveryMap() {
    if (_acceptedDeliveries.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.deliveryMap,
        arguments: _acceptedDeliveries,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No deliveries accepted for mapping')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/landing', 
          (route) => false
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleOnlineStatus() async {
    setState(() {
      _isOnline = !_isOnline;
    });
    
    // Update rider status in Firebase
    await _deliveryService.updateRiderStatus(isOnline: _isOnline);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isOnline ? 'You are now online' : 'You are now offline'),
        backgroundColor: _isOnline ? Colors.green : Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshDeliveries() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Refreshing deliveries...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Refresh stats
    _loadTodayStats();
  }

  Future<void> _loadTodayStats() async {
    try {
      final stats = await _deliveryService.getRiderStatistics();
      setState(() {
        _todayStats = {
          'deliveries': stats['totalDeliveries'] ?? 0,
          'distance': stats['totalEarnings'] ?? 0, // Using earnings as distance for now
        };
      });
    } catch (e) {
      print('Failed to load stats: $e');
    }
  }

  // Complete delivery function
  Future<void> _completeDelivery(String deliveryId) async {
    try {
      await _deliveryService.completeDelivery(deliveryId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete delivery: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Test function to create a sample delivery (remove in production)
  Future<void> _createTestDelivery() async {
    try {
      await FirebaseFirestore.instance.collection('deliveries').add({
        'orderId': 'TEST-ORDER-${DateTime.now().millisecondsSinceEpoch}',
        'restaurantId': 'test-restaurant',
        'customerId': 'test-customer',
        'customerName': 'Test Customer',
        'customerPhone': '+256700123456',
        'deliveryAddress': 'Makerere University, Kampala',
        'customerLocation': {
          'latitude': 0.331635,
          'longitude': 32.566491,
        },
        'orderItems': [
          {
            'name': 'Chicken Pilau',
            'price': 10000,
            'quantity': 1,
          }
        ],
        'totalAmount': 10000,
        'deliveryFee': 1000,
        'status': 'pending_assignment',
        'assignedRiderId': null,
        'assignedAt': null,
        'estimatedDeliveryTime': null,
        'estimatedPickupTime': null,
        'actualDeliveryTime': null,
        'actualPickupTime': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test delivery created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create test delivery: ${e.toString()}')),
      );
    }
  }

  void _acceptDelivery(DeliveryLocation delivery) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Delivery'),
        content: Text('Do you want to accept this delivery for UGX ${delivery.earning}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                // Accept delivery in Firebase
                await _deliveryService.acceptDelivery(delivery.id);
                
                setState(() {
                  _acceptedDeliveries.add(delivery);
                  _availableDeliveries.removeWhere((d) => d.id == delivery.id);
                  _hasActiveDelivery = _acceptedDeliveries.isNotEmpty;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Delivery accepted! Added to your accepted list.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to accept delivery: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _startNavigation() async {
    // The actual navigation logic will be handled within DeliveryMapScreen.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Please use 'Multi Delivery' to view and navigate your accepted deliveries."),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _callCustomer() {
    // This function will be removed or modified to call the customer of the *next* delivery in the optimized route.
    // For now, it will show a message.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Call customer functionality will be available on the map screen for the current delivery."),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, 
        AppRoutes.deliveryMap, // Assuming this route exists
        arguments: _acceptedDeliveries, // Pass accepted deliveries
        );
        break;
      case 2:
        Navigator.pushNamed(context, AppRoutes.deliveryProfile); 
        break;
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Quick Actions", style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildQuickAction(
              _isOnline ? "Go Offline" : "Go Online",
              Icons.power_settings_new,
              _isOnline ? Colors.red : Colors.green,
              _toggleOnlineStatus,
            )),
            SizedBox(width: 12),
            Expanded(child: _buildQuickAction(
              "Multi\nDelivery",
              Icons.alt_route,
              AppColors.primary,
              _viewMultiDeliveryMap,
            )),
            SizedBox(width: 12),
            Expanded(child: _buildQuickAction(
              "Delivery\nHistory",
              Icons.history,
              AppColors.success,
              () => Navigator.pushNamed(context, "/deliveries"),
            )),
          ],
        ),
        SizedBox(height: 12),
        // Test button - remove in production
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _createTestDelivery,
            icon: Icon(Icons.add),
            label: Text("Create Test Delivery"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MakBites Delivery", style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, "/notifications");
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, "/help");
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case "logout":
                  _logout(context);
                  break;
                case "settings":
                  Navigator.pushNamed(context, "/settings");
                  break;
                case "support":
                  Navigator.pushNamed(context, "/support");
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: "settings",
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("Settings"),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: "support",
                  child: Row(
                    children: [
                      Icon(Icons.support_agent, color: Colors.grey),
                      SizedBox(width: 8),
                      Text("Support"),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: "logout",
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Logout", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshDeliveries();
          await Future.delayed(Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              _buildStatusCard(),
              SizedBox(height: 24),
              
              // Today's Stats
              _buildTodayStats(),
              SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(),
              SizedBox(height: 24),
              
              // Available Deliveries (Real-time from Firebase)
              _buildAvailableDeliveriesStream(),
              SizedBox(height: 24),
              
              // Accepted Deliveries Section (Real-time from Firebase)
              _buildAcceptedDeliveriesStream(),
              SizedBox(height: 24),

              // Recent Deliveries
              _buildRecentDeliveriesSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _deliveryService.getAssignedDeliveries(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return FloatingActionButton.extended(
              onPressed: () {
                final deliveries = snapshot.data!.docs
                    .map((doc) => _deliveryService.deliveryToLocation(doc))
                    .toList();
                Navigator.pushNamed(
                  context,
                  AppRoutes.deliveryMap,
                  arguments: deliveries,
                );
              },
              backgroundColor: AppColors.primary,
              icon: Icon(Icons.map, color: AppColors.white),
              label: Text("View Accepted Deliveries", style: TextStyle(color: AppColors.white)),
            );
          }
          return SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isOnline 
              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
              : [Colors.orange, Colors.orange.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.circle, 
                color: _isOnline ? Colors.green : Colors.orange, 
                size: 12,
              ),
              SizedBox(width: 8),
              Text(
                _isOnline ? "Online - Ready for Deliveries" : "Offline",
                style: AppTextStyles.body.copyWith(color: AppColors.white),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Good Morning, Rider!",
            style: AppTextStyles.subHeader.copyWith(color: AppColors.white),
          ),
          SizedBox(height: 4),
          Text(
            _isOnline 
                ? "You're ready to start earning today"
                : "Go online to start receiving deliveries",
            style: AppTextStyles.body.copyWith(color: AppColors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Today's Performance", style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              "Deliveries", 
              "${_todayStats["deliveries"]}", 
              Icons.local_shipping, 
              AppColors.success
            )),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              "Distance", 
              "${_todayStats["distance"]} km", 
              Icons.route, 
              AppColors.primary
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentDeliveryCard() {
    if (_acceptedDeliveries.isEmpty || _waypointOrder == null || _waypointOrder!.isEmpty) return SizedBox.shrink();

    // Build the full optimized order including the destination
    List<int> allStopsOrder;
    if (_waypointOrder == null || _waypointOrder!.isEmpty) {
      // Only one delivery, so just show it
      allStopsOrder = [_acceptedDeliveries.length - 1];
    } else {
      // Usual case: waypoints + destination
      allStopsOrder = [
        ..._waypointOrder!,
        _acceptedDeliveries.length - 1
      ];
    }

    // Use _currentOptimizedIndex to index into allStopsOrder
    final delivery = _acceptedDeliveries[allStopsOrder[_currentOptimizedIndex]];

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  delivery.isPickup ? Icons.store : Icons.home,
                  color: delivery.isPickup ? Colors.orange : Colors.green,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  'Stop ${_currentOptimizedIndex + 1}/${allStopsOrder.length}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(delivery.address),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(delivery.customerName, style: TextStyle(color: Colors.grey)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.fastfood, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(delivery.items, style: TextStyle(color: Colors.grey)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UGX ${delivery.earning}',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _callCustomerFor(delivery.customerPhone),
                  icon: Icon(Icons.phone, size: 16),
                  label: Text('Call Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _currentOptimizedIndex > 0
                      ? () => setState(() => _currentOptimizedIndex--)
                      : null,
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _currentOptimizedIndex < allStopsOrder.length - 1
                      ? () => setState(() => _currentOptimizedIndex++)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Current Active Route", style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        _buildCurrentDeliveryCard(),
      ],
    );
  }

   Widget _buildAvailableDeliveriesStream() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Available Deliveries", style: AppTextStyles.subHeader),
            TextButton(
              onPressed: _refreshDeliveries,
              child: Text("Refresh", style: TextStyle(color: AppColors.primary)),
            )
          ],
        ),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _deliveryService.getAvailableDeliveries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading deliveries: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No new deliveries available",
                        style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final delivery = _deliveryService.deliveryToLocation(doc);
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildDeliveryCard(delivery),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAcceptedDeliveriesStream() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Accepted Deliveries", style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _deliveryService.getAssignedDeliveries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading accepted deliveries: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "No deliveries accepted yet.",
                        style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final delivery = _deliveryService.deliveryToLocation(doc);
                return Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildAcceptedDeliveryCard(delivery),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentDeliveriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Deliveries", style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        ...List.generate(_recentDeliveries.length, (index) {
          final delivery = _recentDeliveries[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildRecentDeliveryCard(
              delivery["route"],
              delivery["earning"],
              delivery["status"],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: color, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(DeliveryLocation delivery) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: delivery.isPickup ? AppColors.warning : Colors.grey.withOpacity(0.2),
          width: delivery.isPickup ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.name + (delivery.isPickup ? " (Pickup)" : " (Dropoff)"),
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (delivery.isPickup)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "PICKUP",
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(delivery.address, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "UGX ${delivery.earning}",
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey, size: 16),
                  SizedBox(width: 4),
                  Text("Est. Time: ${delivery.estimatedTime?.minute ?? "N/A"} min", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isOnline ? () => _acceptDelivery(delivery) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isOnline ? AppColors.primary : Colors.grey,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isOnline ? "Accept Delivery" : "Go Online First",
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedDeliveryCard(DeliveryLocation delivery) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  delivery.name + (delivery.isPickup ? " (Pickup)" : " (Dropoff)"),
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "ACCEPTED",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(delivery.address, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 8),
          Text(delivery.items, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "UGX ${delivery.earning}",
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => _completeDelivery(delivery.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Complete',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentDeliveryCard(String route, int earning, String status) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(color: AppColors.success, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "UGX $earning",
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentNavIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: "Deliveries",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: "Profile",
        ),
      ],
      onTap: _handleBottomNavTap,
    );
  }

  Future<void> _getOptimizedRoute() async {
    if (_currentLocation == null || _acceptedDeliveries.isEmpty) return;

    final apiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';
    final origin = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    final destination = '${_acceptedDeliveries.last.coordinates.latitude},${_acceptedDeliveries.last.coordinates.longitude}';
    final waypoints = _acceptedDeliveries
        .sublist(0, _acceptedDeliveries.length - 1)
        .map((d) => '${d.coordinates.latitude},${d.coordinates.longitude}')
        .join('|');

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&waypoints=optimize:true|$waypoints&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final route = data['routes'][0];
      final polyline = route['overview_polyline']['points'];
      final waypointOrder = List<int>.from(route['waypoint_order']);

      // Decode polyline
      PolylinePoints polylinePoints = PolylinePoints();
      List<PointLatLng> result = polylinePoints.decodePolyline(polyline);

      setState(() {
        _optimizedPolyline = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        _waypointOrder = waypointOrder;
      });

      _createMarkers();
    } else {
      // Handle error
    }
  }

  void _createMarkers() {
    Set<Marker> markers = {};

    // Start marker
    if (_currentLocation != null) {
      _markers.add(Marker(
        markerId: MarkerId('start'),
        position: _currentLocation!,
        infoWindow: InfoWindow(title: 'Start (You)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ));
    }

    // Delivery stops
    for (int i = 0; i < _waypointOrder!.length; i++) {
      final delivery = _acceptedDeliveries[_waypointOrder![i]];
      markers.add(Marker(
        markerId: MarkerId('stop_${i + 1}'),
        position: delivery.coordinates,
        infoWindow: InfoWindow(title: 'Stop ${i + 1}', snippet: delivery.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    // End marker
    final last = _acceptedDeliveries.last;
    markers.add(Marker(
      markerId: MarkerId('end'),
      position: last.coordinates,
      infoWindow: InfoWindow(title: 'End', snippet: last.name),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ));

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Optionally show a message to the user
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Optionally show a message to the user
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _callCustomerFor(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not call $phoneNumber')),
      );
    }
  }
}

