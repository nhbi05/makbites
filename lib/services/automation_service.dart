import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/automation_models.dart';
import '../models/user_event.dart';

class AutomationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Sample restaurant data
  static final List<Restaurant> sampleRestaurants = [
    Restaurant(
      id: 'rest1',
      name: 'Campus Grill',
      cuisine: 'Burgers • Fries • Drinks',
      rating: 4.5,
      deliveryTime: '15-20 min',
    ),
    Restaurant(
      id: 'rest2',
      name: 'Healthy Bites',
      cuisine: 'Salads • Wraps • Smoothies',
      rating: 4.8,
      deliveryTime: '10-15 min',
    ),
    Restaurant(
      id: 'rest3',
      name: 'Pizza Corner',
      cuisine: 'Pizza • Pasta • Italian',
      rating: 4.3,
      deliveryTime: '20-25 min',
    ),
    Restaurant(
      id: 'rest4',
      name: 'Asian Fusion',
      cuisine: 'Chinese • Thai • Japanese',
      rating: 4.6,
      deliveryTime: '18-22 min',
    ),
    Restaurant(
      id: 'rest5',
      name: 'Coffee & More',
      cuisine: 'Coffee • Pastries • Sandwiches',
      rating: 4.4,
      deliveryTime: '8-12 min',
    ),
  ];

  // Sample meals data
  static final List<Meal> sampleMeals = [
    // Breakfast meals
    Meal(
      id: 'meal1',
      name: 'Continental Breakfast',
      description: 'Eggs, toast, bacon, and coffee',
      price: 15000,
      restaurantId: 'rest1',
      category: 'breakfast',
    ),
    Meal(
      id: 'meal2',
      name: 'Healthy Bowl',
      description: 'Oatmeal with fruits and nuts',
      price: 12000,
      restaurantId: 'rest2',
      category: 'breakfast',
    ),
    Meal(
      id: 'meal3',
      name: 'Coffee & Croissant',
      description: 'Fresh croissant with coffee',
      price: 8000,
      restaurantId: 'rest5',
      category: 'breakfast',
    ),
    
    // Lunch meals
    Meal(
      id: 'meal4',
      name: 'Beef Burger Combo',
      description: 'Beef burger with fries and drink',
      price: 25000,
      restaurantId: 'rest1',
      category: 'lunch',
    ),
    Meal(
      id: 'meal5',
      name: 'Caesar Salad',
      description: 'Fresh salad with chicken',
      price: 18000,
      restaurantId: 'rest2',
      category: 'lunch',
    ),
    Meal(
      id: 'meal6',
      name: 'Margherita Pizza',
      description: 'Classic pizza with tomato and mozzarella',
      price: 22000,
      restaurantId: 'rest3',
      category: 'lunch',
    ),
    Meal(
      id: 'meal7',
      name: 'Chicken Fried Rice',
      description: 'Stir-fried rice with chicken and vegetables',
      price: 20000,
      restaurantId: 'rest4',
      category: 'lunch',
    ),
    
    // Dinner meals
    Meal(
      id: 'meal8',
      name: 'Grilled Chicken',
      description: 'Grilled chicken with sides',
      price: 28000,
      restaurantId: 'rest1',
      category: 'dinner',
    ),
    Meal(
      id: 'meal9',
      name: 'Pasta Carbonara',
      description: 'Creamy pasta with bacon',
      price: 24000,
      restaurantId: 'rest3',
      category: 'dinner',
    ),
    Meal(
      id: 'meal10',
      name: 'Sushi Roll Set',
      description: 'Assorted sushi rolls',
      price: 30000,
      restaurantId: 'rest4',
      category: 'dinner',
    ),
  ];

  // Save weekly schedule
  Future<void> saveWeeklySchedule(WeeklySchedule schedule) async {
    await _firestore
        .collection('weekly_schedules')
        .doc(schedule.id)
        .set(schedule.toMap());
  }

  // Get user's weekly schedule
  Future<WeeklySchedule?> getWeeklySchedule(String userId) async {
    try {
      final doc = await _firestore
          .collection('weekly_schedules')
          .where('userId', isEqualTo: userId)
          .get();
      
      if (doc.docs.isNotEmpty) {
        // Filter for active schedules in memory instead of in query
        final activeSchedules = doc.docs
            .map((doc) => WeeklySchedule.fromMap(doc.data()))
            .where((schedule) => schedule.isActive)
            .toList();
        
        if (activeSchedules.isNotEmpty) {
          return activeSchedules.first;
        }
      }
      return null;
    } catch (e) {
      print('Error getting weekly schedule: $e');
      return null;
    }
  }

  // Get restaurants
  List<Restaurant> getRestaurants() {
    return sampleRestaurants;
  }

  // Get meals by category and restaurant
  List<Meal> getMealsByCategory(String category, {String? restaurantId}) {
    return sampleMeals.where((meal) {
      bool matchesCategory = meal.category == category;
      bool matchesRestaurant = restaurantId == null || meal.restaurantId == restaurantId;
      return matchesCategory && matchesRestaurant;
    }).toList();
  }

  // Create automated order
  Future<void> createAutomatedOrder(AutomatedOrder order) async {
    await _firestore
        .collection('automated_orders')
        .doc(order.id)
        .set(order.toMap());
  }

  // Get user's automated orders
  Stream<List<AutomatedOrder>> getAutomatedOrders(String userId) {
    return _firestore
        .collection('automated_orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => AutomatedOrder.fromMap(doc.data()))
              .toList();
          
          // Sort in memory instead of using orderBy
          orders.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
          return orders;
        });
  }

  // Schedule automated orders based on weekly schedule
  Future<void> scheduleOrdersFromWeeklySchedule(WeeklySchedule schedule) async {
    final now = DateTime.now();
    final today = now.weekday; // 1 = Monday, 7 = Sunday
    
    for (int i = 0; i < schedule.days.length; i++) {
      final daySchedule = schedule.days[i];
      if (!daySchedule.isEnabled) continue;
      
      for (final mealSchedule in daySchedule.meals) {
        if (!mealSchedule.isEnabled || mealSchedule.restaurantId == null || mealSchedule.mealId == null) {
          continue;
        }
        
        // Calculate the next occurrence of this day and time
        final nextOccurrence = _getNextOccurrence(i + 1, mealSchedule.time);
        
        // Schedule order 30 minutes before
        final orderTime = nextOccurrence.subtract(Duration(minutes: 30));
        
        if (orderTime.isAfter(now)) {
          final order = AutomatedOrder(
            id: '${schedule.userId}_${nextOccurrence.millisecondsSinceEpoch}',
            userId: schedule.userId,
            restaurantId: mealSchedule.restaurantId!,
            mealId: mealSchedule.mealId!,
            scheduledTime: nextOccurrence,
            orderTime: orderTime,
            status: 'pending',
            totalAmount: _getMealPrice(mealSchedule.mealId!),
          );
          
          await createAutomatedOrder(order);
        }
      }
    }
  }

  DateTime _getNextOccurrence(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    final today = now.weekday;
    
    int daysUntilNext = weekday - today;
    if (daysUntilNext <= 0) {
      daysUntilNext += 7; // Next week
    }
    
    final nextDate = now.add(Duration(days: daysUntilNext));
    return DateTime(
      nextDate.year,
      nextDate.month,
      nextDate.day,
      time.hour,
      time.minute,
    );
  }

  double _getMealPrice(String mealId) {
    final meal = sampleMeals.firstWhere((meal) => meal.id == mealId);
    return meal.price;
  }

  // Cancel automated order
  Future<void> cancelAutomatedOrder(String orderId) async {
    await _firestore
        .collection('automated_orders')
        .doc(orderId)
        .update({'status': 'cancelled'});
  }

  // Pause/Resume automation
  Future<void> toggleAutomation(String scheduleId, bool isActive) async {
    await _firestore
        .collection('weekly_schedules')
        .doc(scheduleId)
        .update({'isActive': isActive});
  }

  /// Schedules smart orders for the user based on in-app events and meal preferences
  Future<void> scheduleSmartOrdersForUser(String userId) async {
    // 1. Fetch user events
    final eventsSnapshot = await _firestore
        .collection('user_events')
        .where('userId', isEqualTo: userId)
        .get();
    final List<UserEvent> events = eventsSnapshot.docs
        .map((doc) => UserEvent.fromMap(doc.data()))
        .toList();

    // 2. Fetch meal preferences
    final prefsDoc = await _firestore
        .collection('meal_preferences')
        .doc(userId)
        .get();
    if (!prefsDoc.exists) return;
    final prefs = prefsDoc.data()!;
    final mealWindows = [
      {
        'label': 'breakfast',
        'start': _parseTime(prefs['breakfastStart']),
        'end': _parseTime(prefs['breakfastEnd']),
      },
      {
        'label': 'lunch',
        'start': _parseTime(prefs['lunchStart']),
        'end': _parseTime(prefs['lunchEnd']),
      },
      {
        'label': 'dinner',
        'start': _parseTime(prefs['dinnerStart']),
        'end': _parseTime(prefs['dinnerEnd']),
      },
    ];
    final deliveryBuffer = prefs['deliveryBuffer'] ?? 15;

    // 3. For each day in the next 7 days, find optimal meal times
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.add(Duration(days: i));
      for (final window in mealWindows) {
        final mealType = window['label'];
        final TimeOfDay startTime = window['start'] as TimeOfDay;
        final TimeOfDay endTime = window['end'] as TimeOfDay;
        final windowStart = DateTime(day.year, day.month, day.day, startTime.hour, startTime.minute);
        final windowEnd = DateTime(day.year, day.month, day.day, endTime.hour, endTime.minute);

        // Find all events that overlap with this meal window
        final busySlots = events.where((e) =>
          (e.startTime.isBefore(windowEnd) && e.endTime.isAfter(windowStart))
        ).toList();

        // Find free gaps in the window
        List<DateTimeRange> freeGaps = _findFreeGaps(windowStart, windowEnd, busySlots);
        if (freeGaps.isEmpty) continue;

        // Pick the first free gap of at least 30 minutes
        final gap = freeGaps.firstWhere(
          (g) => g.duration.inMinutes >= 30,
          orElse: () => DateTimeRange(start: windowStart, end: windowStart),
        );
        if (gap.duration.inMinutes < 30) continue;

        // Schedule the meal at the start of the gap
        final mealTime = gap.start;
        final orderTime = mealTime.subtract(Duration(minutes: 30));
        if (orderTime.isBefore(now)) continue; // Don't schedule in the past

        // Create an automated order (simulate with a placeholder meal/restaurant)
        final order = AutomatedOrder(
          id: '${userId}_${mealTime.millisecondsSinceEpoch}_$mealType',
          userId: userId,
          restaurantId: 'rest1', // TODO: Use user preference or random
          mealId: 'meal1', // TODO: Use user preference or random
          scheduledTime: mealTime,
          orderTime: orderTime,
          status: 'pending',
          totalAmount: 15000, // TODO: Use actual meal price
        );
        await _firestore
            .collection('automated_orders')
            .doc(order.id)
            .set(order.toMap());
      }
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  List<DateTimeRange> _findFreeGaps(DateTime windowStart, DateTime windowEnd, List<UserEvent> events) {
    // Sort events by start time
    events.sort((a, b) => a.startTime.compareTo(b.startTime));
    List<DateTimeRange> gaps = [];
    DateTime current = windowStart;
    for (final event in events) {
      if (event.startTime.isAfter(current)) {
        gaps.add(DateTimeRange(start: current, end: event.startTime));
      }
      if (event.endTime.isAfter(current)) {
        current = event.endTime;
      }
    }
    if (current.isBefore(windowEnd)) {
      gaps.add(DateTimeRange(start: current, end: windowEnd));
    }
    return gaps;
  }

  /// Schedules simple smart orders for the user based on their events and preferences
  Future<void> scheduleSimpleSmartOrderForUser({
    required String userId,
    required String preferredMeal, // 'Breakfast', 'Lunch', 'Supper'
    required String preferredRestaurant, // Restaurant name
    required String deliveryLocation, // Not used in order model, but could be stored elsewhere
  }) async {
    // 1. Fetch user events for the next 7 days
    final eventsSnapshot = await _firestore
        .collection('user_events')
        .where('userId', isEqualTo: userId)
        .get();
    final List<UserEvent> events = eventsSnapshot.docs
        .map((doc) => UserEvent.fromMap(doc.data()))
        .toList();

    // 2. Define meal windows
    final mealWindows = {
      'Breakfast': {'start': TimeOfDay(hour: 7, minute: 0), 'end': TimeOfDay(hour: 11, minute: 0), 'category': 'breakfast'},
      'Lunch': {'start': TimeOfDay(hour: 12, minute: 0), 'end': TimeOfDay(hour: 16, minute: 0), 'category': 'lunch'},
      'Supper': {'start': TimeOfDay(hour: 17, minute: 0), 'end': TimeOfDay(hour: 22, minute: 0), 'category': 'dinner'},
    };
    final window = mealWindows[preferredMeal]!;
    final category = window['category'] as String;

    // 3. Find the restaurant and meal IDs
    final restaurant = sampleRestaurants.firstWhere((r) => r.name == preferredRestaurant);
    final meal = sampleMeals.firstWhere((m) => m.category == category && m.restaurantId == restaurant.id);

    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = now.add(Duration(days: i));
      final TimeOfDay startTime = window['start'] as TimeOfDay;
      final TimeOfDay endTime = window['end'] as TimeOfDay;
      final windowStart = DateTime(day.year, day.month, day.day, startTime.hour, startTime.minute);
      final windowEnd = DateTime(day.year, day.month, day.day, endTime.hour, endTime.minute);

      // Get events for this day
      final dayEvents = events.where((e) =>
        e.startTime.day == day.day &&
        e.startTime.month == day.month &&
        e.startTime.year == day.year
      ).toList();

      // Find free slots in the meal window
      List<DateTimeRange> freeGaps = _findFreeGaps(windowStart, windowEnd, dayEvents);
      if (freeGaps.isEmpty) continue;

      // Pick the first free gap of at least 30 minutes
      final gap = freeGaps.firstWhere(
        (g) => g.duration.inMinutes >= 30,
        orElse: () => DateTimeRange(start: windowStart, end: windowStart),
      );
      if (gap.duration.inMinutes < 30) continue;

      // Schedule the order 15 minutes before the start of the gap
      final scheduledTime = gap.start;
      final orderTime = scheduledTime.subtract(Duration(minutes: 15));
      if (orderTime.isBefore(now)) continue; // Don't schedule in the past

      final order = AutomatedOrder(
        id: '${userId}_${scheduledTime.millisecondsSinceEpoch}_$category',
        userId: userId,
        restaurantId: restaurant.id,
        mealId: meal.id,
        scheduledTime: scheduledTime,
        orderTime: orderTime,
        status: 'pending',
        totalAmount: meal.price,
      );
      await createAutomatedOrder(order);
    }
  }
} 