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
  bool _isSubmitting = false;

  final List<String> times = ['10 minutes', '15 minutes', '20 minutes', '30 minutes'];

  Future<void> _submitTime() async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a preparation time.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'Start Preparing',
        'estimatedPreparationTime': selectedTime,
        'preparationStartTimestamp': FieldValue.serverTimestamp(),
        'restaurant': widget.vendorRestaurantId,
      });

      // Return success to OrdersPage
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Could not update order.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Preparation Time")),
      body: _isSubmitting
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Select an estimated preparation time:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...times.map((time) {
              return RadioListTile<String>(
                title: Text(time),
                value: time,
                groupValue: selectedTime,
                onChanged: (value) {
                  setState(() {
                    selectedTime = value;
                  });
                },
              );
            }).toList(),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitTime,
              child: Text("Confirm & Start Preparing"),
            ),
          ],
        ),
      ),
    );
  }
}
