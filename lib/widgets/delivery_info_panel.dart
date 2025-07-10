import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/delivery_route.dart';
import '../models/delivery_location.dart';

class DeliveryInfoPanel extends StatefulWidget {
  final DeliveryRoute route;
  final LatLng? currentLocation;

  const DeliveryInfoPanel({
    Key? key,
    required this.route,
    this.currentLocation,
  }) : super(key: key);

  @override
  State<DeliveryInfoPanel> createState() => _DeliveryInfoPanelState();
}

class _DeliveryInfoPanelState extends State<DeliveryInfoPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    DeliveryLocation? nextLocation = widget.route.nextLocation;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? 300 : 200,
      child: Card(
        elevation: 8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with toggle button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Route Info',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route summary
                  _buildRouteSummary(),
                  
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    // Next delivery info
                    if (nextLocation != null) _buildNextDeliveryInfo(nextLocation),
                    
                    const SizedBox(height: 12),
                    
                    // Progress indicator
                    _buildProgressIndicator(),
                    
                    const SizedBox(height: 12),
                    
                    // Delivery list
                    _buildDeliveryList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.straighten, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${widget.route.totalDistance.toStringAsFixed(1)} km',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${widget.route.estimatedDuration.inMinutes} min',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.account_balance_wallet, size: 16, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'UGX ${widget.route.totalEarnings.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextDeliveryInfo(DeliveryLocation nextLocation) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.navigation, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              const Text(
                'Next Delivery',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            nextLocation.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            nextLocation.address,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            nextLocation.items,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'UGX ${nextLocation.earning.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (widget.currentLocation != null)
                Text(
                  '${_calculateDistance(widget.currentLocation!, nextLocation.coordinates).toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    int completed = widget.route.completedCount;
    int total = widget.route.locations.length;
    double progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '$completed / $total',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ],
    );
  }

  Widget _buildDeliveryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deliveries',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...widget.route.locations.asMap().entries.map((entry) {
          int index = entry.key;
          DeliveryLocation location = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: location.isCompleted 
                        ? Colors.green 
                        : location.isPickup 
                            ? Colors.blue 
                            : Colors.orange,
                  ),
                  child: Center(
                    child: Text(
                      location.isCompleted 
                          ? '✓' 
                          : location.isPickup 
                              ? 'P' 
                              : '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: location.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                      Text(
                        'UGX ${location.earning.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  double _calculateDistance(LatLng start, LatLng end) {
    // Simple distance calculation (not accurate for long distances)
    double deltaLat = end.latitude - start.latitude;
    double deltaLng = end.longitude - start.longitude;
    double distance = (deltaLat * deltaLat + deltaLng * deltaLng) * 111.32; // Rough km conversion
    return distance;
  }
}

