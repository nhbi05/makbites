import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? restaurantName;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.amber[100],
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    _fetchVendorData();
    _pages = [
      _buildDashboard(),
      OrdersPage(vendorRestaurantId: restaurantName ?? ''),
      MenuPage(),
      ProfilePage(),
    ];
  }

  Future<void> _fetchVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        restaurantName = doc.data()?['name'] ?? 'Restaurant';
        profileImageUrl = doc.data()?['profileImage'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          restaurantName ?? 'Loading...',
          style: AppTextStyles.header.copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: profileImageUrl != null && profileImageUrl!.isNotEmpty
                ? CircleAvatar(
              backgroundImage: NetworkImage(profileImageUrl!),
            )
                : const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/vendor-profile');
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Orders'),
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
    String greeting;
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good Morning, Chef!\nReady to serve delicious meals today?";
    } else if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon, Chef!\nReady for the lunch rush?";
    } else {
      greeting = "Good Evening, Chef!\nReady to serve the last meals of the day?";
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          greeting,
          style: AppTextStyles.body.copyWith(color: Colors.black),
        ),
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
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _metricCard(
              Icons.shopping_cart, "23", "Today's Orders", AppColors.success),
          _metricCard(Icons.attach_money, "UGX 200K", "Revenue", Colors.amber),
          _metricCard(
              Icons.timelapse, "5", "Pending Orders", AppColors.primary),
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
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
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
    Color statusColor;
    switch (status) {
      case "preparing":
        statusColor = Colors.orange;
        break;
      case "completed":
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.fastfood),
        title: Text(meal, style: AppTextStyles.body),
        subtitle: Text(
            customer, style: AppTextStyles.body.copyWith(fontSize: 14)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            // Light background with opacity
            borderRadius: BorderRadius.circular(16), // More curved
          ),
          child: Text(
            status,
            style: AppTextStyles.body.copyWith(
              color: statusColor, // Colored text
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
