import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
      appBar: AppBar(title: Text('Pick Delivery Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _searchLocation(value.trim());
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                _isSearching
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          final value = _searchController.text.trim();
                          if (value.isNotEmpty) {
                            _searchLocation(value);
                          }
                        },
                      ),
              ],
            ),
          ),
          Expanded(
            child: _pickedLocation == null
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
          ),
        ],
      ),
    );
  }
}