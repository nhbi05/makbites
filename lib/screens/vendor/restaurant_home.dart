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
  String? restaurantName;
  String? profileImageUrl;
  bool isRestaurantOpen = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.amber[100],
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    _initializeRestaurant(); // ✅ Auto-create if missing
    _fetchVendorData();
  }

  /// ✅ Auto-create restaurant document if missing (with correct name from users collection)
  Future<void> _initializeRestaurant() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final restaurantDoc = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid);
      final doc = await restaurantDoc.get();

      if (!doc.exists) {
        // ✅ Fetch name from 'users' collection
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userName = userDoc.data()?['name'] ?? 'Unnamed Restaurant';

        await restaurantDoc.set({
          'name': userName, // ✅ Correct name
          'profileImage': '',
          'location': '',
          'isOpen': true,
        });
        print('Restaurant created automatically with correct name.');
      } else {
        // ✅ Fix missing fields in existing document
        final data = doc.data()!;
        final Map<String, dynamic> updates = {};

        if (!data.containsKey('name')) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          updates['name'] = userDoc.data()?['name'] ?? 'Unnamed Restaurant';
        }
        if (!data.containsKey('profileImage')) {
          updates['profileImage'] = '';
        }
        if (!data.containsKey('location')) {
          updates['location'] = '';
        }
        if (!data.containsKey('isOpen')) {
          updates['isOpen'] = true;
        }

        if (updates.isNotEmpty) {
          await restaurantDoc.update(updates);
          print('Existing restaurant updated with missing fields.');
        }
      }
    }
  }

  /// ✅ Fetch restaurant data
  Future<void> _fetchVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .get();
      setState(() {
        restaurantName = doc.data()?['name'] ?? 'Restaurant';
        profileImageUrl = doc.data()?['profileImage'];
        isRestaurantOpen = doc.data()?['isOpen'] ?? true;
      });
    }
  }

  /// ✅ Update restaurant open/closed status
  Future<void> _updateRestaurantStatus(bool status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.uid)
          .update({'isOpen': status});
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
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _currentIndex == 0
          ? _buildDashboard()
          : _currentIndex == 1
          ? OrdersPage(vendorRestaurantId: restaurantName ?? '')
          : _currentIndex == 2
          ? MenuPage()
          : ProfilePage(),
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
          _restaurantStatusCard(),
          _sectionTitle("Recent Orders"),
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
                "No recent orders yet.", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _headerSection() {
    String greeting;
    final hour = DateTime
        .now()
        .hour;
    if (hour < 12) {
      greeting = "Good Morning, Chef!\nReady to serve delicious meals today?";
    } else if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon, Chef!\nReady for the lunch rush?";
    } else {
      greeting =
      "Good Evening, Chef!\nReady to serve the last meals of the day?";
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

  /// ✅ Restaurant Status Toggle Card
  Widget _restaurantStatusCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isRestaurantOpen ? "Restaurant Open" : "Restaurant Closed",
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            Switch(
              value: isRestaurantOpen,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  isRestaurantOpen = value;
                });
                _updateRestaurantStatus(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(title, style: AppTextStyles.subHeader),
    );
  }
}