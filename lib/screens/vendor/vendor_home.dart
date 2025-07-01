import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'menu_page.dart';
import 'analytics.dart';

class VendorHomePage extends StatefulWidget {
  @override
  _VendorHomePageState createState() => _VendorHomePageState();
}

class _VendorHomePageState extends State<VendorHomePage> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Set status bar style to match revenue container
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.amber[100],
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    _pages = [
      _buildDashboard(),
      Placeholder(), // Replace with OrdersPage()
      MenuPage(),
      Placeholder(), // Replace with ProfilePage()
    ];
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
          setState(() {
            _currentIndex = index;
          });
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
          _quickActions(),

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

  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = 2; // Navigate to MenuPage
              });
            },
            child: _quickAction(Icons.edit, "Manage Menu", AppColors.primary),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsPage()),
              );
            },
            child: _quickAction(Icons.bar_chart, "View Analytics", Colors.amber),
          ),

        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        SizedBox(height: 6),
        Text(label, style: AppTextStyles.body.copyWith(fontSize: 12)),
      ],
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
