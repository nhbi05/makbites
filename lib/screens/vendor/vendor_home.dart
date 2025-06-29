import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class VendorHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MakBites Vendor'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, Chef!',
                    style: AppTextStyles.subHeader.copyWith(color: AppColors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ready to serve delicious meals today?',
                    style: AppTextStyles.body.copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Stats Overview
            Row(
              children: [
                Expanded(child: _buildStatCard('Today\'s Orders', '23', Icons.receipt_long, AppColors.success)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard('Revenue', 'UGX 450K', Icons.attach_money, AppColors.warning)),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatCard('Pending Orders', '5', Icons.pending_actions, AppColors.primary)),
                SizedBox(width: 12),
                Expanded(child: _buildStatCard('Rating', '4.8', Icons.star, AppColors.warning)),
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
                Expanded(child: _buildQuickAction('Add New\nItem', Icons.add_circle, AppColors.success)),
                SizedBox(width: 12),
                Expanded(child: _buildQuickAction('Manage\nMenu', Icons.restaurant_menu, AppColors.primary)),
                SizedBox(width: 12),
                Expanded(child: _buildQuickAction('View\nAnalytics', Icons.analytics, AppColors.warning)),
              ],
            ),
            SizedBox(height: 24),
            
            // Recent Orders
            Text(
              'Recent Orders',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            _buildOrderCard('Order #1234', 'Beef Burger Combo', 'John Doe', 'UGX 25,000', 'Preparing', AppColors.warning),
            SizedBox(height: 12),
            _buildOrderCard('Order #1235', 'Caesar Salad', 'Jane Smith', 'UGX 18,000', 'Ready', AppColors.success),
            SizedBox(height: 12),
            _buildOrderCard('Order #1236', 'Margherita Pizza', 'Mike Johnson', 'UGX 32,000', 'Delivered', Colors.grey),
            SizedBox(height: 24),
            
            // Popular Items
            Text(
              'Your Popular Items',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            _buildPopularItemCard('Beef Burger Combo', 'UGX 25,000', '45 orders today'),
            SizedBox(height: 12),
            _buildPopularItemCard('Chicken Wings', 'UGX 20,000', '32 orders today'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(0),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new item
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: AppColors.white),
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
              fontSize: 20,
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
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String orderNum, String item, String customer, String amount, String status, Color statusColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderNum, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.fastfood, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(item, style: AppTextStyles.body)),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(customer, style: TextStyle(color: Colors.grey))),
              Text(amount, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopularItemCard(String name, String price, String orders) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.fastfood, color: AppColors.primary),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text(orders, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Text(price, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
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
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
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