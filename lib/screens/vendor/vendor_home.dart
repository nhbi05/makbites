import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'menu_page.dart';
//import 'analytics.dart';
import 'orders.dart';
import 'profile.dart'; // Make sure this exists
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VendorHomePage extends StatefulWidget {
  @override
  _VendorHomePageState createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  int _currentIndex = 0;
  late List<Widget> _pages;
  String? _restaurantId;
  Map<String, String> _userIdToName = {};

  @override
  void initState() {
    super.initState();
    _initFCM();
    _getAndSaveFcmToken();
    _loadRestaurantId();
    _loadUsers();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.amber[100],
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _pages = [
      _buildDashboard(),
      Container(),
      MenuPage(),
      Container(), // Placeholder for Profile tab, we push manually
    ];
  }

  void _initFCM() async {
    // Request permissions (iOS)
    await FirebaseMessaging.instance.requestPermission();

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message in the foreground!');
      print('Message data:  [message.data]');
      if (message.notification != null) {
        print('Message also contained a notification:  [message.notification]');
      }
      // Optionally show a local notification here
    });

    // Listen for messages when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      // Handle navigation or other logic here
    });
  }

  void _getAndSaveFcmToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    _saveTokenToFirestore(token);
    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('New FCM Token: $newToken');
      _saveTokenToFirestore(newToken);
    });
  }

  void _saveTokenToFirestore(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance
          .collection('users') // Change to your actual collection name for vendors if different
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  Future<void> _loadRestaurantId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _restaurantId = user.uid;
    });
  }

  Future<void> _loadUsers() async {
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final usersMap = <String, String>{};
    for (var doc in userSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('uid') && data.containsKey('name')) {
        usersMap[data['uid']] = data['name'];
      }
    }
    setState(() {
      _userIdToName = usersMap;
    });
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
          _recentOrdersList(),
          _sectionTitle("Popular Orders"),
          _orderCard("#1221", "Chapati and Beans", "Jane Smith", "Completed"),
          _orderCard("#1222", "Chicken Pilau", "Alex Kim", "Completed"),
        ],
      ),
    );
  }

  Widget _recentOrdersList() {
    if (_restaurantId == null) {
      return Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant', isEqualTo: _restaurantId)
          .orderBy('clientTimestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('No recent orders found.', style: AppTextStyles.body),
          );
        }
        final now = DateTime.now();
        // Filter out orders with scheduledSendTime in the future
        final filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final scheduledSendTime = data['scheduledSendTime'];
          if (scheduledSendTime != null && scheduledSendTime is Timestamp) {
            return scheduledSendTime.toDate().isBefore(now) || scheduledSendTime.toDate().isAtSameMomentAs(now);
          }
          return true;
        }).take(5).toList();
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('No recent orders found.', style: AppTextStyles.body),
          );
        }
        return Column(
          children: filtered.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final meal = data['food'] ?? 'Unknown';
            final userId = data['userId'] ?? 'Unknown';
            final customer = _userIdToName[userId] ?? userId;
            final status = data['status'] ?? 'Pending';
            return _orderCard(doc.id, meal, customer, status);
          }).toList(),
        );
      },
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
    Color chipColor;
    if (status.toLowerCase() == "preparing" || status.toLowerCase() == "start preparing") {
      chipColor = Colors.orange[100]!;
    } else if (status.toLowerCase() == "completed") {
      chipColor = Colors.green[100]!;
    } else if (status.toLowerCase() == "cancelled") {
      chipColor = Colors.grey[300]!;
    } else {
      chipColor = Colors.blue[100]!;
    }
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(Icons.fastfood),
        title: Text(meal, style: AppTextStyles.body),
        subtitle: Text(customer, style: AppTextStyles.body.copyWith(fontSize: 14)),
        trailing: Chip(
          label: Text(status),
          backgroundColor: chipColor,
        ),
      ),
    );
  }
}
