import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_event.dart';

class PlaceOrderScreen extends StatefulWidget {
  @override
  _PlaceOrderScreenState createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  DateTime? _selectedDate;
  String? _mealType;
  String? _restaurant;
  String? _food;
  String? _paymentMethod;
  String? _location;
  Map<String, DateTime?>? _optimalMealTimes;
  bool _loadingMealTimes = false;

  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Supper'];
  final List<String> restaurants = [
    'Campus Grill',
    'Healthy Bites',
    'Pizza Corner',
    'Freshhot',
    'Fredoz',
  ];
  final Map<String, List<String>> restaurantFoods = {
    'Campus Grill': ['Beef Burger', 'Chicken Wrap', 'Veggie Fries'],
    'Healthy Bites': ['Caesar Salad', 'Avocado Wrap', 'Fruit Smoothie'],
    'Pizza Corner': ['Pepperoni Pizza', 'Veggie Pizza', 'Pasta Alfredo'],
    'Freshhot': ['Grilled Chicken', 'Hot Wings', 'Rice Bowl'],
    'Fredoz': ['Fish Fingers', 'Beef Stew', 'Chapati Roll'],
  };

  @override
  void initState() {
    super.initState();
    _fetchOptimalMealTimes();
  }

  Future<void> _fetchOptimalMealTimes() async {
    if (_selectedDate == null) return;
    setState(() { _loadingMealTimes = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0);
    final end = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59);
    final snapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: user.uid)
        .get();
    final events = snapshot.docs.map((doc) => UserEvent.fromMap(doc.data())).toList();
    final dayEvents = events.where((e) => e.startTime.isAfter(start) && e.startTime.isBefore(end)).toList();
    _optimalMealTimes = _findOptimalMealTimes(dayEvents, _selectedDate!);
    setState(() { _loadingMealTimes = false; });
  }

  Map<String, DateTime?> _findOptimalMealTimes(List<UserEvent> events, DateTime day) {
    final windows = {
      'Breakfast': [TimeOfDay(hour: 7, minute: 0), TimeOfDay(hour: 11, minute: 0)],
      'Lunch': [TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 17, minute: 0)],
      'Supper': [TimeOfDay(hour: 18, minute: 0), TimeOfDay(hour: 23, minute: 0)],
    };
    Map<String, DateTime?> result = {};
    for (final meal in windows.keys) {
      final start = windows[meal]![0];
      final end = windows[meal]![1];
      final windowStart = DateTime(day.year, day.month, day.day, start.hour, start.minute);
      final windowEnd = DateTime(day.year, day.month, day.day, end.hour, end.minute);
      final busy = events.where((e) => e.startTime.isBefore(windowEnd) && e.endTime.isAfter(windowStart)).toList();
      final gaps = _findFreeGaps(windowStart, windowEnd, busy);
      DateTime? mealStart;
      for (final g in gaps) {
        if (g.end.difference(g.start).inMinutes >= 30) {
          mealStart = g.start;
          break;
        }
      }
      result[meal] = mealStart;
    }
    return result;
  }

  List<DateTimeRange> _findFreeGaps(DateTime windowStart, DateTime windowEnd, List<UserEvent> events) {
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    List<DateTimeRange> gaps = [];
    DateTime current = windowStart;
    for (final event in events) {
      if (event.startTime.isAfter(current)) {
        gaps.add(DateTimeRange(start: current, end: event.startTime));
      }
      if (event.endTime.isAfter(current)) {
        current = event.endTime;
      }
    }
    if (current.isBefore(windowEnd)) {
      gaps.add(DateTimeRange(start: current, end: windowEnd));
    }
    return gaps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Place Order'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Order Details'),
            SizedBox(height: 16),
            _buildDatePicker(),
            SizedBox(height: 16),
            _buildDropdown('Meal Type', mealTypes, _mealType, (val) => setState(() => _mealType = val)),
            SizedBox(height: 16),
            _buildDropdown('Preferred Restaurant', restaurants, _restaurant, (val) {
              setState(() {
                _restaurant = val;
                _food = null;
              });
            }),
            SizedBox(height: 16),
            _buildDropdown(
              'Food',
              _restaurant != null ? restaurantFoods[_restaurant!]! : [],
              _food,
              (val) => setState(() => _food = val),
              enabled: _restaurant != null,
            ),
            SizedBox(height: 16),
            _buildSectionTitle('Payment & Delivery'),
            SizedBox(height: 16),
            _buildPaymentMethod(),
            SizedBox(height: 16),
            _buildLocationField(),
            SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _canSubmit() ? _submitOrder : null,
                icon: Icon(Icons.check_circle),
                label: Text('Place Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.subHeader.copyWith(fontSize: 20));
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              await _fetchOptimalMealTimes();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  _selectedDate != null
                      ? DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)
                      : 'Select Date',
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        _buildOptimalMealTimesSection(),
      ],
    );
  }

  Widget _buildOptimalMealTimesSection() {
    if (_selectedDate == null) {
      return Text('Select a date to see optimal meal times.', style: AppTextStyles.body);
    }
    if (_loadingMealTimes) {
      return Center(child: CircularProgressIndicator());
    }
    if (_optimalMealTimes == null) {
      return Text('No data available.', style: AppTextStyles.body);
    }
    return Card(
      color: AppColors.secondary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Optimal Meal Times', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ..._optimalMealTimes!.entries.map((e) => Row(
              children: [
                Text('${e.key}: ', style: AppTextStyles.body),
                Text(
                  e.value != null ? DateFormat('hh:mm a').format(e.value!) : 'No free slot',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged, {bool enabled = true}) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: enabled ? onChanged : null,
          hint: Text('Select $label'),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method', style: AppTextStyles.body),
        Row(
          children: [
            Radio<String>(
              value: 'Mobile Money',
              groupValue: _paymentMethod,
              onChanged: (val) => setState(() => _paymentMethod = val),
            ),
            Text('Mobile Money'),
            SizedBox(width: 24),
            Radio<String>(
              value: 'Cash on Delivery',
              groupValue: _paymentMethod,
              onChanged: (val) => setState(() => _paymentMethod = val),
            ),
            Text('Cash on Delivery'),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Delivery Location',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(Icons.location_on),
      ),
      onChanged: (val) => setState(() => _location = val),
    );
  }

  bool _canSubmit() {
    return _selectedDate != null &&
        _mealType != null &&
        _restaurant != null &&
        _food != null &&
        _paymentMethod != null &&
        _location != null &&
        _location!.trim().isNotEmpty;
  }

  void _submitOrder() {
    // You can implement order submission logic here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Placed!'),
        content: Text('Your order has been placed successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
} 