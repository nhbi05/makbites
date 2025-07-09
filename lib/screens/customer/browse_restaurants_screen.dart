import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    fetchRestaurants();
  }

  Future<void> fetchRestaurants() async {
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
    print('Fetched docs: ${snapshot.docs.length}');
    for (var doc in snapshot.docs) {
      print('Doc data: ${doc.data()}');
    }
    setState(() {
      restaurants = snapshot.docs.map((doc) => doc.data()).toList();
      isLoading = false;
    });
  }

  Widget _buildModernRestaurantCard(String name, String location, String imageUrl) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.only(bottom: 18, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
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
                    );
                  },
                ),
    );
  }
} 