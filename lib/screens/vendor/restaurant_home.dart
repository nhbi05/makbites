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
  String? vendorId;
  bool isRestaurantOpen = true;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.amber[100],
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _initializeRestaurant();
    await _fetchVendorData();
    setState(() {
      _isDataLoaded = true;
    });
  }

  Future<void> _initializeRestaurant() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      vendorId = user.uid;
      final restaurantDoc = FirebaseFirestore.instance.collection('restaurants').doc(user.uid);
      final doc = await restaurantDoc.get();

      if (!doc.exists) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userName = userDoc.data()?['name'] ?? 'Unnamed Restaurant';

        await restaurantDoc.set({
          'name': userName,
          'profileImage': '',
          'location': '',
          'isOpen': true,
          'vendorId': user.uid,
        });
      } else {
        final data = doc.data()!;
        final Map<String, dynamic> updates = {};

        if (!data.containsKey('name')) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
        if (!data.containsKey('vendorId')) {
          updates['vendorId'] = user.uid;
        }

        if (updates.isNotEmpty) {
          await restaurantDoc.update(updates);
        }
      }
    }
  }

  Future<void> _fetchVendorData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('restaurants').doc(user.uid).get();
      if (mounted) {
        setState(() {
          restaurantName = doc.data()?['name'] ?? 'Restaurant';
          profileImageUrl = doc.data()?['profileImage'];
          isRestaurantOpen = doc.data()?['isOpen'] ?? true;
          vendorId = user.uid;
        });
      }
    }
  }

  Future<void> _updateRestaurantStatus(bool status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('restaurants').doc(user.uid).update({'isOpen': status});
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
              onBackgroundImageError: (exception, stackTrace) {
                // Handle image load error silently
              },
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
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    if (!_isDataLoaded || vendorId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerSection(),
          _metricsGrid(),
          _restaurantStatusCard(),
          _sectionTitle("Recent Orders"),
          _recentOrdersList(),
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
          // Today's Orders - Fixed to filter in-memory
          StreamBuilder<QuerySnapshot>(
            stream: _getTodaysOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Today's Orders Error: ${snapshot.error}");
                return _metricCard(Icons.shopping_cart, "Error", "Today's Orders", Colors.red);
              }

              if (snapshot.hasData) {
                // Filter orders to only include today's orders
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day);

                final todayOrders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = data['clientTimestamp'] as Timestamp?;

                  if (timestamp != null) {
                    return timestamp.toDate().isAfter(startOfDay);
                  }
                  return false;
                }).toList();

                final count = todayOrders.length;
                return _metricCard(Icons.shopping_cart, "$count", "Today's Orders", AppColors.success);
              } else {
                return _metricCard(Icons.shopping_cart, "...", "Today's Orders", AppColors.success);
              }
            },
          ),

          // Revenue - Calculated from completed orders
          StreamBuilder<QuerySnapshot>(
            stream: _getVendorOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Revenue Error: ${snapshot.error}");
                return _metricCard(Icons.attach_money, "Error", "Revenue", Colors.red);
              }

              if (snapshot.hasData) {
                double totalRevenue = 0;
                final today = DateTime.now();
                final startOfDay = DateTime(today.year, today.month, today.day);

                for (var doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status']?.toString().toLowerCase() ?? '';
                  final timestamp = data['clientTimestamp'] as Timestamp?;

                  // Check if order is from today and completed
                  if (timestamp != null &&
                      timestamp.toDate().isAfter(startOfDay) &&
                      (status == 'completed' || status == 'delivered')) {
                    final price = data['foodPrice'];
                    if (price != null) {
                      if (price is int) {
                        totalRevenue += price.toDouble();
                      } else if (price is double) {
                        totalRevenue += price;
                      } else if (price is String) {
                        totalRevenue += double.tryParse(price) ?? 0;
                      }
                    }
                  }
                }

                return _metricCard(Icons.attach_money, "UGX ${totalRevenue.toStringAsFixed(0)}", "Revenue", Colors.amber);
              } else {
                return _metricCard(Icons.attach_money, "...", "Revenue", Colors.amber);
              }
            },
          ),

          // Delivered Orders Today - Fixed version with debugging
          StreamBuilder<QuerySnapshot>(
            stream: _getVendorOrdersStream(), // Using all orders stream instead of delivered-only
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Delivered Orders Error: ${snapshot.error}");
                return _metricCard(Icons.check_circle, "Error", "Delivered Today", Colors.red);
              }

              if (snapshot.hasData) {
                print("=== DELIVERED ORDERS DEBUG ===");
                print("Total orders fetched: ${snapshot.data!.docs.length}");

                // Get today's date range
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day);
                final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

                print("Today's date range: $startOfDay to $endOfDay");

                final todayDeliveredOrders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status']?.toString().toLowerCase() ?? '';

                  print("Order ${doc.id}: status='$status'");

                  // First check if status is delivered
                  if (status != 'delivered') {
                    return false;
                  }

                  // Then check multiple possible timestamp fields
                  Timestamp? orderTimestamp;

                  // Try different timestamp field names that might exist
                  if (data.containsKey('clientTimestamp') && data['clientTimestamp'] != null) {
                    orderTimestamp = data['clientTimestamp'] as Timestamp;
                    print("  Found clientTimestamp: ${orderTimestamp.toDate()}");
                  } else if (data.containsKey('timestamp') && data['timestamp'] != null) {
                    orderTimestamp = data['timestamp'] as Timestamp;
                    print("  Found timestamp: ${orderTimestamp.toDate()}");
                  } else if (data.containsKey('orderDate') && data['orderDate'] != null) {
                    orderTimestamp = data['orderDate'] as Timestamp;
                    print("  Found orderDate: ${orderTimestamp.toDate()}");
                  } else if (data.containsKey('deliveredAt') && data['deliveredAt'] != null) {
                    orderTimestamp = data['deliveredAt'] as Timestamp;
                    print("  Found deliveredAt: ${orderTimestamp.toDate()}");
                  } else {
                    print("  No timestamp found for delivered order ${doc.id}");
                    print("  Available fields: ${data.keys.toList()}");
                  }

                  if (orderTimestamp != null) {
                    final orderDate = orderTimestamp.toDate();
                    final isToday = orderDate.isAfter(startOfDay) && orderDate.isBefore(endOfDay);
                    print("  Order date: $orderDate, Is today: $isToday");
                    return isToday;
                  }

                  // If no timestamp found, include it anyway (might be recent)
                  print("  Including delivered order without timestamp: ${doc.id}");
                  return true;
                }).toList();

                final count = todayDeliveredOrders.length;
                print("Final delivered orders today count: $count");
                print("=== END DEBUG ===");

                return _metricCard(Icons.check_circle, "$count", "Delivered Today", AppColors.success);
              } else {
                return _metricCard(Icons.check_circle, "...", "Delivered Today", AppColors.success);
              }
            },
          ),

          // Cancelled Orders Today - Replaces the rating metric card
          StreamBuilder<QuerySnapshot>(
            stream: _getVendorOrdersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                print("Cancelled Orders Error: ${snapshot.error}");
                return _metricCard(Icons.cancel, "Error", "Cancelled ", Colors.red);
              }

              if (snapshot.hasData) {
                print("=== CANCELLED ORDERS DEBUG ===");
                print("Total orders fetched: ${snapshot.data!.docs.length}");

                // Get today's date range
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day);
                final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

                print("Today's date range: $startOfDay to $endOfDay");

                final todayCancelledOrders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status']?.toString().toLowerCase() ?? '';

                  print("Order ${doc.id}: status='$status'");

                  // First check if status is cancelled
                  if (status != 'cancelled') {
                    return false;
                  }

                  // Then check multiple possible timestamp fields
                  Timestamp? orderTimestamp;

                  // Try different timestamp field names that might exist
                  if (data.containsKey('clientTimestamp') && data['clientTimestamp'] != null) {
                    orderTimestamp = data['clientTimestamp'] as Timestamp;
                    print("  Found clientTimestamp: ${orderTimestamp.toDate()}");
                  } else if (data.containsKey('timestamp') && data['timestamp'] != null) {
                    orderTimestamp = data['timestamp'] as Timestamp;
                    print("  Found timestamp: ${orderTimestamp.toDate()}");
                  } else if (data.containsKey('orderDate') && data['orderDate'] != null) {
                    orderTimestamp = data['orderDate'] as Timestamp;
                    print("  Found orderDate: ${orderTimestamp.toDate()}");
                  } else if (data.containsKey('cancelledAt') && data['cancelledAt'] != null) {
                    orderTimestamp = data['cancelledAt'] as Timestamp;
                    print("  Found cancelledAt: ${orderTimestamp.toDate()}");
                  } else {
                    print("  No timestamp found for cancelled order ${doc.id}");
                    print("  Available fields: ${data.keys.toList()}");
                  }

                  if (orderTimestamp != null) {
                    final orderDate = orderTimestamp.toDate();
                    final isToday = orderDate.isAfter(startOfDay) && orderDate.isBefore(endOfDay);
                    print("  Order date: $orderDate, Is today: $isToday");
                    return isToday;
                  }

                  // If no timestamp found, include it anyway (might be recent)
                  print("  Including cancelled order without timestamp: ${doc.id}");
                  return true;
                }).toList();

                final count = todayCancelledOrders.length;
                print("Final cancelled orders today count: $count");
                print("=== END DEBUG ===");

                return _metricCard(Icons.cancel, "$count", "Cancelled ", Colors.red);
              } else {
                return _metricCard(Icons.cancel, "...", "Cancelled ", Colors.red);
              }
            },
          ),
        ],
      ),
    );
  }

  // Fixed stream - no longer requires composite index
  Stream<QuerySnapshot> _getTodaysOrdersStream() {
    if (vendorId == null) return const Stream.empty();

    // Simple query without timestamp filter to avoid index requirement
    if (restaurantName != null && restaurantName!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant', isEqualTo: restaurantName)
          .snapshots();
    }

    // Fallback to vendor ID if available
    return FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots();
  }

  Stream<QuerySnapshot> _getVendorOrdersStream() {
    if (vendorId == null) return const Stream.empty();

    // Get all orders for this vendor (we'll filter by date in the widget)
    if (restaurantName != null && restaurantName!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant', isEqualTo: restaurantName)
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots();
  }

  // New stream for delivered orders - replaces the pending orders stream
  Stream<QuerySnapshot> _getDeliveredOrdersStream() {
    if (vendorId == null) return const Stream.empty();

    if (restaurantName != null && restaurantName!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant', isEqualTo: restaurantName)
          .where('status', isEqualTo: 'delivered')
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: 'delivered')
        .snapshots();
  }

  // New stream for cancelled orders
  Stream<QuerySnapshot> _getCancelledOrdersStream() {
    if (vendorId == null) return const Stream.empty();

    if (restaurantName != null && restaurantName!.isNotEmpty) {
      return FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant', isEqualTo: restaurantName)
          .where('status', isEqualTo: 'cancelled')
          .snapshots();
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .where('status', isEqualTo: 'cancelled')
        .snapshots();
  }

  Widget _recentOrdersList() {
    if (vendorId == null) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant', isEqualTo: restaurantName)
          .orderBy('clientTimestamp', descending: true)
          .limit(20) // Increased limit to get more data to filter from
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          // Fallback query without orderBy if index is missing
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('restaurant', isEqualTo: restaurantName)
                .limit(20)
                .snapshots(),
            builder: (context, fallbackSnapshot) {
              if (!fallbackSnapshot.hasData || fallbackSnapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("No recent orders yet.", style: TextStyle(color: Colors.grey)),
                );
              }

              return _buildOrdersList(fallbackSnapshot.data!.docs);
            },
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text("No recent orders yet.", style: TextStyle(color: Colors.grey)),
          );
        }

        return _buildOrdersList(snapshot.data!.docs);
      },
    );
  }

  Widget _buildOrdersList(List<QueryDocumentSnapshot> docs) {
    // Filter orders for today only
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final todaysOrders = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['clientTimestamp'] as Timestamp?;

      if (timestamp != null) {
        return timestamp.toDate().isAfter(startOfDay);
      }
      return false; // Only include orders with timestamps from today
    }).take(50).toList(); // Take only 50 orders

    if (todaysOrders.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text("No orders today yet.", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: todaysOrders.length,
      itemBuilder: (context, index) {
        final order = todaysOrders[index].data() as Map<String, dynamic>;
        final foodPrice = order['foodPrice'];
        String priceDisplay = "0";

        if (foodPrice != null) {
          if (foodPrice is int || foodPrice is double) {
            priceDisplay = foodPrice.toString();
          } else if (foodPrice is String) {
            priceDisplay = foodPrice;
          }
        }

        return ListTile(
          leading: const Icon(Icons.receipt_long, color: AppColors.primary),
          title: Text(order['food'] ?? 'Food Item'),
          subtitle: Text("UGX $priceDisplay"),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(order['status'] ?? 'sent'),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              order['status'] ?? 'sent',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sent':
      case 'pending':
        return Colors.orange;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTextStyles.subHeader.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

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
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.subHeader),
          GestureDetector(
            onTap: () {
              // Navigate to Orders page (Orders tab)
              setState(() {
                _currentIndex = 1;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1),
              ),
              child: Text(
                "All",
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}