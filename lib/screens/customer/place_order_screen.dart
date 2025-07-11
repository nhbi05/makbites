import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_event.dart';
import 'checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Models for Restaurant and MenuItem
class MenuItem {
  final String id;
  final String name;
  final int price;
  final String imageUrl;

  MenuItem({required this.id, required this.name, required this.price, required this.imageUrl});

  factory MenuItem.fromFirestore(String id, Map<String, dynamic> data) {
    final priceRaw = data['price'];
    int price;
    if (priceRaw is int) {
      price = priceRaw;
    } else if (priceRaw is double) {
      price = priceRaw.toInt();
    } else {
      price = 0;
    }
    return MenuItem(
      id: id,
      name: data['name'] ?? '',
      price: price,
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}

class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final List<MenuItem> menu;

  Restaurant({required this.id, required this.name, required this.imageUrl, required this.menu});

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data, List<MenuItem> menu) {
    return Restaurant(
      id: id,
      name: data['name'] ?? '',
      imageUrl: data['profileImage'] ?? '', // Use profileImage for consistency
      menu: menu,
    );
  }
}

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
  List<Restaurant> _restaurants = [];
  Restaurant? _selectedRestaurant;
  MenuItem? _selectedMenuItem;
  bool _loadingRestaurants = false;
  List<Map<String, dynamic>> _ordersForDay = [];

  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Supper'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _optimalMealTimes = widget.initialOptimalMealTimes;
    if (_optimalMealTimes == null) {
      _fetchOptimalMealTimes();
    }
    _fetchRestaurants();
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

  Future<void> _fetchRestaurants() async {
    setState(() { _loadingRestaurants = true; });
    final names = [
      "MK-Catering Services",
      "Fresh Hot",
      "Lumumba Cafe",
      "Freddoz",
      "Ssalongo's"
    ];
    final snapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .where('name', whereIn: names)
        .get();
    List<Restaurant> restaurants = [];
    for (final doc in snapshot.docs) {
      final menuSnapshot = await doc.reference.collection('items').get();
      final menu = menuSnapshot.docs.isNotEmpty
          ? menuSnapshot.docs.map((m) => MenuItem.fromFirestore(m.id, m.data())).toList()
          : <MenuItem>[];
      restaurants.add(Restaurant.fromFirestore(doc.id, doc.data(), menu));
    }
    setState(() {
      _restaurants = restaurants;
      _loadingRestaurants = false;
    });
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
            if (_loadingRestaurants)
              Center(child: CircularProgressIndicator())
            else if (_restaurants.isEmpty)
              Text('No restaurants available.')
            else
              _buildDropdown('Restaurant', _restaurants.map((r) => r.name).toList(), _restaurant, (val) {
                setState(() {
                  _restaurant = val;
                  _food = null;
                });
              }),
            SizedBox(height: 16),
            _buildDropdown(
              'Food',
              _restaurant != null
                  ? _restaurants.firstWhere((r) => r.name == _restaurant, orElse: () => Restaurant(id: '', name: '', imageUrl: '', menu: [])).menu.map((m) => m.name + ' (UGX ${m.price})').toList()
                  : [],
              _food,
              (val) => setState(() {
                final selected = val;
                // Parse food name and price from the selected string
                String? foodName;
                int? foodPrice;
                final regExp = RegExp(r'^(.*) \(UGX (\d+)\)$');
                final match = regExp.firstMatch(selected ?? '');
                if (match != null) {
                  foodName = match.group(1)?.trim();
                  foodPrice = int.tryParse(match.group(2) ?? '');
                } else {
                  foodName = selected;
                  foodPrice = null;
                }
                _food = foodName;
                _foodPrice = foodPrice;
              }),
              enabled: _restaurant != null &&
                  _restaurants.any((r) => r.name == _restaurant && r.menu.isNotEmpty),
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
                            orderSource: 'schedule', // Pass the source
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
                    value: item,
                    child: Text(item),
                  )).toList()
              : items.map<DropdownMenuItem<String>>((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: enabled
              ? (val) {
                  if (label == 'Food') {
                    final selected = items.firstWhere((item) => item == val, orElse: () => '');
                    // Parse food name and price from the selected string
                    String? foodName;
                    int? foodPrice;
                    final regExp = RegExp(r'^(.*) \(UGX (\d+)\)$');
                    final match = regExp.firstMatch(selected ?? '');
                    if (match != null) {
                      foodName = match.group(1)?.trim();
                      foodPrice = int.tryParse(match.group(2) ?? '');
                    } else {
                      foodName = selected;
                      foodPrice = null;
                    }
                    setState(() {
                      _food = foodName;
                      _foodPrice = foodPrice;
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
    // Prevent placing an order for a meal time that has already passed (for today)
    final now = DateTime.now();
    if (_selectedDate != null &&
        _mealType != null &&
        _optimalMealTimes != null &&
        _optimalMealTimes![_mealType!] != null) {
      final selectedDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final today = DateTime(now.year, now.month, now.day);
      final mealTime = _optimalMealTimes![_mealType!];
      if (selectedDate == today && mealTime != null && mealTime.isBefore(now)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Invalid Order Time'),
            content: Text('You cannot place an order for a meal time that has already passed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }
    // Add the order to the local summary only
    setState(() {
      _ordersForDay.add({
        'mealType': _mealType,
        'restaurant': _restaurant,
        'food': _food,
        'foodPrice': _foodPrice,
        'foodImage': null, // No image for simple text dropdowns
        'restaurantImage': null, // No image for simple text dropdowns
        'paymentMethod': _paymentMethod,
        'location': _location,
        'orderDate': _selectedDate,
      });
      // Reset only mealType, restaurant, food, paymentMethod
      _mealType = null;
      _restaurant = null;
      _food = null;
      _foodPrice = null;
      _paymentMethod = null;
      // Do NOT reset _location, keep it for convenience
    });
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