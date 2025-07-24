# Delivery Assignment Flow

This document explains how the delivery assignment system works in the MakBites app.

## Flow Overview

1. **Customer places order** → Order goes to `orders` collection
2. **Restaurant owner assigns rider** → Order status updated + Delivery document created in `deliveries` collection
3. **Rider receives assignment** → Delivery appears in rider's app
4. **Rider accepts delivery** → Delivery status updated to 'assigned'
5. **Rider completes delivery** → Delivery status updated to 'completed'

## Database Collections

### Orders Collection
- Contains customer orders
- When rider is assigned, `assignedRiderId` and `assignedRiderName` are added
- Status: 'Pending' → 'Start Preparing' → 'Delivered'

### Deliveries Collection
- Created when restaurant assigns a rider
- Contains delivery-specific information
- Status: 'pending_assignment' → 'assigned' → 'in_progress' → 'completed'

### Delivery Riders Collection
- Contains rider information
- `assigned_vendors`: Array of restaurant IDs the rider works with
- `is_online`: Current online status
- `total_deliveries`: Count of completed deliveries

## Key Features

### Real-time Updates
- Delivery home screen uses StreamBuilder to show real-time available and assigned deliveries
- Riders can see new deliveries as soon as they're created
- Status updates are reflected immediately

### Rider Assignment
- Restaurant owners can assign specific riders to orders
- Riders can only see deliveries assigned to them
- Riders can accept available deliveries

### Delivery Management
- Riders can view delivery details including customer info and items
- Riders can call customers directly from the app
- Riders can mark deliveries as completed

## Testing

### Create Test Delivery
- Use the "Create Test Delivery" button in the delivery home screen
- This creates a sample delivery document for testing
- Remove this button in production

### Test Flow
1. Create a test delivery using the button
2. Accept the delivery (it will be assigned to current rider)
3. View the delivery in the accepted deliveries section
4. Complete the delivery using the complete button

## Files Modified

- `lib/services/delivery_assignment_service.dart` - New service for handling delivery assignments
- `lib/screens/delivery/delivery_home.dart` - Updated to use real Firebase data
- `lib/screens/vendor/set_preparation_time.dart` - Updated to create delivery documents
- `lib/screens/delivery/delivery_map_screen.dart` - Minor updates for new data structure

## Next Steps

1. Add customer location selection when placing orders
2. Implement delivery fee calculation based on distance
3. Add push notifications for new deliveries
4. Add delivery tracking for customers
5. Implement delivery time estimation
6. Add delivery rating system 