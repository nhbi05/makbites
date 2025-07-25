import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../models/cart_model.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'restaurant_menu_screen.dart';
import '../../widgets/map_picker.dart'; // Added import for MapPicker
import 'dart:convert'; // Added import for json
import 'package:http/http.dart' as http; // Added import for http

class BrowseRestaurantsScreen extends StatefulWidget {
  @override
  _BrowseRestaurantsScreenState createState() => _BrowseRestaurantsScreenState();
}

class _BrowseRestaurantsScreenState extends State<BrowseRestaurantsScreen> {
  List<Map<String, dynamic>> restaurants = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    listenToRestaurants();
  }

  void listenToRestaurants() {
    final names = [
      "MK-Catering Services",
      "Fresh Hot",
      "Lumumba Cafe",
      "Freddoz",
      "Ssalongo's"
    ];
    FirebaseFirestore.instance
        .collection('restaurants')
        .where('name', whereIn: names)
        .snapshots()
        .listen((snapshot) {
      final seenNames = <String>{};
    setState(() {
        restaurants = snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['docId'] = doc.id; // Attach the Firestore document ID
              return data;
            })
            .where((restaurant) => seenNames.add(restaurant['name']))
            .toList();
      isLoading = false;
      });
    });
  }

  Widget _buildModernRestaurantCard(String name, String location, String imageUrl, String docId) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 18, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantMenuScreen(
                restaurantDocId: docId,
                restaurantName: name,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl != ""
                    ? Image.network(
                        imageUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                    : Icon(Icons.restaurant, size: 56, color: Colors.grey[400]),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text(location, style: TextStyle(color: Colors.black.withOpacity(0.7))),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Browse Restaurants'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : restaurants.isEmpty
              ? Center(child: Text('No restaurants found.'))
              : ListView.builder(
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return _buildModernRestaurantCard(
                      restaurant['name'] ?? 'No Name',
                      restaurant['location'] ?? '',
                      restaurant['profileImage'] ?? '',
                      restaurant['docId'] ?? '',
                    );
                  },
                ),
    );
  }
}

// Remove the RestaurantMenuScreen class from this file entirely, so it is only defined in restaurant_menu_screen.dart

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    double total = 0;
    for (final item in cart.items) {
      final price = (item['price'] ?? 0) as num;
      final quantity = (item['quantity'] ?? 1) as num;
      total += price * quantity;
    }
    return Scaffold(
      appBar: AppBar(title: Text('Your Cart')),
      body: cart.items.isEmpty
          ? Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final price = (item['price'] ?? 0) as num;
                      final quantity = (item['quantity'] ?? 1) as num;
                      return ListTile(
                        leading: item['imageUrl'] != null && item['imageUrl'] != ''
                            ? Image.network(item['imageUrl'], width: 40, height: 40, fit: BoxFit.cover)
                            : Icon(Icons.fastfood, size: 32, color: Colors.grey[400]),
                        title: Text(item['name'] ?? 'No Name'),
                        subtitle: Text('UGX $price x $quantity = UGX ${price * quantity}'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            cart.removeItem(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('UGX $total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CheckoutScreen(total: total)),
                        );
                      },
                      child: Text('Checkout'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final double total;
  CheckoutScreen({required this.total});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Autocomplete for location
  final TextEditingController _locationSearchController = TextEditingController();
  List<Map<String, String>> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  final String _apiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';
  Map<String, dynamic>? _pickedLocationData; // To store lat/lng/address

  late int deliveryFee;
  late String deliveryFeeLabel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final options = [0, 500, 1000];
    deliveryFee = options[Random().nextInt(options.length)];
    deliveryFeeLabel = deliveryFee == 0 ? 'Free' : 'UGX $deliveryFee';
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
              _pickedLocationData = {
                'address': suggestion['description'],
                'lat': loc['lat'],
                'lng': loc['lng'],
              };
            });
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }
    setState(() => _isSearchingLocation = false);
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPicker()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _pickedLocationData = result;
        _locationSearchController.text = result['address'] ?? '';
      });
    }
  }

  Future<void> _saveOrderToFirestore(List<Map<String, dynamic>> items, String location, double total, int deliveryFee) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    try {
      // Fetch the user's phone number
      String? customerPhone;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        customerPhone = userDoc.data()?['phone'];
      }
      // Determine restaurant name from the first item (assuming all items are from the same restaurant)
      String? restaurantName;
      if (items.isNotEmpty && items[0].containsKey('restaurant')) {
        restaurantName = items[0]['restaurant'];
      }
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'items': items,
        'location': location,
        'foodPrice': total,
        'deliveryFee': deliveryFee,
        'clientTimestamp': DateTime.now(),
        'serverTimestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'sentAt': DateTime.now(),
        'orderSource': 'browse',
        if (restaurantName != null) 'restaurant': restaurantName,
        if (customerPhone != null) 'customerPhone': customerPhone,
        if (_pickedLocationData != null) ...{
          'customerLocation': {
            'latitude': _pickedLocationData!['lat'],
            'longitude': _pickedLocationData!['lng'],
          },
          'customerAddress': _pickedLocationData!['address'],
        },
      });
    } catch (e) {
      print('Error saving order: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartModel>(context);
    double itemsTotal = 0;
    for (final item in cart.items) {
      final price = (item['price'] ?? 0) as num;
      final quantity = (item['quantity'] ?? 1) as num;
      itemsTotal += price * quantity;
    }
    double grandTotal = itemsTotal + deliveryFee;
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                final price = (item['price'] ?? 0) as num;
                final quantity = (item['quantity'] ?? 1) as num;
                return ListTile(
                  leading: item['imageUrl'] != null && item['imageUrl'] != ''
                      ? Image.network(item['imageUrl'], width: 40, height: 40, fit: BoxFit.cover)
                      : Icon(Icons.fastfood, size: 32, color: Colors.grey[400]),
                  title: Text(item['name'] ?? 'No Name'),
                  subtitle: Text('UGX $price x $quantity = UGX ${price * quantity}'),
                );
              },
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Delivery Fee:', style: TextStyle(fontSize: 16)),
                Text(deliveryFeeLabel, style: TextStyle(fontSize: 16)),
              ],
            ),
            SizedBox(height: 8),
            // Autocomplete location field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  TextField(
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
                                      _pickedLocationData = null;
                                    });
                                  },
                                )
                              : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  if (_locationSuggestions.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _locationSuggestions[index];
                          return ListTile(
                            title: Text(suggestion['description'] ?? ''),
                            onTap: () => _selectLocationSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.map),
                label: Text('Pick on Map'),
                onPressed: _openMapPicker,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('UGX $grandTotal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: _isSaving
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: () async {
                        if (_locationSearchController.text.trim().isEmpty || _pickedLocationData == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Please select a delivery location.')),
                          );
                          return;
                        }
                        setState(() => _isSaving = true);
                        try {
                          await _saveOrderToFirestore(
                            cart.items,
                            _locationSearchController.text.trim(),
                            itemsTotal,
                            deliveryFee,
                          );
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Order placed successfully!')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to place order.')),
                          );
                        }
                      },
                      child: Text('Place Order'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 