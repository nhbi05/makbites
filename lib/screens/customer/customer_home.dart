import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';

class CustomerHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MakBites'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined),
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
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning!',
                    style: AppTextStyles.subHeader,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'What would you like to eat today?',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
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
                Expanded(child: _buildQuickAction('Schedule\nMeals', Icons.schedule, AppColors.primary)),
                SizedBox(width: 12),
                Expanded(child: _buildQuickAction('Browse\nRestaurants', Icons.restaurant, AppColors.success)),
                SizedBox(width: 12),
                Expanded(child: _buildQuickAction('Order\nHistory', Icons.history, AppColors.warning)),
              ],
            ),
            SizedBox(height: 24),
            
            // Popular Restaurants
            Text(
              'Popular Near Campus',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            _buildRestaurantCard('Campus Grill', 'Burgers • Fries • Drinks', 4.5, '15-20 min'),
            SizedBox(height: 12),
            _buildRestaurantCard('Healthy Bites', 'Salads • Wraps • Smoothies', 4.8, '10-15 min'),
            SizedBox(height: 12),
            _buildRestaurantCard('Pizza Corner', 'Pizza • Pasta • Italian', 4.3, '20-25 min'),
            SizedBox(height: 24),
            
            // Recent Orders Section
            Text(
              'Your Recent Orders',
              style: AppTextStyles.subHeader,
            ),
            SizedBox(height: 16),
            _buildRecentOrderCard('Beef Burger Combo', 'Campus Grill', 'UGX 25,000', 'Delivered'),
            SizedBox(height: 12),
            _buildRecentOrderCard('Caesar Salad', 'Healthy Bites', 'UGX 18,000', 'Delivered'),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(0),
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

  Widget _buildRestaurantCard(String name, String cuisine, double rating, String time) {
    return GestureDetector(
      onTap: () {
        // Navigate to restaurant details
      },
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restaurant, color: AppColors.primary),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.subHeader.copyWith(fontSize: 16)),
                  SizedBox(height: 4),
                  Text(cuisine, style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: AppColors.warning, size: 16),
                      SizedBox(width: 4),
                      Text(rating.toString(), style: TextStyle(fontWeight: FontWeight.w500)),
                      SizedBox(width: 16),
                      Icon(Icons.access_time, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text(time, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(String item, String restaurant, String price, String status) {
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
                Text(item, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text(restaurant, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
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
          icon: Icon(Icons.search),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
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