import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetPreparationTimePage extends StatefulWidget {
  final String orderId;

  /// This can be the restaurant **ID** or the **name** — we’ll handle both.
  final String vendorRestaurantIdOrName;

  const SetPreparationTimePage({
    required this.orderId,
    required this.vendorRestaurantIdOrName,
  });

  @override
  _SetPreparationTimePageState createState() => _SetPreparationTimePageState();
}

class _SetPreparationTimePageState extends State<SetPreparationTimePage> {
  String? selectedTime;
  String? selectedRiderId;
  bool _isSubmitting = false;
  bool _isLoadingRiders = true;

  List<Map<String, dynamic>> _riders = [];
  String? _restaurantDocId;

  final List<String> times = [
    '10 minutes',
    '15 minutes',
    '20 minutes',
    '30 minutes',
  ];

  @override
  void initState() {
    super.initState();
    _resolveRestaurantIdAndFetchRiders();
  }

  /// Step 1: Figure out the actual restaurant Firestore doc ID
  Future<void> _resolveRestaurantIdAndFetchRiders() async {
    setState(() {
      _isLoadingRiders = true;
    });

    try {
      // Try to get the restaurant doc by ID first
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.vendorRestaurantIdOrName)
          .get();

      if (doc.exists) {
        // It is already the ID
        _restaurantDocId = doc.id;
      } else {
        // Not an ID, so look up by name
        final snapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('name', isEqualTo: widget.vendorRestaurantIdOrName)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          throw Exception(
              'No restaurant found with name ${widget.vendorRestaurantIdOrName}');
        }

        _restaurantDocId = snapshot.docs.first.id;
      }

      print('Resolved restaurant ID: $_restaurantDocId');

      await _fetchRiders();
    } catch (e) {
      print('Error resolving restaurant ID: $e');
      _showSnackBar('Could not find restaurant. Please check and try again.');
      setState(() {
        _isLoadingRiders = false;
      });
    }
  }

  /// Step 2: Fetch riders using the resolved restaurant doc ID
  Future<void> _fetchRiders() async {
    if (_restaurantDocId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('delivery_riders')
          .where('assigned_vendors', arrayContains: _restaurantDocId)
          .get();

      final ridersList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed',
        };
      }).toList();

      setState(() {
        _riders = ridersList;
        _isLoadingRiders = false;
      });

      print('Fetched ${_riders.length} riders for restaurant: $_restaurantDocId');
    } catch (e) {
      print('Error fetching riders: $e');
      _showSnackBar('Error loading riders. Please try again.');
      setState(() {
        _isLoadingRiders = false;
      });
    }
  }

  Future<void> _submitTime() async {
    if (selectedTime == null) {
      _showSnackBar('Please select a preparation time.');
      return;
    }

    if (selectedRiderId == null) {
      _showSnackBar('Please select a rider.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final selectedRider = _riders.firstWhere((r) => r['id'] == selectedRiderId);

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'Start Preparing',
        'estimatedPreparationTime': selectedTime,
        'preparationStartTimestamp': FieldValue.serverTimestamp(),
        'restaurant': _restaurantDocId,
        'assignedRiderId': selectedRiderId,
        'assignedRiderName': selectedRider['name'],
      });
      //udpate the total delivery field
      await FirebaseFirestore.instance
          .collection('delivery_riders')
          .doc(selectedRiderId)
          .update({
        'total_deliveries': FieldValue.increment(1),
      });
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Error: Could not update order.');
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildRiderDropdown() {
    if (_isLoadingRiders) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text("Loading riders..."),
          ],
        ),
      );
    }

    if (_riders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 20),
            SizedBox(width: 10),
            Text(
              "No riders available for this restaurant",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedRiderId,
      hint: Text("Select rider"),
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _riders.map((rider) {
        return DropdownMenuItem<String>(
          value: rider['id'],
          child: Text(rider['name']),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedRiderId = value;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isSubmitting
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Select an estimated preparation time and rider:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ...times.map((time) {
            return RadioListTile<String>(
              title: Text(time),
              value: time,
              groupValue: selectedTime,
              onChanged: (value) => setState(() => selectedTime = value),
            );
          }).toList(),
          SizedBox(height: 20),
          Text(
            "Assign a rider:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _buildRiderDropdown(),
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
              (_riders.isEmpty || _isLoadingRiders) ? null : _submitTime,
              child: Text("Confirm & Start Preparing"),
            ),
          ),
        ],
      ),
    );
  }
}
