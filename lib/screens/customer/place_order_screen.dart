import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_event.dart';
import 'checkout_page.dart';

class PlaceOrderScreen extends StatefulWidget {
  final DateTime? initialDate;
  final Map<String, DateTime?>? initialOptimalMealTimes;

  const PlaceOrderScreen({Key? key, this.initialDate, this.initialOptimalMealTimes}) : super(key: key);

  @override
  _PlaceOrderScreenState createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  DateTime? _selectedDate;
  String? _mealType;
  String? _restaurant;
  String? _food;
  int? _foodPrice;
  String? _paymentMethod;
  String? _location;
  Map<String, DateTime?>? _optimalMealTimes;
  bool _loadingMealTimes = false;
  List<Map<String, dynamic>> _ordersForDay = [];

  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Supper'];
  final List<String> restaurants = [
    'MK Catering Services',
    'Lumumba Cafe',
    "Ssalongo's",
    'Freddoz',
    'Fresh Hot',
  ];
  final Map<String, List<Map<String, dynamic>>> restaurantFoods = {
    'MK Catering Services': [
      {'name': 'Pilau', 'price': 8000},
      {'name': 'Chicken Stew', 'price': 10000},
      {'name': 'Chapati', 'price': 2000},
    ],
    'Lumumba Cafe': [
      {'name': 'Rolex', 'price': 3000},
      {'name': 'Katogo', 'price': 4000},
      {'name': 'Tea', 'price': 1500},
    ],
    "Ssalongo's": [
      {'name': 'Matoke', 'price': 5000},
      {'name': 'Beef Stew', 'price': 9000},
      {'name': 'Rice', 'price': 3000},
    ],
    'Freddoz': [
      {'name': 'Fish Fingers', 'price': 7000},
      {'name': 'Beef Stew', 'price': 9000},
      {'name': 'Chapati Roll', 'price': 2500},
    ],
    'Fresh Hot': [
      {'name': 'Grilled Chicken', 'price': 12000},
      {'name': 'Hot Wings', 'price': 8000},
      {'name': 'Rice Bowl', 'price': 4000},
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _optimalMealTimes = widget.initialOptimalMealTimes;
    if (_optimalMealTimes == null) {
      _fetchOptimalMealTimes();
    }
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
            SizedBox(height: 32),
            if (_ordersForDay.isNotEmpty)
              ...[
                _buildOrderSummary(),
                SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutPage(
                            orders: _ordersForDay,
                            optimalMealTimes: _optimalMealTimes,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.payment),
                    label: Text('Checkout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
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
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
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
                  e.value != null ? DateFormat('HH:mm').format(e.value!) : 'No free slot',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List items, String? value, ValueChanged<String?> onChanged, {bool enabled = true}) {
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
          items: label == 'Food'
              ? items.map<DropdownMenuItem<String>>((item) => DropdownMenuItem(
                    value: item['name'],
                    child: Text('${item['name']} (UGX ${item['price']})'),
                  )).toList()
              : items.map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: enabled
              ? (val) {
                  if (label == 'Food') {
                    final selected = items.firstWhere((item) => item['name'] == val, orElse: () => <String, dynamic>{});
                    setState(() {
                      _food = val;
                      _foodPrice = selected.isNotEmpty ? selected['price'] : null;
                    });
                  } else {
                    onChanged(val);
                  }
                }
              : null,
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
    // Prevent placing orders for past dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate != null && _selectedDate!.isBefore(today)) {
      return false;
    }
    return _selectedDate != null &&
        _mealType != null &&
        _restaurant != null &&
        _food != null &&
        _foodPrice != null &&
        _paymentMethod != null &&
        _location != null &&
        _location!.trim().isNotEmpty;
  }

  void _submitOrder() {
    // Save the order locally for summary
    setState(() {
      _ordersForDay.add({
        'mealType': _mealType,
        'restaurant': _restaurant,
        'food': _food,
        'foodPrice': _foodPrice,
        'paymentMethod': _paymentMethod,
        'location': _location,
        'orderDate': _selectedDate,
      });
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Placed!'),
        content: Text('Your order has been placed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Reset only mealType, restaurant, food, paymentMethod
                _mealType = null;
                _restaurant = null;
                _food = null;
                _foodPrice = null;
                _paymentMethod = null;
                // Do NOT reset _location, keep it for convenience
              });
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Card(
      color: AppColors.secondary.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Orders Placed for the Day', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            ..._ordersForDay.map((order) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.fastfood, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('${order['mealType']}: ', style: AppTextStyles.body),
                  Text('${order['food']} (UGX ${order['foodPrice']}) from ${order['restaurant']}', style: AppTextStyles.body),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
} 