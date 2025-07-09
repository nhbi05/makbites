import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/delivery_location.dart';
import '../../constants/app_colours.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    if (widget.deliveries.isNotEmpty) {
      _createMarkers();
      _calculateBounds();
    }
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

  void _startNavigationToCurrent() {
    if (_currentDeliveryIndex >= widget.deliveries.length) return;
    
    final delivery = widget.deliveries[_currentDeliveryIndex];
    final lat = delivery.coordinates.latitude;
    final lng = delivery.coordinates.longitude;
    
    // Open in Google Maps app for navigation
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    
    _launchUrl(url);
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch navigation')),
      );
    }
  }

  void _callCurrentCustomer() {
    if (_currentDeliveryIndex >= widget.deliveries.length) return;
    
    final phone = widget.deliveries[_currentDeliveryIndex].customerPhone;
    final url = 'tel:$phone';
    
    _launchUrl(url);
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
          
          if (widget.deliveries.isNotEmpty) ...[
            // Delivery info card
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: _buildCurrentDeliveryCard(),
            ),
            
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

  Widget _buildCurrentDeliveryCard() {
    if (widget.deliveries.isEmpty) return SizedBox.shrink();
    
    final delivery = widget.deliveries[_currentDeliveryIndex];
    
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
                  '${_currentDeliveryIndex + 1}/${widget.deliveries.length}',
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
                  onPressed: _callCurrentCustomer,
                  icon: Icon(Icons.phone, size: 16),
                  label: Text('Call Customer'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
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
            ElevatedButton.icon(
              onPressed: _startNavigationToCurrent,
              icon: Icon(Icons.navigation),
              label: Text('Navigate'),
              style: ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
),
            ),
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