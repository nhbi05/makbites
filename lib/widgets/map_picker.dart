import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPicker extends StatefulWidget {
  @override
  _MapPickerState createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  LatLng? _pickedLocation;
  String? _address;
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Google Places Autocomplete
  List<Map<String, String>> _suggestions = [];
  final String _apiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    await _fetchAutocompleteSuggestions(query);
  }

  Future<void> _fetchAutocompleteSuggestions(String input) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$_apiKey&components=country:UG',
    );
    setState(() => _isSearching = true);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = List<Map<String, String>>.from(
              (data['predictions'] as List).map((item) => {
                'description': item['description'].toString(),
                'place_id': item['place_id'].toString(),
              }),
            );
          });
        } else {
          setState(() => _suggestions = []);
        }
      } else {
        setState(() => _suggestions = []);
      }
    } catch (e) {
      setState(() => _suggestions = []);
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, String> suggestion) async {
    setState(() {
      _isSearching = true;
      _suggestions = [];
      _searchController.text = suggestion['description'] ?? '';
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
            final latLng = LatLng(loc['lat'], loc['lng']);
            setState(() {
              _pickedLocation = latLng;
            });
            _getAddress(latLng);
            _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
          }
        }
      } catch (e) {
      }
    }
    setState(() => _isSearching = false);
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
      });
      _getAddress(_pickedLocation!);
    } catch (e) {
      // Fallback to Kampala coordinates if location fails
      setState(() {
        _pickedLocation = LatLng(0.3476, 32.5825); // Kampala, Uganda
      });
      _getAddress(_pickedLocation!);
    }
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
      _suggestions = []; // Hide suggestions when tapping map
    });
    _getAddress(latLng);
  }

  Future<void> _searchLocation(String query) async {
    setState(() => _isSearching = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _pickedLocation = latLng;
        });
        _getAddress(latLng);
        _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location not found.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Delivery Location'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Map (full screen)
          _pickedLocation == null
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
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
          
          // Search bar overlay (top)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search location',
                  prefixIcon: _isSearching 
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _suggestions = []);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Suggestions dropdown (below search bar)
          if (_suggestions.isNotEmpty)
            Positioned(
              top: 64, // Below search bar
              left: 8,
              right: 8,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 250),
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
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) => Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(Icons.location_on, color: Colors.red),
                        title: Text(
                          suggestion['description'] ?? '',
                          style: TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Address card (bottom area)
          if (_address != null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _address!,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Confirm button (bottom)
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Confirm Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}