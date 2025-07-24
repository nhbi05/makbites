import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'menu_page.dart';
import 'orders.dart';
import 'profile.dart';

class VendorHomePage extends StatefulWidget {
  @override
  _VendorHomePageState createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  late String vendorRestaurantId;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.amber[100],
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    vendorRestaurantId = FirebaseAuth.instance.currentUser!.uid;

    _pages = [
      _buildDashboard(),
      OrdersPage(vendorRestaurantId: vendorRestaurantId),
      MenuPage(),
      Container(),
    ];

    saveDeviceToken();

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(user.uid)
            .update({'deviceToken': newToken});
        print('🔄 Device token refreshed and updated: $newToken');
      }
    });

    requestNotificationPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Received a message while app is in the foreground!');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print('Notification Title: ${message.notification!.title}');
        print('Notification Body: ${message.notification!.body}');
        // Optional: Show an in-app alert/snackbar here
      }
    });
  }

  Future<void> requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission for notifications');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('ℹ️ User granted provisional permission');
    } else {
      print('❌ User declined or has not accepted notification permission');
    }
  }

  // Save device token to Firestore
  Future<void> saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();

    if (token != null) {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .update({
        'deviceToken': token,
      });

      print('✅ Device token saved: $token');
    } else {
      print('❌ Could not get device token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          'MukBites Vendor',
          style: AppTextStyles.header.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          Icon(Icons.notifications, color: AppColors.white),
          SizedBox(width: 10),
          Icon(Icons.settings, color: AppColors.white),
          SizedBox(width: 10),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerSection(),
          _metricsGrid(),
          _sectionTitle("Recent Orders"),
          _orderCard("#1234", "Matooke and Rice", "John Doe", "Preparing"),
          _sectionTitle("Popular Orders"),
          _orderCard("#1221", "Chapati and Beans", "Jane Smith", "Completed"),
          _orderCard("#1222", "Chicken Pilau", "Alex Kim", "Completed"),
        ],
      ),
    );
  }

  Widget _headerSection() {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.all(16),
      child: Text(
        "Good Morning, Chef!\nReady to serve delicious meals today?",
        style: AppTextStyles.body.copyWith(color: AppColors.white),
      ),
    );
  }

  Widget _metricsGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _metricCard(Icons.shopping_cart, "23", "Today's Orders", AppColors.success),
          _metricCard(Icons.attach_money, "UGX 200K", "Revenue", Colors.amber),
          _metricCard(Icons.timelapse, "5", "Pending Orders", AppColors.primary),
          _metricCard(Icons.star, "4.8", "Rating", Colors.amber),
        ],
      ),
    );
  }

  Widget _metricCard(IconData icon, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppTextStyles.subHeader),
              Text(label, style: AppTextStyles.body.copyWith(fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(title, style: AppTextStyles.subHeader),
    );
  }

  Widget _orderCard(String id, String meal, String customer, String status) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(Icons.fastfood),
        title: Text(meal, style: AppTextStyles.body),
        subtitle: Text(customer, style: AppTextStyles.body.copyWith(fontSize: 14)),
        trailing: Chip(
          label: Text(status),
          backgroundColor:
          status == "Preparing" ? Colors.orange[100] : Colors.green[100],
        ),
      ),
    );
  }
}
