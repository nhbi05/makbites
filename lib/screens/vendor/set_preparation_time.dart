import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetPreparationTimePage extends StatefulWidget {
  final String orderId;
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

  Future<void> _resolveRestaurantIdAndFetchRiders() async {
    setState(() => _isLoadingRiders = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.vendorRestaurantIdOrName)
          .get();

      if (doc.exists) {
        _restaurantDocId = doc.id;
      } else {
        final snapshot = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('name', isEqualTo: widget.vendorRestaurantIdOrName)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          throw Exception('No restaurant found with name ${widget.vendorRestaurantIdOrName}');
        }

        _restaurantDocId = snapshot.docs.first.id;
      }

      await _fetchRiders();
    } catch (e) {
      _showSnackBar('Could not find restaurant. Please check and try again.');
      setState(() => _isLoadingRiders = false);
    }
  }

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
    } catch (e) {
      _showSnackBar('Error loading riders. Please try again.');
      setState(() => _isLoadingRiders = false);
    }
  }

  Future<void> _submitTime() async {
    if (selectedTime == null) {
      _showSnackBar('Please select a preparation time.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      Map<String, dynamic> updateData = {
        'status': 'Start Preparing',
        'estimatedPreparationTime': selectedTime,
        'preparationStartTimestamp': FieldValue.serverTimestamp(),
      };

      if (selectedRiderId != null && _riders.any((r) => r['id'] == selectedRiderId)) {
        final selectedRider = _riders.firstWhere((r) => r['id'] == selectedRiderId);
        updateData['assignedRiderId'] = selectedRiderId!;
        updateData['assignedRiderName'] = selectedRider['name'];

        await FirebaseFirestore.instance
            .collection('delivery_riders')
            .doc(selectedRiderId)
            .update({'total_deliveries': FieldValue.increment(1)});
      }

      updateData.removeWhere((key, value) => value == null);

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(updateData);

      Navigator.pop(context, true); // trigger refresh
    } catch (e) {
      _showSnackBar('Error: Could not update order.');
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildRiderDropdown() {
    if (_isLoadingRiders) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 10),
            Text("Loading riders..."),
          ],
        ),
      );
    }

    if (_riders.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "No riders available now. You can continue without assigning one.",
          style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: selectedRiderId,
      hint: Text("Select rider (optional)"),
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
      onChanged: (value) => setState(() => selectedRiderId = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Preparation Time")),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Set preparation time:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text("Assign a rider (optional):",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildRiderDropdown(),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitTime,
                child: Text("Confirm & Start Preparing"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
