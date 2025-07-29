import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:makbites/screens/vendor/set_preparation_time.dart';
import 'package:makbites/screens/vendor/all_orders_page.dart';
import 'package:makbites/services/push_notification_service.dart';
import 'package:makbites/models/automation_models.dart';

class OrdersPage extends StatefulWidget {
  final String vendorRestaurantId;

  OrdersPage({required this.vendorRestaurantId});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  Map<String, String> _userIdToName = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _combinedOrders = [];
  Timer? _refreshTimer;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadOrders();
    _startRefreshTimer();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ordersSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _loadOrders();
    });
  }

  void _showSetPreparationTimeDialog(String orderId) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SetPreparationTimePage(
          orderId: orderId,
          vendorRestaurantIdOrName: widget.vendorRestaurantId,
        ),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  // Load orders using simple approach - no complex queries
  void _loadOrders() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(Duration(days: 1));
      
      List<Map<String, dynamic>> allOrders = [];
      
      // 1. Fetch regular orders for today
      final regularOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('restaurant', isEqualTo: widget.vendorRestaurantId)
          .get();
      
      for (var doc in regularOrdersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['clientTimestamp'];
        final status = data['status']?.toString() ?? '';
        final scheduledSendTime = data['scheduledSendTime'];
        DateTime? scheduledSendDateTime;
        if (scheduledSendTime is Timestamp) {
          scheduledSendDateTime = scheduledSendTime.toDate();
        }

        // Skip scheduled orders here - we'll process them separately
        if (data['orderSource'] == 'schedule') {
          continue;
        }

        if (timestamp != null && timestamp is Timestamp) {
          final orderDate = timestamp.toDate();
          // Only include today's orders
          if (orderDate.isAfter(startOfDay) && orderDate.isBefore(endOfDay)) {
            bool showOrder = false;
            if (status == 'sent' || status == 'cancelled') {
              showOrder = true;
            } else {
              // For pending and all other statuses
              if (scheduledSendDateTime == null || scheduledSendDateTime.isBefore(DateTime.now()) || scheduledSendDateTime.isAtSameMomentAs(DateTime.now())) {
                showOrder = true;
              }
            }
            if (showOrder) {
              data['id'] = doc.id;
              data['isScheduled'] = false;
              allOrders.add(data);
            }
          }
        }
      }
      
      // 2. Look for scheduled orders in the regular orders collection
      // These are orders with orderSource: "schedule" and scheduledTime field
      for (var doc in regularOrdersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString() ?? '';
        final scheduledSendTime = data['scheduledSendTime'];
        DateTime? scheduledSendDateTime;
        if (scheduledSendTime is Timestamp) {
          scheduledSendDateTime = scheduledSendTime.toDate();
        }
        // Check if this is a scheduled order
        if (data['orderSource'] == 'schedule' && data['scheduledTime'] != null) {
          final scheduledTimestamp = data['scheduledTime'];
          if (scheduledTimestamp is Timestamp) {
            final scheduledTime = scheduledTimestamp.toDate();
            bool showOrder = false;
            if (status == 'sent' || status == 'cancelled') {
              showOrder = true;
            } else {
              if (scheduledSendDateTime == null || scheduledSendDateTime.isBefore(DateTime.now()) || scheduledSendDateTime.isAtSameMomentAs(DateTime.now())) {
                showOrder = true;
              }
            }
            if (showOrder) {
              final scheduledOrderData = Map<String, dynamic>.from(data);
              scheduledOrderData['id'] = doc.id;
              scheduledOrderData['isScheduled'] = true;
              allOrders.add(scheduledOrderData);
            }
          }
        }
      }
      
      // 3. Sort combined orders
      allOrders.sort((a, b) {
        final aTime = a['isScheduled'] == true 
            ? (a['scheduledTime'] as Timestamp).toDate()
            : (a['clientTimestamp'] as Timestamp).toDate();
        final bTime = b['isScheduled'] == true 
            ? (b['scheduledTime'] as Timestamp).toDate()
            : (b['clientTimestamp'] as Timestamp).toDate();
        return bTime.compareTo(aTime);
      });
      
      setState(() {
        _combinedOrders = allOrders;
      });
      
    } catch (e) {
      print('Error loading orders: $e');
    }
  }

  Future<void> _loadUsers() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final usersMap = <String, String>{};
      for (var doc in userSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('uid') && data.containsKey('name')) {
          usersMap[data['uid']] = data['name'];
        }
      }
      print('Loaded ${usersMap.length} users: $usersMap'); // Debug info
      setState(() {
        _userIdToName = usersMap;
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  // Method to fetch missing user names
  Future<void> _fetchMissingUserNames(List<String> userIds) async {
    final missingUserIds = userIds.where((id) => !_userIdToName.containsKey(id)).toList();
    if (missingUserIds.isEmpty) return;

    try {
      for (final userId in missingUserIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          final userName = userDoc.data()?['name'] ?? 'Unknown Customer';
          _userIdToName[userId] = userName;
        }
      }
      setState(() {}); // Trigger rebuild with updated names
    } catch (e) {
      print('Error fetching missing user names: $e');
    }
  }

  void updateOrderStatus(String orderId, String currentStatus) async {
    if (currentStatus.trim().toLowerCase() == "start preparing") {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Completed'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as "Completed"!')),
      );

      setState(() {});
    }
  }

  void cancelOrder(String orderId) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Cancelled'});

    setState(() {});
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Cancel Order"),
        content: Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("No")),
          TextButton(
            onPressed: () {
              cancelOrder(orderId);
              Navigator.pop(ctx);
            },
            child: Text("Yes"),
          ),
        ],
      ),
    );
  }

  Future<void> _createTestOrder() async {
    String newId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';

    await FirebaseFirestore.instance.collection('orders').doc(newId).set({
      'restaurant': widget.vendorRestaurantId,
      'food': 'Chapati',
      'foodPrice': 2000,
      'status': 'Pending',
      'clientTimestamp': Timestamp.now(),
      'serverTimestamp': Timestamp.now(),
      'userId': _userIdToName.keys.isNotEmpty ? _userIdToName.keys.first : 'Unknown',
      'mealType': 'Breakfast',
      'paymentMethod': 'Cash on Delivery',
      'deliveryAddress': 'Kampala, Plot 10 Makerere',
      'contactInfo': '0789-123-456',
      'notes': 'Please add ketchup and cutlery.',
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test order created')));
  }

  Widget _buildCombinedOrdersList(List<Map<String, dynamic>> orders) {
    final validOrders = orders.where((orderData) {
      return orderData.containsKey('status') && orderData['status'] != null && orderData['status'].toString().trim().isNotEmpty;
    }).toList();

    // Fetch missing user names for the orders
    final userIds = validOrders.map((orderData) {
      return orderData['userId'] ?? '';
    }).where((id) => id.isNotEmpty).cast<String>().toList();
    _fetchMissingUserNames(userIds);

    // Filter by search query
    final filteredOrders = _searchQuery.isEmpty
        ? validOrders
        : validOrders.where((orderData) {
            final userId = orderData['userId'] ?? '';
            final customerName = _userIdToName[userId]?.toLowerCase() ?? '';
            final food = (orderData['food'] ?? '').toString().toLowerCase();
            final date = (orderData['clientTimestamp'] != null && orderData['clientTimestamp'] is Timestamp)
                ? (orderData['clientTimestamp'] as Timestamp).toDate().toString().toLowerCase()
                : '';
            return customerName.contains(_searchQuery) ||
                food.contains(_searchQuery) ||
                date.contains(_searchQuery);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Expanded(
          child: ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final orderData = filteredOrders[index];
              final orderId = orderData['id'];
              final userId = orderData['userId'] ?? 'Unknown';
              final customerName = _userIdToName[userId] ?? 'Unknown Customer';
              final displayOrderId = '#ORD${(index + 1).toString().padLeft(3, '0')}';
              final timestamp = orderData['clientTimestamp'];
              final isScheduled = orderData['isScheduled'] ?? false;
              
              String orderTime;
              String scheduledInfo = '';
              
              if (isScheduled) {
                final scheduledTimestamp = orderData['scheduledTime'];
                final scheduledTime = (scheduledTimestamp != null && scheduledTimestamp is Timestamp)
                    ? scheduledTimestamp.toDate()
                    : DateTime.now();
                orderTime = 'Scheduled: ${DateFormat('HH:mm').format(scheduledTime)}';
                
                
              } else {
                orderTime = (timestamp != null && timestamp is Timestamp)
                    ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
                    : 'Unknown time';
              }

                            // Display items from the items field if available, otherwise fallback to food field
                            String foodItem;
                            List<Map<String, dynamic>> items = [];
                            if (orderData['items'] != null && orderData['items'] is List) {
                              items = List<Map<String, dynamic>>.from(orderData['items']);
                              if (items.isNotEmpty) {
                                foodItem = items.map((item) => '${item['name'] ?? 'Unknown'} x${item['quantity'] ?? 1}').join(', ');
                              } else {
                                foodItem = orderData['food'] ?? 'No items';
                              }
                            } else {
                              foodItem = orderData['food'] ?? 'No items';
                            }
                            
                            final status = orderData['status'].toString().trim();
                            final normalizedStatus = status.toLowerCase();
                            final price = orderData['foodPrice'] ?? 0;
                            final mealType = orderData['mealType'] ?? '';

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              if (isScheduled) ...[
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'SCHEDULED',
                                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(customerName, style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _showCancelDialog(context, orderId),
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text("$displayOrderId • $orderTime"),
                                    if (isScheduled && scheduledInfo.isNotEmpty) ...[
                                      SizedBox(height: 2),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                        ),
                                        child: Text(
                                          scheduledInfo,
                                          style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.w500, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 4),
                                    Text("Food: $foodItem"),
                                    Text("Meal Type: $mealType"),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            if (normalizedStatus == "pending" || normalizedStatus == "sent") {
                                              _showSetPreparationTimeDialog(orderId);
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: normalizedStatus == "completed"
                                                  ? Colors.green
                                                  : normalizedStatus == "start preparing"
                                                  ? Colors.orange
                                                  : normalizedStatus == "cancelled"
                                                  ? Colors.grey
                                                  : Colors.blueAccent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  normalizedStatus == "completed"
                                                      ? Icons.check
                                                      : normalizedStatus == "start preparing"
                                                      ? Icons.access_time
                                                      : normalizedStatus == "cancelled"
                                                      ? Icons.cancel
                                                      : Icons.fiber_new,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  status[0].toUpperCase() + status.substring(1),
                                                  style: TextStyle(color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Text("Shs. $price", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate today's range
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createTestOrder,
        child: Icon(Icons.add),
        tooltip: 'Create Test Order',
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, food, date...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
            SizedBox(height: 8),
            // Refresh button
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loadOrders,
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllOrdersPage(vendorRestaurantId: widget.vendorRestaurantId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list, color: Colors.white),
                  label: const Text('All Orders', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Text('${_combinedOrders.length} orders', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: _combinedOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No orders found'),
                          SizedBox(height: 8),
                          Text('Regular orders and scheduled orders (30 min before delivery) will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : _buildCombinedOrdersList(_combinedOrders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: 150,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}