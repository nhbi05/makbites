import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:makbites/screens/vendor/set_preparation_time.dart';
import 'dart:async';

class OrdersPage extends StatefulWidget {
  final String vendorRestaurantId;

  OrdersPage({required this.vendorRestaurantId});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _userIdToName = {};
  Timer? _debounce;
  Stream<QuerySnapshot> get _ordersStream => FirebaseFirestore.instance
      .collection('orders')
      .where('restaurant', isEqualTo: widget.vendorRestaurantId)
      .snapshots();

  @override
  void initState() {
    super.initState();
    print('vendorRestaurantId: ${widget.vendorRestaurantId}');
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final userSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final usersMap = <String, String>{};
    for (var doc in userSnapshot.docs) {
      final data = doc.data();
      if (data.containsKey('uid') && data.containsKey('name')) {
        usersMap[data['uid']] = data['name'];
      }
    }
    setState(() {
      _userIdToName = usersMap;
    });
  }

  Future<void> sendNotificationToUser(String userId, String message) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final fcmToken = userDoc.data()?['fcmToken'];

    if (fcmToken != null && fcmToken.toString().isNotEmpty) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'to': fcmToken,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void updateOrderStatus(String orderId, String newStatus) async {
    final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    final userId = orderDoc.data()?['userId'];

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});

    String statusMessage = {
      'Pending': 'Your order is now marked as pending.',
      'Start Preparing': 'Your order is being prepared!',
      'Completed': 'Your order has been completed!',
      'Cancelled': 'Your order has been cancelled.',
    }[newStatus] ?? 'Order status updated.';

    if (userId != null) {
      await sendNotificationToUser(userId, statusMessage);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newStatus == 'Completed'
                  ? Icons.check_circle
                  : newStatus == 'Cancelled'
                  ? Icons.cancel
                  : newStatus == 'Start Preparing'
                  ? Icons.access_time
                  : Icons.info,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Order marked as "$newStatus"!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: newStatus == 'Completed'
            ? Colors.green
            : newStatus == 'Cancelled'
            ? Colors.red
            : newStatus == 'Start Preparing'
            ? Colors.orange
            : Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 8,
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {});
  }

  void cancelOrder(String orderId) async {
    final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
    final userId = orderDoc.data()?['userId'];

    await FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .update({'status': 'Cancelled'});

    if (userId != null) {
      await sendNotificationToUser(userId, 'Your order has been cancelled.');
    }

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

  void _showStatusChangeOptions(String orderId, String currentStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Order Status"),
        content: Text("Do you want to change the order status?"),
        actions: [
          if (currentStatus == "start preparing") ...[
            TextButton(
              onPressed: () {
                updateOrderStatus(orderId, "Sent");
                Navigator.pop(ctx);
              },
              child: Text("Revert to Sent"),
            ),
            TextButton(
              onPressed: () {
                updateOrderStatus(orderId, "Completed");
                Navigator.pop(ctx);
              },
              child: Text("Mark as Completed"),
            ),
          ] else if (currentStatus == "completed") ...[
            TextButton(
              onPressed: () {
                updateOrderStatus(orderId, "Start Preparing");
                Navigator.pop(ctx);
              },
              child: Text("Revert to Start Preparing"),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No orders found for this restaurant.'));
            }

            final allDocs = snapshot.data!.docs;
            final now = DateTime.now();
            final validOrders = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              if (!data.containsKey('status') || data['status'] == null) return false;
              final status = data['status'].toString().toLowerCase();

              // Check for scheduledSendTime
              final scheduledSendTime = data['scheduledSendTime'];
              bool isDue = true;
              if (scheduledSendTime != null && scheduledSendTime is Timestamp) {
                isDue = scheduledSendTime.toDate().isBefore(now) || scheduledSendTime.toDate().isAtSameMomentAs(now);
              }

              // Only show:
              // - sent
              // - pending (no scheduledSendTime or scheduledSendTime is due/now)
              // - cancelled
              if (
              status == 'sent' ||
                  (status == 'pending' && (scheduledSendTime == null || isDue)) ||
                  status == 'cancelled' ||
                  status == 'start preparing' ||
                  status == 'completed'
              ) {
                // If no search query, include all valid orders
                if (_searchQuery.isEmpty) return true;

                // Extract food name for both order types
                String food = '';
                if (data.containsKey('food')) {
                  food = (data['food'] ?? '').toString().toLowerCase();
                } else if (data.containsKey('items') && data['items'] is List && data['items'].isNotEmpty) {
                  final firstItem = data['items'][0];
                  if (firstItem is Map && firstItem.containsKey('name')) {
                    food = (firstItem['name'] ?? '').toString().toLowerCase();
                  }
                }

                final userId = data['userId'] ?? '';
                final customerName = _userIdToName[userId]?.toLowerCase() ?? '';
                // Use all possible timestamp fields for date search
                final timestamp = data['clientTimestamp'] ?? data['orderDate'] ?? data['orderTime'] ?? data['sentAt'];
                final date = (timestamp is Timestamp)
                    ? DateFormat('yyyy-MM-dd')
                    .format(timestamp.toDate().toLocal())
                    .toLowerCase()
                    : '';

                return food.contains(_searchQuery) ||
                    customerName.contains(_searchQuery) ||
                    date.contains(_searchQuery);
              }
              return false;
            }).toList();

            // Sort orders by most recent date (descending)
            validOrders.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTimestamp = aData['clientTimestamp'] ?? aData['orderDate'] ?? aData['orderTime'] ?? aData['sentAt'];
              final bTimestamp = bData['clientTimestamp'] ?? bData['orderDate'] ?? bData['orderTime'] ?? bData['sentAt'];
              if (aTimestamp == null && bTimestamp == null) return 0;
              if (aTimestamp == null) return 1;
              if (bTimestamp == null) return -1;
              if (aTimestamp is Timestamp && bTimestamp is Timestamp) {
                return bTimestamp.compareTo(aTimestamp); // Latest first
              }
              return 0;
            });

            int totalOrders = validOrders.length;

            // Show a message if no orders match the search
            if (validOrders.isEmpty) {
              return Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'No orders found for this restaurant.'
                      : 'No orders found matching your search.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)),
                SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, food, date...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () {
                      setState(() {
                        _searchQuery = value.toLowerCase().trim();
                      });
                    });
                  },
                ),
                SizedBox(height: 12),
                Text("Track and manage all your restaurant orders here!\n", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: validOrders.length,
                    itemBuilder: (context, index) {
                      final orderDoc = validOrders[index];
                      final orderData = orderDoc.data() as Map<String, dynamic>;
                      final orderId = orderDoc.id;
                      final userId = orderData['userId'] ?? 'Unknown';
                      final customerName = _userIdToName[userId] ?? 'Unknown Customer';
                      final displayOrderId = '#ORD${(totalOrders - index).toString().padLeft(3, '0')}';
                      final scheduledTime = orderData['scheduledSendTime'];
                      final timestamp = orderData['clientTimestamp'];
                      final orderTime = (scheduledTime != null && scheduledTime is Timestamp)
                          ? DateFormat('yyyy-MM-dd – kk:mm').format(scheduledTime.toDate())
                          : (timestamp != null && timestamp is Timestamp)
                              ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
                              : 'Unknown time';

                      String foodItem = '';
                      if (orderData.containsKey('food')) {
                        foodItem = orderData['food'];
                      } else if (orderData.containsKey('items') && orderData['items'] is List && orderData['items'].isNotEmpty) {
                        final firstItem = orderData['items'][0];
                        if (firstItem is Map && firstItem.containsKey('name')) {
                          foodItem = firstItem['name'];
                        }
                      }

                      final status = orderData['status'].toString().trim();
                      final normalizedStatus = status.toLowerCase();
                      final price = orderData['foodPrice'] ?? 0;
                      final mealType = orderData['mealType'] ?? '';
                      final paymentMethod = orderData['paymentMethod'] ?? '';

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderDetailsPage(
                                  orderData: orderData,
                                  customerName: customerName,
                                  orderId: displayOrderId,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(customerName, style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (normalizedStatus == "pending" || normalizedStatus == "sent")
                                      GestureDetector(
                                        onTap: () => _showCancelDialog(context, orderId),
                                        child: Tooltip(
                                          message: "Cancel Order",
                                          child: Icon(Icons.cancel, color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                                Text("$displayOrderId • $orderTime"),
                                SizedBox(height: 4),
                                Text("Food: $foodItem"),
                                Text("Meal Type: $mealType"),
                                Text("Payment: $paymentMethod"),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (normalizedStatus == "pending" || normalizedStatus == "sent") {
                                          _showSetPreparationTimeDialog(orderId);
                                        } else if (normalizedStatus == "start preparing" || normalizedStatus == "completed") {
                                          _showStatusChangeOptions(orderId, normalizedStatus);
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
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

//order details page


class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final String customerName;
  final String orderId;

  const OrderDetailsPage({
    required this.orderData,
    required this.customerName,
    required this.orderId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String? _contactInfo;
  bool _loadingContact = false;

  @override
  void initState() {
    super.initState();
    _fetchContactInfoIfNeeded();
  }

  void _fetchContactInfoIfNeeded() async {
    final orderData = widget.orderData;
    String? contact = orderData['contactInfo'] ?? orderData['phone'] ?? (orderData['delivery'] is Map ? orderData['delivery']['phone'] : null);
    if (contact == null || contact.toString().trim().isEmpty) {
      final userId = orderData['userId'];
      if (userId != null) {
        setState(() { _loadingContact = true; });
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          final userPhone = userDoc.data()?['phone'];
          if (userPhone != null && userPhone.toString().trim().isNotEmpty) {
            setState(() { _contactInfo = userPhone.toString(); });
          }
        } catch (e) {
          // Optionally handle error
        }
        setState(() { _loadingContact = false; });
      }
    } else {
      setState(() { _contactInfo = contact.toString(); });
    }
  }

  String cleanText(dynamic value, {String fallback = 'N/A'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String getFoodDescription(dynamic foodData, dynamic itemsData) {
    // For automated orders
    if (foodData != null && foodData.toString().trim().isNotEmpty) {
      return foodData.toString();
    }
    // For normal orders with items array
    if (itemsData is List && itemsData.isNotEmpty) {
      return itemsData
          .map((item) =>
              (item is Map && item['name'] != null) ? item['name'].toString() : '')
          .where((name) => name.isNotEmpty)
          .join(', ');
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final orderData = widget.orderData;
    final formatter = DateFormat('yyyy-MM-dd – hh:mm a');
    final isAutomated = orderData['orderSource'] == 'schedule';
    final scheduledTime = orderData['scheduledSendTime'];
    final timestamp = orderData['clientTimestamp'];
    final orderTime = (isAutomated && scheduledTime != null && scheduledTime is Timestamp)
        ? 'Scheduled: ' + formatter.format(scheduledTime.toDate())
        : (timestamp != null && timestamp is Timestamp)
            ? formatter.format(timestamp.toDate())
            : 'Unknown';

    final deliveryMan = orderData['deliveryMan'];
    final deliveryInfo = (deliveryMan != null && deliveryMan.toString().trim().isNotEmpty)
        ? "Assigned to: $deliveryMan"
        : "No delivery person assigned yet";

    final foodDescription = getFoodDescription(orderData['food'], orderData['items']);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Order ID: ${widget.orderId}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  SizedBox(height: 8),
                  Text("Customer: ${widget.customerName}",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.fastfood),
                    title: Text("Food"),
                    subtitle: Text(foodDescription),
                  ),
                  ListTile(
                    leading: Icon(Icons.attach_money),
                    title: Text("Price"),
                    subtitle: Text("Shs. ${cleanText(orderData['foodPrice'])}"),
                  ),
                  if (isAutomated)
                    ListTile(
                      leading: Icon(Icons.category),
                      title: Text("Meal Type"),
                      subtitle: Text(cleanText(orderData['mealType'])),
                    ),
                  ListTile(
                    leading: Icon(Icons.location_on),
                    title: Text("Delivery Address"),
                    subtitle: Text(
                        cleanText(
                            orderData['deliveryAddress'] ??
                                orderData['address'] ??
                                orderData['location'] ??
                                (orderData['delivery'] is Map ? orderData['delivery']['address'] : null)
                        )
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.phone),
                    title: Text("Contact Info"),
                    subtitle: _loadingContact
                        ? Text("Loading...")
                        : Text(cleanText(_contactInfo)),
                  ),
                  ListTile(
                    leading: Icon(Icons.notes),
                    title: Text("Notes"),
                    subtitle: Text(cleanText(orderData['notes'], fallback: 'No notes')),
                  ),
                  ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text("Order Time"),
                    subtitle: Text(orderTime),
                  ),
                  ListTile(
                    leading: Icon(Icons.delivery_dining),
                    title: Text("Delivery Info"),
                    subtitle: Text(deliveryInfo),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
