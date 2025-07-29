import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/delivery_location.dart';
import '../../constants/app_colours.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeliveryMapScreen extends StatefulWidget {
  final List<DeliveryLocation> deliveries;

  const DeliveryMapScreen({Key? key, required this.deliveries}) : super(key: key);

  @override
  _DeliveryMapScreenState createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _currentDeliveryIndex = 0;
  bool _showRoute = false;
  LatLngBounds? _deliveryBounds;
  List<int>? _waypointOrder; // New field to store the optimized order
  LatLng? _currentLocation;
  int _currentOptimizedIndex = 0;
  late List<DeliveryLocation> _activeDeliveries;

  final String _googleApiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';

  // Remove multi-route support fields
  // List<Map<String, dynamic>> _routes = [];
  // int _selectedRouteIndex = 0;
  // List<Color> _routeColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.brown];

  @override
  void initState() {
    super.initState();
    _activeDeliveries = List.from(widget.deliveries); // Make a mutable copy
    _initializeMap();
    _loadDeliveryDetails();
    // Fetch multiple routes after map and location are ready
    Future.delayed(Duration(seconds: 2), _optimizeRoute);
  }

  Future<void> _initializeMap() async {
    if (_activeDeliveries.isNotEmpty) {
      await _getCurrentLocation();
      _createMarkers();
      _calculateBounds();
      await _optimizeRoute(); // Optimize route when map is initialized
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission permanently denied. Please enable it in settings.')),
      );
      return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _createMarkers() {
    _markers = _activeDeliveries.map((delivery) {
      return Marker(
        markerId: MarkerId(delivery.id),
        position: delivery.coordinates,
        infoWindow: InfoWindow(
          title: delivery.name,
          snippet: delivery.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          delivery.isPickup 
              ? BitmapDescriptor.hueOrange  // Pickup locations in orange
              : BitmapDescriptor.hueGreen,  // Dropoff locations in green
        ),
      );
    }).toSet();
  }

  void _calculateBounds() {
    if (_activeDeliveries.isEmpty) return;

    double minLat = _activeDeliveries[0].coordinates.latitude;
    double maxLat = _activeDeliveries[0].coordinates.latitude;
    double minLng = _activeDeliveries[0].coordinates.longitude;
    double maxLng = _activeDeliveries[0].coordinates.longitude;

    for (var delivery in _activeDeliveries) {
      final lat = delivery.coordinates.latitude;
      final lng = delivery.coordinates.longitude;
      
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      if (lng < minLng) minLng = lng;
      if (lng > maxLng) maxLng = lng;
    }

    setState(() {
      _deliveryBounds = LatLngBounds(
        northeast: LatLng(maxLat, maxLng),
        southwest: LatLng(minLat, minLng),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Zoom to show all markers after a small delay to allow map to initialize
    Future.delayed(Duration(milliseconds: 500), () {
      if (_deliveryBounds != null) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(_deliveryBounds!, 100),
        );
      }
    });
  }

  void _toggleRouteVisibility() {
    setState(() {
      _showRoute = !_showRoute;
      if (_showRoute) {
        _createRoutePolylines();
      } else {
        _polylines.clear();
      }
    });
  }

  void _createRoutePolylines() {
    _polylines.clear();
    
    if (_activeDeliveries.length < 2) return;

    for (int i = 0; i < _activeDeliveries.length - 1; i++) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          color: AppColors.primary,
          width: 4,
          points: [
            _activeDeliveries[i].coordinates,
            _activeDeliveries[i + 1].coordinates,
          ],
        ),
      );
    }
  }

  void _nextDelivery() {
    if (_currentDeliveryIndex < _activeDeliveries.length - 1) {
      setState(() {
        _currentDeliveryIndex++;
        _moveCameraToCurrent();
      });
    }
  }

  void _previousDelivery() {
    if (_currentDeliveryIndex > 0) {
      setState(() {
        _currentDeliveryIndex--;
        _moveCameraToCurrent();
      });
    }
  }

  void _moveCameraToCurrent() {
    if (_activeDeliveries.isEmpty) return;
    
    final delivery = _activeDeliveries[_currentDeliveryIndex];
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(delivery.coordinates, 15),
    );
  }

  Future<void> _optimizeRoute() async {
    if (_activeDeliveries.isEmpty || _currentLocation == null) return;

    final origin = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    
    // If only one delivery, no optimization needed
    if (_activeDeliveries.length == 1) {
      setState(() {
        _waypointOrder = [0]; // Single delivery at index 0
        _polylines = {}; // Clear polylines for single delivery
      });
      return;
    }
    
    // For multiple deliveries, treat all as waypoints (no fixed destination)
    final waypoints = _activeDeliveries
        .map((d) => '${d.coordinates.latitude},${d.coordinates.longitude}')
        .join('|');

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$origin&waypoints=optimize:true|$waypoints&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final waypointOrder = List<int>.from(route['waypoint_order']);
        final polyline = route['overview_polyline']['points'];
        List<PointLatLng> result = PolylinePoints.decodePolyline(polyline);
        setState(() {
          _waypointOrder = waypointOrder;
          _polylines = {
            Polyline(
              polylineId: PolylineId('optimized_route'),
              color: AppColors.primary,
              width: 5,
              points: result.map((p) => LatLng(p.latitude, p.longitude)).toList(),
            ),
          };
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Route optimization failed: ${data['status']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error optimizing route: $e')),
      );
    }
  }

  // Remove _fetchMultipleRoutes, _drawAllRoutes, _onRouteSelected, _getBoundsForRoute, _buildRouteSelectionSheet

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Route'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeMap,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _activeDeliveries.isNotEmpty 
                  ? _activeDeliveries[0].coordinates 
                  : LatLng(0.3136, 32.5811),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
          ),
          if (_activeDeliveries.isNotEmpty && _waypointOrder != null && _waypointOrder!.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildOptimizedDeliveryCard(),
            ),
        ],
      ),
    );
  }

  Widget _buildOptimizedDeliveryCard() {
    if (_waypointOrder == null || _waypointOrder!.isEmpty) return SizedBox.shrink();
    final delivery = _activeDeliveries[_waypointOrder![_currentOptimizedIndex]];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Make the header row horizontally scrollable to prevent overflow
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Icon(
                    delivery.isPickup ? Icons.store : Icons.home,
                    color: delivery.isPickup ? Colors.orange : Colors.green,
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      delivery.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Move stop indicator and route icon together
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stop ${_currentOptimizedIndex + 1}/${_waypointOrder!.length}',
                        style: TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.route, color: AppColors.primary, size: 20),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                delivery.address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.customerName,
                          style: TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        if (delivery.customerPhone.isNotEmpty)
                          Text(
                            delivery.customerPhone,
                            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.fastfood, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      delivery.items,
                      style: TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'UGX ${delivery.earning}',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _callCustomerFor(delivery.customerPhone),
                    icon: Icon(Icons.phone, size: 16),
                    label: Text('Call Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: _currentOptimizedIndex > 0
                        ? () => setState(() => _currentOptimizedIndex--)
                        : null,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check_circle, color: AppColors.success),
                        tooltip: 'Mark as completed',
                        onPressed: () => _completeDelivery(_waypointOrder![_currentOptimizedIndex]),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Cancel this delivery',
                        onPressed: () => _removeDestination(_waypointOrder![_currentOptimizedIndex]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward),
                    onPressed: _currentOptimizedIndex < _waypointOrder!.length - 1
                        ? () => setState(() => _currentOptimizedIndex++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Remove _buildRouteSelectionSheet

  Widget _buildNavigationControls() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: _previousDelivery,
              color: _currentDeliveryIndex > 0 ? AppColors.primary : Colors.grey,
            ),
            IconButton(
              icon: Icon(_showRoute ? Icons.route : Icons.route_outlined),
              onPressed: _toggleRouteVisibility,
              color: _showRoute ? AppColors.primary : Colors.grey,
              tooltip: _showRoute ? 'Hide Route' : 'Show Route',
            ),
            // Navigation button removed
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: _nextDelivery,
              color: _currentDeliveryIndex < _activeDeliveries.length - 1 
                  ? AppColors.primary 
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  void _callCustomerFor(String phoneNumber) async {
    final formatted = phoneNumber.startsWith('+') ? phoneNumber : '+$phoneNumber';
    final url = 'tel:$formatted';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not call $formatted')),
      );
    }
  }

  Future<void> _loadDeliveryDetails() async {
    // Load additional delivery details if needed
    // This can be used to fetch real-time updates from Firebase
  }

  Future<void> _removeDestination(int indexToRemove) async {
    final delivery = _activeDeliveries[indexToRemove];
    
    // Show confirmation dialog
    bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to cancel this delivery?'),
              SizedBox(height: 12),
              Text(
                'Customer: ${delivery.name}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Address: ${delivery.address}'),
              SizedBox(height: 12),
              Text(
                'This action cannot be undone and will notify the customer.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Keep Delivery'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Cancel Delivery', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      await _cancelDeliveryInDatabase(delivery);
      
      setState(() {
        _activeDeliveries.removeAt(indexToRemove);
        _waypointOrder = null;
        _currentOptimizedIndex = 0;
        _createMarkers(); // Update markers after removal
      });
      
      // Check if all deliveries are removed
      if (_activeDeliveries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All deliveries cancelled. Returning to home.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
        return;
      }
      
      _optimizeRoute();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _cancelDeliveryInDatabase(DeliveryLocation delivery) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update the delivery status in Firestore
      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(delivery.id)
          .update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': 'rider_${currentUser.uid}',
        'cancellationReason': 'Cancelled by delivery rider',
      });

      print('Delivery ${delivery.id} cancelled successfully in database');
    } catch (e) {
      print('Error cancelling delivery in database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel delivery in database: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  Future<void> _completeDelivery(int indexToComplete) async {
    final delivery = _activeDeliveries[indexToComplete];
    
    // Show confirmation dialog
    bool? shouldComplete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Complete Delivery'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mark this delivery as completed?'),
              SizedBox(height: 12),
              Text(
                'Customer: ${delivery.name}',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Address: ${delivery.address}'),
              SizedBox(height: 12),
              Text(
                '',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
              ),
              child: Text('Complete Delivery', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldComplete == true) {
      await _completeDeliveryInDatabase(delivery);
      
      setState(() {
        _activeDeliveries.removeAt(indexToComplete);
        _waypointOrder = null;
        _currentOptimizedIndex = 0;
        _createMarkers(); // Update markers after completion
      });
      
      // Check if all deliveries are completed
      if (_activeDeliveries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All deliveries completed! Great job! Returning to home.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
        return;
      }
      
      _optimizeRoute();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery completed successfully! 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _completeDeliveryInDatabase(DeliveryLocation delivery) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update the delivery status in Firestore
      await FirebaseFirestore.instance
          .collection('deliveries')
          .doc(delivery.id)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': 'rider_${currentUser.uid}',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Delivery ${delivery.id} completed successfully in database');
    } catch (e) {
      print('Error completing delivery in database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete delivery in database: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }
}