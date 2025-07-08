import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import '../../config/routes.dart';
import './delivery_map_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/delivery_location.dart'; // Import DeliveryLocation model

class DeliveryHomeScreen extends StatefulWidget {
  @override
  _DeliveryHomeScreenState createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  bool _isOnline = true;
  bool _hasActiveDelivery = false; // Changed to false initially
  int _currentNavIndex = 0;
  
  // Mock data - replace with actual data from your backend
  Map<String, dynamic> _todayStats = {
    'deliveries': 12,
    'distance': 45
  };

  List<DeliveryLocation> _availableDeliveries = [
    DeliveryLocation(
      id: '1',
      name: 'Campus Grill',
      address: 'Mary Stuart Hall',
      coordinates: LatLng(0.3036, 32.5711), // Example coordinates
      customerName: 'John Doe',
      customerPhone: '+256700123456',
      items: 'Beef Burger Combo + Fries',
      earning: 4500,
      isPickup: true,
    ),
    DeliveryLocation(
      id: '2',
      name: 'Lumumba Hall',
      address: 'Pizza Corner',
      coordinates: LatLng(0.3136, 32.5811), // Example coordinates
      customerName: 'Jane Smith',
      customerPhone: '+256700123457',
      items: 'Margherita Pizza + Drinks',
      earning: 6200,
      isPickup: false,
    ),
  ];

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

  @override
  void initState() {
    super.initState();
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

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });
    
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
    
    // Simulate refresh
    setState(() {
      // You would update _availableDeliveries from your backend here
    });
  }

  void _acceptDelivery(DeliveryLocation delivery) {
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _acceptedDeliveries.add(delivery);
                _availableDeliveries.removeWhere((d) => d.id == delivery.id);
                _hasActiveDelivery = _acceptedDeliveries.isNotEmpty; // Update active delivery status
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delivery accepted! Added to your accepted list.'),
                  backgroundColor: Colors.green,
                ),
              );
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
              
              // Current Delivery (if any)
              if (_hasActiveDelivery && _currentDelivery != null) ...[
                _buildCurrentDeliverySection(),
                SizedBox(height: 24),
              ],
              
              // Available Deliveries
              _buildAvailableDeliveriesSection(),
              SizedBox(height: 24),
              
              // Accepted Deliveries Section
              _buildAcceptedDeliveriesSection(),
              SizedBox(height: 24),

              // Recent Deliveries
              _buildRecentDeliveriesSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _acceptedDeliveries.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _viewMultiDeliveryMap,
              backgroundColor: AppColors.primary,
              icon: Icon(Icons.map, color: AppColors.white),
              label: Text("View Accepted Deliveries", style: TextStyle(color: AppColors.white)),
            )
          : null,
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
    // This card will now display information about the *current active route* if one is set
    // For now, it will display a placeholder or be hidden if no active route.
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Active Route Summary",
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("You have ${_acceptedDeliveries.length} deliveries accepted.", 
              style: TextStyle(color: Colors.grey)),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.map),
              label: Text("View Route on Map"),
              onPressed: _viewMultiDeliveryMap,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
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

 Widget _buildAvailableDeliveriesSection() {
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
        if (_availableDeliveries.isEmpty)
          Center(
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
          )
        else
          ...List.generate(_availableDeliveries.length, (index) {
            final delivery = _availableDeliveries[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildDeliveryCard(delivery),
            );
          }),
      ],
    );
  }

  Widget _buildAcceptedDeliveriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Accepted Deliveries", style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        if (_acceptedDeliveries.isEmpty)
          Center(
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
          )
        else
          ...List.generate(_acceptedDeliveries.length, (index) {
            final delivery = _acceptedDeliveries[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _buildAcceptedDeliveryCard(delivery),
            );
          }),
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
}

