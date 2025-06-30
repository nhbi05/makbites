import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> foodItems = [
    {
      'name': 'Matooke',
      'price': null,
      'status': 'Unavailable',
      'type': 'food',
    },
    {
      'name': 'Chicken',
      'price': 'UGX 4000',
      'status': 'Unavailable',
      'type': 'food',
    },
  ];

  final List<Map<String, dynamic>> drinkItems = [
    {
      'name': 'Juice',
      'price': 'UGX 2500',
      'status': 'Unavailable',
      'type': 'drink',
    },
    {
      'name': 'Soda',
      'price': 'UGX 2000',
      'status': 'Unavailable',
      'type': 'drink',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.red,
                tabs: const [
                  Tab(text: 'Foods'),
                  Tab(text: 'Drinks'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMenuList(foodItems),
                  _buildMenuList(drinkItems),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Add your logic here
            },
            backgroundColor: Colors.orange,
            label: Text('Add new item',style: TextStyle(color:Colors.white),),
            icon: Icon(Icons.add,color:Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(List<Map<String, dynamic>> items) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) => _menuItem(items[index]),
      ),
    );
  }

  Widget _menuItem(Map<String, dynamic> item) {
    IconData iconData =
    item['type'] == 'drink' ? Icons.local_drink : Icons.fastfood;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(iconData, color: Colors.red, size: 30),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (item['price'] != null)
                    Text(item['price'], style: TextStyle(color: Colors.orange)),
                  Container(
                    margin: EdgeInsets.only(top: 6),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(item['status'], style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: BorderSide(color: Colors.grey),
                  ),
                  child: Text("Mark Available"),
                ),
                SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Remove", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
