import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class DeliveryHomeScreen extends StatefulWidget {
  @override
  _DeliveryHomeScreenState createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  Future<void> _logout(BuildContext context) async {
    try {
      bool confirm = await showDialog(
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
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MakBites Delivery'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
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
                      Icon(Icons.circle, color: Colors.green, size: 12),
                      SizedBox(width: 8),
                      Text(
                        'Online - Ready for Deliveries',
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
                    'You\'re ready to start earning today',
                    style: AppTextStyles.body.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Today's Stats
            Text(
              'Today\'s Performance',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Deliveries', '12', Icons.local_shipping, AppColors.success)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard('Earnings', 'UGX 48K', Icons.account_balance_wallet, AppColors.warning)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Distance', '45 km', Icons.route, AppColors.primary)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard('Rating', '4.9', Icons.star, AppColors.warning)),
              ],
            ),
            SizedBox(height: 24),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildQuickAction('Go Offline', Icons.power_settings_new, Colors.red)),
                SizedBox(width: 12),
                Expanded(child: _buildQuickAction('View Map', Icons.map, AppColors.primary)),
                SizedBox(width: 12),
                Expanded(child: _buildQuickAction('Earnings\nHistory', Icons.history, AppColors.success)),
              ],
            ),
            SizedBox(height: 24),
            
            // Available Deliveries
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Deliveries',
                  style: AppTextStyles.subHeader,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Refresh', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildDeliveryCard(
              'Campus Grill → Mary Stuart Hall',
              'Beef Burger Combo + Fries',
              'UGX 4,500',
              '2.3 km',
              '8 min',
              true,
            ),
            SizedBox(height: 12),
            _buildDeliveryCard(
              'Pizza Corner → Lumumba Hall',
              'Margherita Pizza + Drinks',
              'UGX 6,200',
              '3.1 km',
              '12 min',
              false,
            ),
            SizedBox(height: 24),
            
            // Current Delivery (if any)
            Text(
              'Current Delivery',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            _buildCurrentDeliveryCard(),
            SizedBox(height: 24),
            
            // Recent Deliveries
            Text(
              'Recent Deliveries',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            _buildRecentDeliveryCard('Healthy Bites → Africa Hall', 'UGX 3,800', 'Delivered'),
            SizedBox(height: 12),
            _buildRecentDeliveryCard('Campus Grill → Complex Hall', 'UGX 4,200', 'Delivered'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Start delivery or navigate to map
        },
        backgroundColor: AppColors.success,
        icon: Icon(Icons.navigation, color: AppColors.white),
        label: Text('Start Navigation', style: TextStyle(color: AppColors.white)),
      ),
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
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Add navigation logic here
      },
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

  Widget _buildDeliveryCard(String route, String items, String earning, String distance, String time, bool isUrgent) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? AppColors.warning : Colors.grey.withOpacity(0.2),
          width: isUrgent ? 2 : 1,
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
                  route,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (isUrgent)
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
          Text(items, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: AppColors.success, size: 16),
                  SizedBox(width: 4),
                  Text(earning, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.route, color: Colors.grey, size: 16),
                  SizedBox(width: 4),
                  Text(distance, style: TextStyle(color: Colors.grey)),
                  SizedBox(width: 12),
                  Icon(Icons.access_time, color: Colors.grey, size: 16),
                  SizedBox(width: 4),
                  Text(time, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Accept delivery logic
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Accept Delivery',
                style: AppTextStyles.button,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentDeliveryCard() {
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
            'Healthy Bites → Nkrumah Hall',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text('Caesar Salad + Smoothie', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.success, size: 16),
              SizedBox(width: 4),
              Text('UGX 3,200', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
              Spacer(),
              Icon(Icons.access_time, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text('15 min remaining', style: TextStyle(color: Colors.grey)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
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
                  onPressed: () {},
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

  Widget _buildRecentDeliveryCard(String route, String earning, String status) {
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
            earning,
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
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
      onTap: (index) {
        // Handle navigation
      },
    );
  }
}