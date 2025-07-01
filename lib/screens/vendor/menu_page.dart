import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'add_item.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with SingleTickerProviderStateMixin {

  void _showAddMenuItemDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AddMenuItemForm(),
    );
  }

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
              color: AppColors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
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
            onPressed: _showAddMenuItemDialog,

            backgroundColor: AppColors.primary,
            label: Text('Add new item',style: TextStyle(color:AppColors.white),),
            icon: Icon(Icons.add,color:AppColors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuList(List<Map<String, dynamic>> items) {
    return Container(
      color: AppColors.white,
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
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Icon(iconData, color: AppColors.primary, size: 30),
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
                    child: Text(item['status'], style: TextStyle(color: AppColors.white, fontSize: 12)),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.black,
                    side: BorderSide(color: Colors.grey),
                  ),
                  child: Text("Mark Available"),
                ),
                SizedBox(height: 6),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text("Remove", style: TextStyle(color: AppColors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
