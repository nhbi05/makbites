# Makbites Automation Feature - Test Implementation

## Overview
This is a test implementation of the automation feature for the Makbites food app. The feature allows customers to set up weekly meal schedules and automatically place orders 15 minutes before their scheduled meal times.

## Features Implemented

### 1. Weekly Schedule Setup
- **Location**: `lib/screens/customer/weekly_schedule_setup.dart`
- **Functionality**: 
  - Set up daily meal schedules for the entire week
  - Configure breakfast, lunch, and dinner times
  - Select from 5 available restaurants
  - Choose specific meals from each restaurant
  - Enable/disable individual days and meals

### 2. Automation Dashboard
- **Location**: `lib/screens/customer/automation_dashboard.dart`
- **Functionality**:
  - View weekly schedule overview
  - See upcoming automated orders
  - Monitor automation status
  - Quick access to schedule setup

### 3. Automation Service
- **Location**: `lib/services/automation_service.dart`
- **Functionality**:
  - Manage weekly schedules
  - Handle restaurant and meal data
  - Schedule automated orders
  - Process order status updates

### 4. Background Service
- **Location**: `lib/services/background_service.dart`
- **Functionality**:
  - Check for orders that need to be placed
  - Automatically place orders 15 minutes before scheduled time
  - Update order status in Firestore

### 5. Test Screen
- **Location**: `lib/screens/customer/automation_test_screen.dart`
- **Functionality**:
  - Demonstrate automation features with test data
  - Create sample weekly schedules
  - Simulate order placement
  - View test orders and their status

## How to Test

### 1. Access the Automation Feature
1. Navigate to the Customer Home screen
2. Tap the "Schedule Meals" quick action button
3. Or use the floating action button (auto_awesome icon) for quick test access

### 2. Set Up Weekly Schedule
1. Go to the Automation Dashboard
2. Tap "Set Up Schedule" if no schedule exists
3. Configure your weekly meal schedule:
   - Select days of the week
   - Set meal times (breakfast, lunch, dinner)
   - Choose restaurants from the 5 available options
   - Select specific meals from each restaurant
4. Save the schedule

### 3. Test Automation
1. Use the test screen to create sample data
2. View upcoming orders in the dashboard
3. Monitor order status changes
4. Test the 15-minute advance ordering system

## Available Restaurants (Test Data)
1. **Campus Grill** - Burgers, Fries, Drinks
2. **Healthy Bites** - Salads, Wraps, Smoothies
3. **Pizza Corner** - Pizza, Pasta, Italian
4. **Asian Fusion** - Chinese, Thai, Japanese
5. **Coffee & More** - Coffee, Pastries, Sandwiches

## Sample Meals Available
- **Breakfast**: Continental Breakfast, Healthy Bowl, Coffee & Croissant
- **Lunch**: Beef Burger Combo, Caesar Salad, Margherita Pizza, Chicken Fried Rice
- **Dinner**: Grilled Chicken, Pasta Carbonara, Sushi Roll Set

## Technical Implementation

### Data Models
- `WeeklySchedule`: Main schedule container
- `DaySchedule`: Individual day configuration
- `MealSchedule`: Meal-specific settings
- `Restaurant`: Restaurant information
- `Meal`: Meal details and pricing
- `AutomatedOrder`: Order tracking

### Firebase Collections
- `weekly_schedules`: User weekly meal schedules
- `automated_orders`: Automated order tracking

### Key Features
- **15-minute advance ordering**: Orders are automatically placed 15 minutes before scheduled meal time
- **Flexible scheduling**: Enable/disable individual days and meals
- **Real-time updates**: Live order status tracking
- **Background processing**: Automatic order placement in the background

## Navigation Flow
1. Customer Home → Schedule Meals → Automation Dashboard
2. Automation Dashboard → Set Up Schedule → Weekly Schedule Setup
3. Weekly Schedule Setup → Save → Back to Dashboard
4. Dashboard shows upcoming orders and automation status

## Testing Notes
- This is a test implementation with sample data
- Firebase integration is included but requires proper setup
- Background service runs every minute to check for orders
- All times are based on the device's local time
- Orders are simulated and don't actually place real orders to restaurants

## Future Enhancements
- Real restaurant API integration
- Push notifications for order status
- Payment processing integration
- Order modification capabilities
- Dietary preference settings
- Meal variety suggestions

## Files Modified/Created
- `lib/models/automation_models.dart` (NEW)
- `lib/services/automation_service.dart` (NEW)
- `lib/services/background_service.dart` (NEW)
- `lib/screens/customer/weekly_schedule_setup.dart` (NEW)
- `lib/screens/customer/automation_dashboard.dart` (NEW)
- `lib/screens/customer/automation_test_screen.dart` (NEW)
- `lib/screens/customer/customer_home.dart` (MODIFIED)
- `lib/config/routes.dart` (MODIFIED)
- `lib/main.dart` (MODIFIED)

The automation feature is now ready for testing! 🚀 