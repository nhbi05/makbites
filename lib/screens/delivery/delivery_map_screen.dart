import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/delivery_location.dart';
import '../../constants/app_colours.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

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

  final String _googleApiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0'; // <-- Replace with your real API key

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (widget.deliveries.isNotEmpty) {
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
    _markers = widget.deliveries.map((delivery) {
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
    if (widget.deliveries.isEmpty) return;

    double minLat = widget.deliveries[0].coordinates.latitude;
    double maxLat = widget.deliveries[0].coordinates.latitude;
    double minLng = widget.deliveries[0].coordinates.longitude;
    double maxLng = widget.deliveries[0].coordinates.longitude;

    for (var delivery in widget.deliveries) {
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
    
    if (widget.deliveries.length < 2) return;

    for (int i = 0; i < widget.deliveries.length - 1; i++) {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          color: AppColors.primary,
          width: 4,
          points: [
            widget.deliveries[i].coordinates,
            widget.deliveries[i + 1].coordinates,
          ],
        ),
      );
    }
  }

  void _nextDelivery() {
    if (_currentDeliveryIndex < widget.deliveries.length - 1) {
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
    if (widget.deliveries.isEmpty) return;
    
    final delivery = widget.deliveries[_currentDeliveryIndex];
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(delivery.coordinates, 15),
    );
  }

  Future<void> _optimizeRoute() async {
    if (widget.deliveries.isEmpty || _currentLocation == null) return;

    final origin = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    final destination = '${widget.deliveries.last.coordinates.latitude},${widget.deliveries.last.coordinates.longitude}';
    final waypoints = widget.deliveries
        .sublist(0, widget.deliveries.length - 1)
        .map((d) => '${d.coordinates.latitude},${d.coordinates.longitude}')
        .join('|');

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&waypoints=optimize:true|$waypoints&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final route = data['routes'][0];
        final waypointOrder = List<int>.from(route['waypoint_order']);
        final polyline = route['overview_polyline']['points'];
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(polyline);
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

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  void _callCustomerFor(String phone) {
    final url = 'tel:$phone';
    _launchUrl(url);
  }

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
              target: widget.deliveries.isNotEmpty 
                  ? widget.deliveries[0].coordinates 
                  : LatLng(0.3136, 32.5811), // Default to Makerere coordinates
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
          ),
          if (widget.deliveries.isNotEmpty && _waypointOrder != null && _waypointOrder!.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildOptimizedDeliveryCard(),
            ),
          if (widget.deliveries.isNotEmpty) ...[
            // Navigation controls
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildNavigationControls(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptimizedDeliveryCard() {
    if (_waypointOrder == null || _waypointOrder!.isEmpty) return SizedBox.shrink();
    final delivery = widget.deliveries[_waypointOrder![_currentOptimizedIndex]];
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  delivery.isPickup ? Icons.store : Icons.home,
                  color: delivery.isPickup ? Colors.orange : Colors.green,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    delivery.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  'Stop ${_currentOptimizedIndex + 1}/${_waypointOrder!.length}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(delivery.address),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(delivery.customerName, style: TextStyle(color: Colors.grey)),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.fastfood, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(delivery.items, style: TextStyle(color: Colors.grey)),
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
    );
  }

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
              color: _currentDeliveryIndex < widget.deliveries.length - 1 
                  ? AppColors.primary 
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}