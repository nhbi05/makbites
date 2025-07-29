import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';



class AllOrdersPage extends StatefulWidget {
  final String vendorRestaurantId;
  const AllOrdersPage({Key? key, required this.vendorRestaurantId}) : super(key: key);

  @override
  _AllOrdersPageState createState() => _AllOrdersPageState();
}

class _AllOrdersPageState extends State<AllOrdersPage> {
  List<Map<String, dynamic>> _allOrders = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _loadAllOrders() async {
    setState(() { _loading = true; });
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('restaurant', isEqualTo: widget.vendorRestaurantId)
        .get();
    final orders = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();
    orders.sort((a, b) {
      final aTime = (a['clientTimestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (b['clientTimestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    setState(() {
      _allOrders = orders;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _searchQuery.isEmpty
        ? _allOrders
        : _allOrders.where((order) {
            final customer = (order['customerName'] ?? '').toString().toLowerCase();
            final food = (order['food'] ?? '').toString().toLowerCase();
            final date = (order['clientTimestamp'] is Timestamp)
                ? DateFormat('yyyy-MM-dd').format((order['clientTimestamp'] as Timestamp).toDate())
                : '';
            return customer.contains(_searchQuery) ||
                food.contains(_searchQuery) ||
                date.contains(_searchQuery);
          }).toList();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text('All Orders', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer, food, date...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${filteredOrders.length} orders', style: TextStyle(color: Colors.grey[600])),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.red),
                  onPressed: _loadAllOrders,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredOrders.isEmpty
                      ? const Center(child: Text('No orders found'))
                      : ListView.builder(
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            final status = (order['status'] ?? '').toString();
                            final price = order['foodPrice'] ?? order['price'] ?? '';
                            final customer = order['customerName'] ?? order['userId'] ?? '';
                            final food = order['food'] ?? '';
                            final time = order['clientTimestamp'] is Timestamp
                                ? DateFormat('yyyy-MM-dd HH:mm').format((order['clientTimestamp'] as Timestamp).toDate())
                                : '';
                            return Card(
                              color: Colors.red.withOpacity(0.08),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text('$food', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Customer: $customer\nStatus: $status\nTime: $time'),
                                trailing: Text('Shs. $price', style: const TextStyle(fontWeight: FontWeight.bold)),
                                onTap: () {
                                  // TODO: Add management actions (prep time, status, cancel, etc.)
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
