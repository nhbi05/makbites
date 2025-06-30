import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'menu_page.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'MuK Bites Vendor',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red[400],
        actions: [
          Icon(Icons.notifications, color: Colors.white),
          SizedBox(width: 10),
          Icon(Icons.settings, color: Colors.white),
          SizedBox(width: 10),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.red,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerSection(),
        _metricsGrid(),
        _quickActions(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Recent Orders"),
                _orderCard("#1234", "Matooke and Rice", "John Doe", "Preparing"),
                _sectionTitle("Popular Orders"),
                _orderCard("#1221", "Chapati and Beans", "Jane Smith", "Completed"),
                _orderCard("#1222", "Chicken Pilau", "Alex Kim", "Completed"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerSection() {
    return Container(
      width: double.infinity,
      color: Colors.red[300],
      padding: EdgeInsets.all(16),
      child: Text(
        "Good Morning, Chef!\nReady to serve delicious meals today?",
        style: TextStyle(color: Colors.white, fontSize: 16),
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
          _metricCard(Icons.shopping_cart, "23", "Today's Orders", Colors.green),
          _metricCard(Icons.attach_money, "UGX 200K", "Revenue", Colors.orange),
          _metricCard(Icons.timelapse, "5", "Pending Orders", Colors.pink),
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
              Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(fontSize: 12)),
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
          //_quickAction(Icons.add, "Add New Item", Colors.green),
          _quickAction(Icons.edit, "Manage Menu", Colors.red),
          _quickAction(Icons.bar_chart, "View Analytics", Colors.orange),
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
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _orderCard(String id, String meal, String customer, String status) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(Icons.fastfood),
        title: Text(meal),
        subtitle: Text(customer),
        trailing: Chip(
          label: Text(status),
          backgroundColor:
          status == "Preparing" ? Colors.orange[100] : Colors.green[100],
        ),
      ),
    );
  }
}
