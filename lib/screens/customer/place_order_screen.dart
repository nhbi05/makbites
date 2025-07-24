import 'package:flutter/material.dart';
import '../../constants/app_colours.dart';
import '../../constants/text_styles.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_event.dart';
import 'checkout_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../automation/add_event_form.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String? _location;
  Map<String, DateTime?>? _optimalMealTimes;
  bool _loadingMealTimes = false;
  List<Map<String, dynamic>> _ordersForDay = [];

  // Simple dropdown state for demonstration
  String? _selectedRestaurantSimple;
  String? _selectedFoodSimple;
  final List<String> _restaurantOptions = [
    'MK-Catering Services',
    'Fresh Hot',
    'Lumumba Cafe',
    'Freddoz',
    "Ssalongo's"
  ];
  final List<String> _foodOptions = [
    'Chips',
    'Katogo',
    'Chicken Pilau',
    'Soda',
    'Water',
    'Rice and Peas',
    'Fresh Juice'
  ];

  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Supper'];

  String? _locationAddress;
  double? _locationLat;
  double? _locationLng;

  // Autocomplete functionality
  final TextEditingController _locationSearchController = TextEditingController();
  List<Map<String, String>> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  final String _apiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _optimalMealTimes = widget.initialOptimalMealTimes;
    if (_optimalMealTimes == null) {
      _fetchOptimalMealTimes();
    }
    _locationSearchController.addListener(_onLocationSearchChanged);
  }

  @override
  void dispose() {
    _locationSearchController.removeListener(_onLocationSearchChanged);
    _locationSearchController.dispose();
    super.dispose();
  }

  void _onLocationSearchChanged() async {
    final query = _locationSearchController.text.trim();
    if (query.isEmpty) {
      setState(() => _locationSuggestions = []);
      return;
    }
    await _fetchLocationAutocompleteSuggestions(query);
  }

  Future<void> _fetchLocationAutocompleteSuggestions(String input) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&components=country:UG',
    );
    setState(() => _isSearchingLocation = true);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _locationSuggestions = List<Map<String, String>>.from(
              (data['predictions'] as List).map((item) => {
                'description': item['description'].toString(),
                'place_id': item['place_id'].toString(),
              }),
            );
          });
        } else {
          setState(() => _locationSuggestions = []);
        }
      } else {
        setState(() => _locationSuggestions = []);
      }
    } catch (e) {
      setState(() => _locationSuggestions = []);
    } finally {
      setState(() => _isSearchingLocation = false);
    }
  }

  Future<void> _selectLocationSuggestion(Map<String, String> suggestion) async {
    setState(() {
      _isSearchingLocation = true;
      _locationSuggestions = [];
      _locationSearchController.text = suggestion['description'] ?? '';
    });
    final placeId = suggestion['place_id'];
    if (placeId != null) {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey',
      );
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final loc = data['result']['geometry']['location'];
            setState(() {
              _locationAddress = suggestion['description'];
              _locationLat = loc['lat'];
              _locationLng = loc['lng'];
            });
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }
    setState(() => _isSearchingLocation = false);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Open Add Event Form
          final eventData = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEventForm(
                initialDate: _selectedDate,
              ),
            ),
          );
          if (eventData != null) {
            // Add event to Firestore
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              final id = FirebaseFirestore.instance.collection('events').doc().id;
              final userEvent = UserEvent(
                id: id,
                userId: user.uid,
                title: eventData['title'] ?? 'Untitled Event',
                startTime: DateTime(
                  eventData['date'].year,
                  eventData['date'].month,
                  eventData['date'].day,
                  eventData['startTime'].hour,
                  eventData['startTime'].minute,
                ),
                endTime: DateTime(
                  eventData['date'].year,
                  eventData['date'].month,
                  eventData['date'].day,
                  eventData['endTime'].hour,
                  eventData['endTime'].minute,
                ),
                isGoogleEvent: false,
                googleEventId: null,
                location: eventData['location'],
              );
              await FirebaseFirestore.instance.collection('events').doc(id).set(userEvent.toMap());
              await _fetchOptimalMealTimes();
            }
          }
        },
        backgroundColor: AppColors.secondary,
        child: Icon(Icons.add, color: AppColors.white),
        tooltip: 'Add Event',
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
            // Simple Select Restaurant dropdown
            DropdownButtonFormField<String>(
              value: _selectedRestaurantSimple,
              decoration: InputDecoration(
                labelText: 'Select Restaurant',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _restaurantOptions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _selectedRestaurantSimple = val),
            ),
            SizedBox(height: 16),
            // Simple Select Food dropdown
            DropdownButtonFormField<String>(
              value: _selectedFoodSimple,
              decoration: InputDecoration(
                labelText: 'Select Food',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _foodOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) => setState(() => _selectedFoodSimple = val),
            ),
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
                      // _food = foodName; // Removed
                      // _foodPrice = foodPrice; // Removed
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
    return SizedBox.shrink(); // Remove payment method UI
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field with autocomplete
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _locationSearchController,
            decoration: InputDecoration(
              hintText: 'Search for delivery location...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              suffixIcon: _isSearchingLocation
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _locationSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _locationSearchController.clear();
                            setState(() {
                              _locationSuggestions = [];
                              _locationAddress = null;
                              _locationLat = null;
                              _locationLng = null;
                            });
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        
        // Suggestions dropdown
        if (_locationSuggestions.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _locationSuggestions.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _locationSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on, color: Colors.red, size: 20),
                  title: Text(
                    suggestion['description'] ?? '',
                    style: TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectLocationSuggestion(suggestion),
                );
              },
            ),
          ),
        
        SizedBox(height: 12),
        
        // Map picker button
        ElevatedButton.icon(
          icon: Icon(Icons.map),
          label: Text(_locationAddress != null ? 'Change Location on Map' : 'Select on Map'),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MapPicker()),
            );
            if (result != null) {
              setState(() {
                _locationAddress = result['address'];
                _locationLat = result['lat'];
                _locationLng = result['lng'];
                _locationSearchController.text = result['address'] ?? '';
              });
            }
          },
        ),
        
        // Selected location display
        if (_locationAddress != null)
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Selected: $_locationAddress',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ),
      ],
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
        _locationAddress != null &&
        _locationLat != null &&
        _locationLng != null;
  }

  void _submitOrder() async {
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
    // Fetch customer phone asynchronously
    String customerPhone = '';
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      print('Fetched user doc for $userId: ${userDoc.data()}'); // <-- Add this
      customerPhone = userDoc.data()?['phone'] ?? '';
      print('Fetched phone: $customerPhone'); // <-- And this
    }
    // Add the order to the local summary only
    setState(() {
      _ordersForDay.add({
        'mealType': _mealType,
        'location': _locationAddress,
        'locationLat': _locationLat,
        'locationLng': _locationLng,
        'orderDate': _selectedDate,
        'restaurant': _selectedRestaurantSimple,
        'food': _selectedFoodSimple,
        'foodPrice': _getFoodPrice(_selectedFoodSimple),
        'customerPhone': customerPhone,
      });
      // Reset only mealType, location, restaurant, food
      _mealType = null;
      _locationAddress = null;
      _locationLat = null;
      _locationLng = null;
      _selectedRestaurantSimple = null;
      _selectedFoodSimple = null;
      _locationSearchController.clear();
      _locationSuggestions = [];
    });
  }

  int? _getFoodPrice(String? food) {
    // Simple static mapping for demonstration
    switch (food) {
      case 'Chips': return 3000;
      case 'Katogo': return 2500;
      case 'Chicken Pilau': return 10000;
      case 'Soda': return 1000;
      case 'Water': return 500;
      case 'Rice and Peas': return 3000;
      case 'Fresh Juice': return 2000;
      default: return null;
    }
  }

  Widget _buildOrderSummary() {
    int total = 0;
    for (final order in _ordersForDay) {
      total += (order['foodPrice'] ?? 0) as int;
    }
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
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fastfood, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('${order['mealType'] ?? ''}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Food: ${order['food'] ?? ''}', style: AppTextStyles.body),
                  Text('Restaurant: ${order['restaurant'] ?? ''}', style: AppTextStyles.body),
                  Text('Price: UGX ${order['foodPrice'] ?? ''}', style: AppTextStyles.body),
                  Text('Location: ${order['location'] ?? ''}', style: AppTextStyles.body),
                  Divider(),
                ],
              ),
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                Text('UGX $total', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MapPicker extends StatefulWidget {
  @override
  _MapPickerState createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  LatLng? _pickedLocation;
  String? _address;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _pickedLocation = LatLng(position.latitude, position.longitude);
    });
    _getAddress(_pickedLocation!);
  }

  Future<void> _getAddress(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _address = "${place.name}, ${place.locality}, ${place.subAdministrativeArea}";
        });
      }
    } catch (e) {
      setState(() {
        _address = null;
      });
    }
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _pickedLocation = latLng;
    });
    _getAddress(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick Delivery Location')),
      body: _pickedLocation == null
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickedLocation!,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: _pickedLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId('picked'),
                            position: _pickedLocation!,
                          ),
                        }
                      : {},
                  onTap: _onMapTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                ),
                if (_address != null)
                  Positioned(
                    bottom: 80,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          _address!,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed: _pickedLocation != null
                        ? () {
                            Navigator.pop(context, {
                              'lat': _pickedLocation!.latitude,
                              'lng': _pickedLocation!.longitude,
                              'address': _address,
                            });
                          }
                        : null,
                    child: Text('Confirm Location'),
                  ),
                ),
              ],
            ),
    );
  }
} 