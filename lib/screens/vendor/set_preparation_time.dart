import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetPreparationTimePage extends StatefulWidget {
  final String orderId;
  final String vendorRestaurantId;

  const SetPreparationTimePage({
    required this.orderId,
    required this.vendorRestaurantId,
  });

  @override
  _SetPreparationTimePageState createState() => _SetPreparationTimePageState();
}

class _SetPreparationTimePageState extends State<SetPreparationTimePage> {
  String? selectedTime;
  String? selectedRiderId;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> _riders = [];

  final List<String> times = ['10 minutes', '15 minutes', '20 minutes', '30 minutes'];

  @override
  void initState() {
    super.initState();
    _fetchRiders();
  }

  Future<void> _fetchRiders() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('delivery_drivers')
        .where('restaurantId', isEqualTo: widget.vendorRestaurantId)
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
    });
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
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'Start Preparing',
        'estimatedPreparationTime': selectedTime,
        'preparationStartTimestamp': FieldValue.serverTimestamp(),
        'restaurant': widget.vendorRestaurantId,
        'assignedRiderId': selectedRiderId,
        'assignedRiderName': selectedRider['name'],
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
          DropdownButtonFormField<String>(
            value: selectedRiderId,
            hint: Text("Select rider"),
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
          ),
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
    );
  }
}
