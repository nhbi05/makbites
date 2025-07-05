import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_event.dart';
import 'package:intl/intl.dart';
import 'order_history_screen.dart';
import '../../config/routes.dart';

class CustomerHomeScreen extends StatefulWidget {
  @override
  _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    String greeting() {
      final hour = DateTime.now().hour;
      if (hour < 12) {
        return 'Good Morning!';
      } else if (hour < 17) {
        return 'Good Afternoon!';
      } else {
        return 'Good Evening!';
      }
    }
    return FutureBuilder<List<UserEvent>>(
      future: _fetchTodayEvents(),
      builder: (context, snapshot) {
        final today = DateTime.now();
        final events = snapshot.data ?? [];
        final mealTimes = _findOptimalMealTimes(events, today);
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.03), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Container(
                  width: double.infinity,
                    padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.08),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          greeting(),
                          style: AppTextStyles.subHeader.copyWith(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                        SizedBox(height: 8),
                      Text(
                          'Discover delicious meals and order from your favorite campus restaurants!',
                          style: AppTextStyles.body.copyWith(fontSize: 16, color: AppColors.textDark.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                  SizedBox(height: 32),
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
                  SizedBox(height: 32),
                  Divider(thickness: 1.2, color: AppColors.primary.withOpacity(0.15)),
                SizedBox(height: 24),
                // Popular Restaurants
                Text(
                  'Popular Near Campus',
                    style: AppTextStyles.subHeader.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                  SizedBox(height: 18),
                  ...[
                    {'name': 'MK Catering Services', 'location': 'Africa Hall', 'image': 'assets/images/MKcatering.png'},
                    {'name': 'Lumumba Cafe', 'location': 'Lumumba Hall', 'image': 'assets/images/Lumumbacafe.png'},
                    {"name": "Ssalongo's", 'location': 'Makerere Kikoni', 'image': "assets/images/ssalongo's.png"},
                    {'name': 'Freddoz', 'location': 'Wandegeya', 'image': 'assets/images/freddoz.png'},
                    {'name': 'Fresh Hot', 'location': 'Kikumi kikumi', 'image': 'assets/images/freshhot.png'},
                  ].map((restaurant) => _buildModernRestaurantCard(restaurant['name']!, restaurant['location']!, restaurant['image']!)).toList(),
                  SizedBox(height: 32),
              ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(0),
        );
      },
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        if (title.contains('Schedule')) {
          Navigator.pushNamed(context, AppRoutes.weeklyScheduleSetup);
        } else if (title.contains('Browse')) {
          // Navigate to restaurant browse
        } else if (title.contains('History')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
          );
        }
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
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderHistoryScreen()),
          );
        }
        // Handle other navigation as needed
      },
    );
  }

  Future<List<UserEvent>> _fetchTodayEvents() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day, 0, 0);
    final end = DateTime(today.year, today.month, today.day, 23, 59);
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: user.uid)
        .get();
    final events = snapshot.docs.map((doc) => UserEvent.fromMap(doc.data())).toList();
    return events.where((e) => e.startTime.isAfter(start) && e.startTime.isBefore(end)).toList();
  }

  Map<String, DateTime?> _findOptimalMealTimes(List<UserEvent> events, DateTime day) {
    // Define meal windows
    final windows = {
      'breakfast': [TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 11, minute: 0)],
      'lunch': [TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 17, minute: 0)],
      'supper': [TimeOfDay(hour: 18, minute: 0), TimeOfDay(hour: 23, minute: 0)],
    };
    Map<String, DateTime?> result = {};
    for (final meal in windows.keys) {
      final start = windows[meal]![0];
      final end = windows[meal]![1];
      final windowStart = DateTime(day.year, day.month, day.day, start.hour, start.minute);
      final windowEnd = DateTime(day.year, day.month, day.day, end.hour, end.minute);
      final busy = events.where((e) => e.startTime.isBefore(windowEnd) && e.endTime.isAfter(windowStart)).toList();
      final gaps = _findFreeGaps(windowStart, windowEnd, busy);
      DateTime? mealStart;
      for (final g in gaps) {
        if (g.end.difference(g.start).inMinutes >= 30) {
          mealStart = g.start;
          break;
        }
      }
      result[meal] = mealStart;
    }
    return result;
  }

  List<DateTimeRange> _findFreeGaps(DateTime windowStart, DateTime windowEnd, List<UserEvent> events) {
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    List<DateTimeRange> gaps = [];
    DateTime current = windowStart;
    for (final event in events) {
      if (event.startTime.isAfter(current)) {
        gaps.add(DateTimeRange(start: current, end: event.startTime));
      }
      if (event.endTime.isAfter(current)) {
        current = event.endTime;
      }
    }
    if (current.isBefore(windowEnd)) {
      gaps.add(DateTimeRange(start: current, end: windowEnd));
    }
    return gaps;
  }

  Widget _buildMealTimeRow(String label, DateTime? time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Text(time != null ? DateFormat('hh:mm a').format(time) : 'No free slot', style: AppTextStyles.body),
        ],
      ),
    );
  }

  Widget _buildSimpleRestaurantCard(String name, String location) {
    return GestureDetector(
      onTap: () {
        // Navigate to restaurant details or do nothing
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
                  Text(location, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRestaurantCard(String name, String location, String imagePath) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.subHeader.copyWith(fontSize: 17, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.success, size: 18),
                        SizedBox(width: 4),
                        Text(location, style: AppTextStyles.body.copyWith(color: AppColors.textDark.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}