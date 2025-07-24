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
  bool isLoading = false;

  final List<String> timeOptions = [
    '5 minutes',
    '10 minutes',
    '15 minutes',
    '20 minutes',
    '25 minutes',
    '30 minutes',
  ];

  void _submitTime() async {
    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a preparation time.')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final int? prepMinutes = int.tryParse(selectedTime!.split(' ').first);

      Map<String, dynamic> updateData = {
        'status': 'Start Preparing',
        'estimatedPreparationTime': selectedTime,
        'preparationStartTimestamp': FieldValue.serverTimestamp(),
        'preparationTimeMinutes': prepMinutes, // ✅ Added this line
      };

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(updateData);

      Navigator.pop(context); // Close the screen after updating
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating order: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Preparation Time'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select estimated preparation time:',
              style: TextStyle(fontSize: 18),
            ),
          ),
          ...timeOptions.map((time) {
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _submitTime,
              child: const Text('Confirm Time'),
            ),
          ),
        ],
      ),
    );
  }
}
