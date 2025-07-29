import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:intl/intl.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  @override
  _DeliveryHistoryScreenState createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Today', 'This Week', 'This Month'];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      appBar: AppBar(
        title: Text('Delivery History', style: AppTextStyles.header),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: AppColors.primary),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filterOptions.map((filter) {
              return PopupMenuItem<String>(
                value: filter,
                child: Row(
                  children: [
                    Icon(
                      _selectedFilter == filter ? Icons.check : Icons.circle_outlined,
                      color: _selectedFilter == filter ? AppColors.primary : Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(filter),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          Expanded(
            child: _buildDeliveryHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final currentRiderId = FirebaseAuth.instance.currentUser?.uid;
    if (currentRiderId == null) return SizedBox.shrink();

    return Container(
      margin: EdgeInsets.all(16),
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
      child: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredDeliveriesStream(currentRiderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Deliveries', '0', Icons.local_shipping),
                _buildStatItem('Total Earnings', 'UGX 0', Icons.account_balance_wallet),
              ],
            );
          }

          final docs = snapshot.data!.docs;
          final totalDeliveries = docs.length;
          final totalEarnings = docs.fold<int>(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + ((data['deliveryFee'] ?? 0) as int);
          });

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Deliveries', '$totalDeliveries', Icons.local_shipping),
              _buildStatItem('Total Earnings', 'UGX $totalEarnings', Icons.account_balance_wallet),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryHistoryList() {
    final currentRiderId = FirebaseAuth.instance.currentUser?.uid;
    if (currentRiderId == null) {
      return Center(child: Text('Please log in to view delivery history'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredDeliveriesStream(currentRiderId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading delivery history'),
                Text('${snapshot.error}', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No delivery history found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  _selectedFilter == 'All' 
                    ? 'Complete your first delivery to see it here'
                    : 'No deliveries found for $_selectedFilter',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildDeliveryHistoryCard(data);
          },
        );
      },
    );
  }

  Widget _buildDeliveryHistoryCard(Map<String, dynamic> delivery) {
    final status = delivery['status'] ?? 'completed';
    // Use appropriate timestamp based on status
    final timestamp = (status == 'cancelled' 
        ? delivery['cancelledAt'] 
        : delivery['completedAt']) as Timestamp?;
    final deliveryAddress = delivery['deliveryAddress'] ?? 'Unknown Address';
    final customerName = delivery['customerName'] ?? 'Unknown Customer';
    final deliveryFee = (delivery['deliveryFee'] ?? 0) as int;
    final distance = delivery['distance']?.toString() ?? 'N/A';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  deliveryAddress,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet, 
                    size: 16, 
                    color: status.toLowerCase() == 'cancelled' ? Colors.grey : AppColors.success
                  ),
                  SizedBox(width: 4),
                  Text(
                    status.toLowerCase() == 'cancelled' ? 'UGX 0' : 'UGX $deliveryFee',
                    style: TextStyle(
                      color: status.toLowerCase() == 'cancelled' ? Colors.grey : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (distance != 'N/A')
                Row(
                  children: [
                    Icon(Icons.route, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '$distance km',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
            ],
          ),
          if (timestamp != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  _formatDateTime(timestamp.toDate()),
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  Stream<QuerySnapshot> _getFilteredDeliveriesStream(String riderId) {
    var query = FirebaseFirestore.instance
        .collection('deliveries')
        .where('assignedRiderId', isEqualTo: 'rider_$riderId')
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('updatedAt', descending: true);

    // Apply date filters
    DateTime? startDate;
    switch (_selectedFilter) {
      case 'Today':
        startDate = DateTime.now().subtract(Duration(days: 1));
        break;
      case 'This Week':
        startDate = DateTime.now().subtract(Duration(days: 7));
        break;
      case 'This Month':
        startDate = DateTime.now().subtract(Duration(days: 30));
        break;
      default:
        // 'All' - no date filter
        break;
    }

    if (startDate != null) {
      query = query.where('updatedAt', isGreaterThan: Timestamp.fromDate(startDate)) as Query<Map<String, dynamic>>;
    }

    return query.snapshots();
  }
}
