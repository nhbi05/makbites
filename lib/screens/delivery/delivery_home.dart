import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class DeliveryHomeScreen extends StatefulWidget {
  @override
  _DeliveryHomeScreenState createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  bool _isOnline = true;
  bool _hasActiveDelivery = true;
  int _currentNavIndex = 0;
  
  // Mock data - replace with actual data from your backend
  Map<String, dynamic> _todayStats = {
    'deliveries': 12,
    'earnings': 48000,
    'distance': 45,
    'rating': 4.9,
  };

  List<Map<String, dynamic>> _availableDeliveries = [
    {
      'id': '1',
      'route': 'Campus Grill → Mary Stuart Hall',
      'items': 'Beef Burger Combo + Fries',
      'earning': 4500,
      'distance': 2.3,
      'time': 8,
      'isUrgent': true,
    },
    {
      'id': '2',
      'route': 'Pizza Corner → Lumumba Hall',
      'items': 'Margherita Pizza + Drinks',
      'earning': 6200,
      'distance': 3.1,
      'time': 12,
      'isUrgent': false,
    },
  ];

  Map<String, dynamic>? _currentDelivery = {
    'id': 'current_1',
    'route': 'Healthy Bites → Nkrumah Hall',
    'items': 'Caesar Salad + Smoothie',
    'earning': 3200,
    'timeRemaining': 15,
    'customerPhone': '+256700123456',
  };

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
    // Add refresh logic here - typically fetch from API
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

  void _acceptDelivery(Map<String, dynamic> delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Accept Delivery'),
        content: Text('Do you want to accept this delivery for UGX ${delivery['earning']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentDelivery = {
                  'id': delivery['id'],
                  'route': delivery['route'],
                  'items': delivery['items'],
                  'earning': delivery['earning'],
                  'timeRemaining': delivery['time'],
                  'customerPhone': '+256700123456', // Mock phone
                };
                _availableDeliveries.removeWhere((d) => d['id'] == delivery['id']);
                _hasActiveDelivery = true;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delivery accepted! Navigate to pickup location.'),
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

  void _startNavigation() {
    if (_currentDelivery != null) {
      // Here you would integrate with maps (Google Maps, Apple Maps, etc.)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening navigation to ${_currentDelivery!['route']}'),
          backgroundColor: Colors.blue,
        ),
      );
      
      // Example: Launch external maps app
      // You can use url_launcher package for this
      // launch('https://maps.google.com/...');
    }
  }

  void _callCustomer() {
    if (_currentDelivery != null) {
      // Here you would make a phone call
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Calling ${_currentDelivery!['customerPhone']}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Example: Launch phone dialer
      // You can use url_launcher package for this
      // launch('tel:${_currentDelivery!['customerPhone']}');
    }
  }

  void _handleBottomNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0:
        // Already on home - do nothing
        break;
      case 1:
        // Navigate to deliveries screen
        Navigator.pushNamed(context, '/deliveries');
        break;
      case 2:
        // Navigate to earnings screen
        Navigator.pushNamed(context, '/earnings');
        break;
      case 3:
        // Navigate to profile screen
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MakBites Delivery', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/help');
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'logout':
                  _logout(context);
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'support':
                  Navigator.pushNamed(context, '/support');
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'support',
                  child: Row(
                    children: [
                      Icon(Icons.support_agent, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Support'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red)),
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
              
              // Recent Deliveries
              _buildRecentDeliveriesSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _hasActiveDelivery
          ? FloatingActionButton.extended(
              onPressed: _startNavigation,
              backgroundColor: AppColors.success,
              icon: Icon(Icons.navigation, color: AppColors.white),
              label: Text('Navigate', style: TextStyle(color: AppColors.white)),
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
                size: 12
              ),
              SizedBox(width: 8),
              Text(
                _isOnline ? 'Online - Ready for Deliveries' : 'Offline',
                style: AppTextStyles.body.copyWith(color: AppColors.white),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Good Morning, Rider!',
            style: AppTextStyles.subHeader.copyWith(color: AppColors.white),
          ),
          SizedBox(height: 4),
          Text(
            _isOnline 
                ? 'You\'re ready to start earning today'
                : 'Go online to start receiving deliveries',
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
        Text('Today\'s Performance', style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Deliveries', 
              '${_todayStats['deliveries']}', 
              Icons.local_shipping, 
              AppColors.success
            )),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Earnings', 
              'UGX ${(_todayStats['earnings'] / 1000).toStringAsFixed(0)}K', 
              Icons.account_balance_wallet, 
              AppColors.warning
            )),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              'Distance', 
              '${_todayStats['distance']} km', 
              Icons.route, 
              AppColors.primary
            )),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Rating', 
              '${_todayStats['rating']}', 
              Icons.star, 
              AppColors.warning
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildQuickAction(
              _isOnline ? 'Go Offline' : 'Go Online',
              Icons.power_settings_new,
              _isOnline ? Colors.red : Colors.green,
              _toggleOnlineStatus,
            )),
            SizedBox(width: 12),
            Expanded(child: _buildQuickAction(
              'View Map',
              Icons.map,
              AppColors.primary,
              () => Navigator.pushNamed(context, '/map'),
            )),
            SizedBox(width: 12),
            Expanded(child: _buildQuickAction(
              'Earnings\nHistory',
              Icons.history,
              AppColors.success,
              () => Navigator.pushNamed(context, '/earnings'),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentDeliverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Delivery', style: AppTextStyles.subHeader),
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
            Text('Available Deliveries', style: AppTextStyles.subHeader),
            TextButton(
              onPressed: _refreshDeliveries,
              child: Text('Refresh', style: TextStyle(color: AppColors.primary)),
            ),
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
                    'No deliveries available',
                    style: TextStyle(color: Colors.grey),
                  ),
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

  Widget _buildRecentDeliveriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Deliveries', style: AppTextStyles.subHeader),
        SizedBox(height: 16),
        ...List.generate(_recentDeliveries.length, (index) {
          final delivery = _recentDeliveries[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildRecentDeliveryCard(
              delivery['route'],
              delivery['earning'],
              delivery['status'],
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

  Widget _buildDeliveryCard(Map<String, dynamic> delivery) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: delivery['isUrgent'] ? AppColors.warning : Colors.grey.withOpacity(0.2),
          width: delivery['isUrgent'] ? 2 : 1,
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
                  delivery['route'],
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (delivery['isUrgent'])
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'URGENT',
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
          Text(delivery['items'], style: TextStyle(color: Colors.grey)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'UGX ${delivery['earning']}',
                    style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.route, color: Colors.grey, size: 16),
                  SizedBox(width: 4),
                  Text('${delivery['distance']} km', style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 12),
                  Icon(Icons.access_time, color: Colors.grey, size: 16),
                  SizedBox(width: 4),
                  Text('${delivery['time']} min', style: TextStyle(color: Colors.grey)),
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
                _isOnline ? 'Accept Delivery' : 'Go Online First',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDeliveryCard() {
    if (_currentDelivery == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Active Delivery',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _currentDelivery!['route'],
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(_currentDelivery!['items'], style: TextStyle(color: Colors.grey)),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.success, size: 16),
              SizedBox(width: 4),
              Text(
                'UGX ${_currentDelivery!['earning']}',
                style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Icon(Icons.access_time, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                '${_currentDelivery!['timeRemaining']} min remaining',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _startNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Navigate', style: AppTextStyles.button),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _callCustomer,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Call Customer',
                    style: TextStyle(color: AppColors.primary),
                  ),
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
            'UGX $earning',
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
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Deliveries',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: _handleBottomNavTap,
    );
  }
}