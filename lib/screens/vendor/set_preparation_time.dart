import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SetPreparationTimePage extends StatefulWidget {
  final String orderId;
  final String vendorRestaurantId; // Add this if you need to pass it around

  const SetPreparationTimePage({
    required this.orderId,
    required this.vendorRestaurantId,
  });

  @override
  _SetPreparationTimePageState createState() => _SetPreparationTimePageState();
}

class _SetPreparationTimePageState extends State<SetPreparationTimePage> {
  String? selectedTime;
  final List<String> times = ['10 minutes', '15 minutes', '20 minutes', '30 minutes'];

  void _submitTime() async {
    if (selectedTime == null) return;

    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'status': 'Start Preparing',
      'estimatedPreparationTime': selectedTime,
      'preparationStartTimestamp': FieldValue.serverTimestamp(),
      'restaurant': widget.vendorRestaurantId, // Optional: in case needed again
    });

    Navigator.pop(context); // Go back to OrdersPage

    // Optional: Show snack on OrdersPage instead of here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order marked as "Start Preparing"!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Set Preparation Time")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Select an estimated preparation time:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
