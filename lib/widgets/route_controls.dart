import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/delivery_route.dart';
import '../models/delivery_location.dart';

class RouteControls extends StatelessWidget {
  final DeliveryRoute? currentRoute;
  final Function(String) onLocationCompleted; // Callback for marking location as completed
  final VoidCallback? onOptimizeRoute; // Callback for optimizing route
  final Function(DeliveryLocation)? onAdvanceToNextDelivery; // New callback to advance to next delivery

  const RouteControls({
    Key? key,
    this.currentRoute,
    required this.onLocationCompleted,
    this.onOptimizeRoute,
    this.onAdvanceToNextDelivery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DeliveryLocation? nextLocation = currentRoute?.nextLocation;

    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (nextLocation != null) ...[
              _buildNextDeliveryCard(context, nextLocation),
              const SizedBox(height: 16),
            ],
            _buildActionButtons(context, nextLocation),
          ],
        ),
      ),
    );
  }

  Widget _buildNextDeliveryCard(BuildContext context, DeliveryLocation location) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                location.isPickup ? Icons.store : Icons.home,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location.isPickup ? 'Pickup from:' : 'Deliver to:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'UGX ${location.earning.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            location.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location.address,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    location.items,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          if (location.customerName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  location.customerName,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                if (location.customerPhone.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () => _callCustomer(location.customerPhone),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
          if (location.estimatedTime != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Est. Arrival: ${location.estimatedTime!.hour.toString().padLeft(2, '0')}:${location.estimatedTime!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DeliveryLocation? nextLocation) {
    return Column(
      children: [
        // Primary action buttons
        Row(
          children: [
            if (nextLocation != null) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMaps(nextLocation),
                  icon: const Icon(Icons.navigation, color: Colors.white),
                  label: const Text('Navigate', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _markAsCompleted(context, nextLocation),
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Complete', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ] else ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'All deliveries completed!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Secondary action buttons
        Row(
          children: [
            if (onOptimizeRoute != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOptimizeRoute,
                  icon: const Icon(Icons.alt_route),
                  label: const Text('Optimize Route'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            if (onOptimizeRoute != null) const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRouteInfo(context),
                icon: const Icon(Icons.info_outline),
                label: const Text('Route Info'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openGoogleMaps(DeliveryLocation location) async {
    final String googleMapsUrl = 
        'https://www.google.com/maps/dir/?api=1&destination=${location.coordinates.latitude},${location.coordinates.longitude}&travelmode=driving';
    
    try {
      final Uri url = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint('Could not launch Google Maps');
      }
    } catch (e) {
      debugPrint('Error launching Google Maps: $e');
    }
  }

  void _callCustomer(String phoneNumber) async {
    final String telUrl = 'tel:$phoneNumber';
    
    try {
      final Uri url = Uri.parse(telUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        debugPrint('Could not make phone call');
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
    }
  }

  void _markAsCompleted(BuildContext context, DeliveryLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Delivery'),
        content: Text('Mark delivery to ${location.name} as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLocationCompleted(location.id);
              if (onAdvanceToNextDelivery != null) {
                onAdvanceToNextDelivery!(location);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Delivery to ${location.name} completed!'),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () {
                      // Implement undo functionality if needed
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRouteInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (currentRoute != null) ...[
              _buildInfoRow('Total Distance', '${currentRoute!.totalDistance.toStringAsFixed(1)} km'),
              _buildInfoRow('Estimated Time', '${currentRoute!.estimatedDuration.inMinutes} minutes'),
              _buildInfoRow('Total Earnings', 'UGX ${currentRoute!.totalEarnings.toStringAsFixed(0)}'),
              _buildInfoRow('Deliveries', '${currentRoute!.locations.length}'),
              _buildInfoRow('Completed', '${currentRoute!.completedCount}'),
              _buildInfoRow('Remaining', '${currentRoute!.locations.length - currentRoute!.completedCount}'),
              _buildInfoRow('Route Optimized', currentRoute!.isOptimized ? 'Yes' : 'No'),
            ] else ...[
              const Text('No route information available'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}


