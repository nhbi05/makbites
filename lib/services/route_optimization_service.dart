import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import '../models/delivery_location.dart';
import '../models/delivery_route.dart';

class RouteOptimizationService {
  static const String _googleMapsApiKey = 'AIzaSyAS10x2khf_QHLIGeyWIADDpoGLgaUkln0';
  static const String _directionsBaseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  static const String _distanceMatrixBaseUrl = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  
  // Optimize route using multiple algorithms
  Future<DeliveryRoute> optimizeRoute({
    required LatLng startLocation,
    required List<DeliveryLocation> deliveryLocations,
    String algorithm = 'google_optimized', // 'google_optimized', 'nearest_neighbor', 'genetic'
  }) async {
    if (deliveryLocations.isEmpty) {
      throw Exception('No delivery locations provided');
    }
    
    List<DeliveryLocation> optimizedLocations;
    List<LatLng> routePoints;
    double totalDistance = 0.0;
    Duration estimatedDuration = Duration.zero;
    
    switch (algorithm) {
      case 'google_optimized':
        final result = await _optimizeWithGoogleDirections(startLocation, deliveryLocations);
        optimizedLocations = result['locations'];
        routePoints = result['routePoints'];
        totalDistance = result['totalDistance'];
        estimatedDuration = result['estimatedDuration'];
        break;
        
      case 'nearest_neighbor':
        optimizedLocations = await _nearestNeighborOptimization(startLocation, deliveryLocations);
        final routeResult = await _getRouteForLocations(startLocation, optimizedLocations);
        routePoints = routeResult['routePoints'];
        totalDistance = routeResult['totalDistance'];
        estimatedDuration = routeResult['estimatedDuration'];
        break;
        
      case 'genetic':
        optimizedLocations = await _geneticAlgorithmOptimization(startLocation, deliveryLocations);
        final routeResult = await _getRouteForLocations(startLocation, optimizedLocations);
        routePoints = routeResult['routePoints'];
        totalDistance = routeResult['totalDistance'];
        estimatedDuration = routeResult['estimatedDuration'];
        break;
        
      default:
        throw Exception('Unknown optimization algorithm: $algorithm');
    }
    
    return DeliveryRoute(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      locations: optimizedLocations,
      routePoints: routePoints,
      totalDistance: totalDistance,
      estimatedDuration: estimatedDuration,
      createdAt: DateTime.now(),
      isOptimized: true,
    );
  }
  
  // Optimize using Google Directions API with waypoint optimization
  Future<Map<String, dynamic>> _optimizeWithGoogleDirections(
    LatLng startLocation,
    List<DeliveryLocation> locations,
  ) async {
    if (locations.length > 23) {
      // Google Directions API supports max 23 waypoints
      // Fall back to nearest neighbor for larger routes
      return await _fallbackOptimization(startLocation, locations);
    }
    
    // Separate pickup and dropoff locations
    List<DeliveryLocation> pickups = locations.where((loc) => loc.isPickup).toList();
    List<DeliveryLocation> dropoffs = locations.where((loc) => !loc.isPickup).toList();
    
    // Optimize pickups first, then dropoffs
    List<DeliveryLocation> optimizedOrder = [];
    
    if (pickups.isNotEmpty) {
      final pickupResult = await _optimizeLocationGroup(startLocation, pickups);
      optimizedOrder.addAll(pickupResult);
    }
    
    if (dropoffs.isNotEmpty) {
      LatLng lastLocation = optimizedOrder.isNotEmpty 
          ? optimizedOrder.last.coordinates 
          : startLocation;
      final dropoffResult = await _optimizeLocationGroup(lastLocation, dropoffs);
      optimizedOrder.addAll(dropoffResult);
    }
    
    // Get complete route
    return await _getRouteForLocations(startLocation, optimizedOrder);
  }
  
  // Optimize a group of locations using Google Directions API
  Future<List<DeliveryLocation>> _optimizeLocationGroup(
    LatLng startLocation,
    List<DeliveryLocation> locations,
  ) async {
    if (locations.isEmpty) return [];
    if (locations.length == 1) return locations;
    
    // Build waypoints string
    String waypoints = locations
        .map((loc) => '${loc.coordinates.latitude},${loc.coordinates.longitude}')
        .join('|');
    
    final String url = '$_directionsBaseUrl?'
        'origin=${startLocation.latitude},${startLocation.longitude}'
        '&destination=${locations.last.coordinates.latitude},${locations.last.coordinates.longitude}'
        '&waypoints=optimize:true|$waypoints'
        '&key=$_googleMapsApiKey'
        '&mode=driving';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final waypointOrder = route['waypoint_order'] as List<dynamic>;
          
          // Reorder locations based on Google's optimization
          List<DeliveryLocation> optimizedLocations = [];
          for (int index in waypointOrder) {
            if (index < locations.length) {
              optimizedLocations.add(locations[index]);
            }
          }
          
          return optimizedLocations;
        }
      }
    } catch (e) {
      print('Error optimizing with Google Directions: $e');
    }
    
    // Fallback to original order
    return locations;
  }
  
  // Nearest Neighbor optimization algorithm
  Future<List<DeliveryLocation>> _nearestNeighborOptimization(
    LatLng startLocation,
    List<DeliveryLocation> locations,
  ) async {
    List<DeliveryLocation> unvisited = List.from(locations);
    List<DeliveryLocation> optimizedRoute = [];
    LatLng currentLocation = startLocation;
    
    // Prioritize pickups first
    List<DeliveryLocation> pickups = unvisited.where((loc) => loc.isPickup).toList();
    List<DeliveryLocation> dropoffs = unvisited.where((loc) => !loc.isPickup).toList();
    
    // Process pickups first
    while (pickups.isNotEmpty) {
      DeliveryLocation nearest = _findNearestLocation(currentLocation, pickups);
      optimizedRoute.add(nearest);
      currentLocation = nearest.coordinates;
      pickups.remove(nearest);
      unvisited.remove(nearest);
    }
    
    // Then process dropoffs
    while (dropoffs.isNotEmpty) {
      DeliveryLocation nearest = _findNearestLocation(currentLocation, dropoffs);
      optimizedRoute.add(nearest);
      currentLocation = nearest.coordinates;
      dropoffs.remove(nearest);
      unvisited.remove(nearest);
    }
    
    return optimizedRoute;
  }
  
  // Genetic Algorithm optimization (simplified version)
  Future<List<DeliveryLocation>> _geneticAlgorithmOptimization(
    LatLng startLocation,
    List<DeliveryLocation> locations,
  ) async {
    if (locations.length <= 3) {
      return await _nearestNeighborOptimization(startLocation, locations);
    }
    
    const int populationSize = 50;
    const int generations = 100;
    const double mutationRate = 0.1;
    const double crossoverRate = 0.8;
    
    // Separate pickups and dropoffs
    List<DeliveryLocation> pickups = locations.where((loc) => loc.isPickup).toList();
    List<DeliveryLocation> dropoffs = locations.where((loc) => !loc.isPickup).toList();
    
    // Optimize pickups first
    List<DeliveryLocation> optimizedPickups = pickups.isNotEmpty
        ? await _geneticOptimizeGroup(startLocation, pickups, populationSize, generations, mutationRate, crossoverRate)
        : [];
    
    // Then optimize dropoffs
    LatLng lastLocation = optimizedPickups.isNotEmpty 
        ? optimizedPickups.last.coordinates 
        : startLocation;
    List<DeliveryLocation> optimizedDropoffs = dropoffs.isNotEmpty
        ? await _geneticOptimizeGroup(lastLocation, dropoffs, populationSize, generations, mutationRate, crossoverRate)
        : [];
    
    return [...optimizedPickups, ...optimizedDropoffs];
  }
  
  // Genetic algorithm for a group of locations
  Future<List<DeliveryLocation>> _geneticOptimizeGroup(
    LatLng startLocation,
    List<DeliveryLocation> locations,
    int populationSize,
    int generations,
    double mutationRate,
    double crossoverRate,
  ) async {
    if (locations.length <= 1) return locations;
    
    // Create initial population
    List<List<DeliveryLocation>> population = [];
    for (int i = 0; i < populationSize; i++) {
      List<DeliveryLocation> individual = List.from(locations);
      individual.shuffle();
      population.add(individual);
    }
    
    // Evolution loop
    for (int generation = 0; generation < generations; generation++) {
      // Calculate fitness for each individual
      List<double> fitness = [];
      for (List<DeliveryLocation> individual in population) {
        double totalDistance = _calculateRouteDistance(startLocation, individual);
        fitness.add(1.0 / (1.0 + totalDistance)); // Higher fitness for shorter routes
      }
      
      // Create new generation
      List<List<DeliveryLocation>> newPopulation = [];
      
      for (int i = 0; i < populationSize; i++) {
        // Selection (tournament selection)
        List<DeliveryLocation> parent1 = _tournamentSelection(population, fitness);
        List<DeliveryLocation> parent2 = _tournamentSelection(population, fitness);
        
        // Crossover
        List<DeliveryLocation> offspring = math.Random().nextDouble() < crossoverRate
            ? _orderCrossover(parent1, parent2)
            : List.from(parent1);
        
        // Mutation
        if (math.Random().nextDouble() < mutationRate) {
          _mutate(offspring);
        }
        
        newPopulation.add(offspring);
      }
      
      population = newPopulation;
    }
    
    // Return best individual
    double bestFitness = 0.0;
    List<DeliveryLocation> bestIndividual = population.first;
    
    for (List<DeliveryLocation> individual in population) {
      double totalDistance = _calculateRouteDistance(startLocation, individual);
      double fitness = 1.0 / (1.0 + totalDistance);
      
      if (fitness > bestFitness) {
        bestFitness = fitness;
        bestIndividual = individual;
      }
    }
    
    return bestIndividual;
  }
  
  // Tournament selection for genetic algorithm
  List<DeliveryLocation> _tournamentSelection(
    List<List<DeliveryLocation>> population,
    List<double> fitness,
  ) {
    const int tournamentSize = 3;
    int bestIndex = math.Random().nextInt(population.length);
    double bestFitness = fitness[bestIndex];
    
    for (int i = 1; i < tournamentSize; i++) {
      int index = math.Random().nextInt(population.length);
      if (fitness[index] > bestFitness) {
        bestIndex = index;
        bestFitness = fitness[index];
      }
    }
    
    return List.from(population[bestIndex]);
  }
  
  // Order crossover for genetic algorithm
  List<DeliveryLocation> _orderCrossover(
    List<DeliveryLocation> parent1,
    List<DeliveryLocation> parent2,
  ) {
    int length = parent1.length;
    if (length <= 2) return List.from(parent1);
    
    int start = math.Random().nextInt(length - 1);
    int end = start + 1 + math.Random().nextInt(length - start - 1);
    
    List<DeliveryLocation> offspring = List.filled(length, parent1.first);
    
    // Copy segment from parent1
    for (int i = start; i <= end; i++) {
      offspring[i] = parent1[i];
    }
    
    // Fill remaining positions from parent2
    int currentPos = (end + 1) % length;
    for (DeliveryLocation location in parent2) {
      if (!offspring.sublist(start, end + 1).contains(location)) {
        offspring[currentPos] = location;
        currentPos = (currentPos + 1) % length;
      }
    }
    
    return offspring;
  }
  
  // Mutation for genetic algorithm
  void _mutate(List<DeliveryLocation> individual) {
    if (individual.length < 2) return;
    
    int index1 = math.Random().nextInt(individual.length);
    int index2 = math.Random().nextInt(individual.length);
    
    // Swap two random locations
    DeliveryLocation temp = individual[index1];
    individual[index1] = individual[index2];
    individual[index2] = temp;
  }
  
  // Find nearest location to current position
  DeliveryLocation _findNearestLocation(LatLng currentLocation, List<DeliveryLocation> locations) {
    DeliveryLocation nearest = locations.first;
    double minDistance = _calculateDistance(currentLocation, nearest.coordinates);
    
    for (DeliveryLocation location in locations) {
      double distance = _calculateDistance(currentLocation, location.coordinates);
      if (distance < minDistance) {
        minDistance = distance;
        nearest = location;
      }
    }
    
    return nearest;
  }
  
  // Calculate total route distance
  double _calculateRouteDistance(LatLng startLocation, List<DeliveryLocation> locations) {
    if (locations.isEmpty) return 0.0;
    
    double totalDistance = 0.0;
    LatLng currentLocation = startLocation;
    
    for (DeliveryLocation location in locations) {
      totalDistance += _calculateDistance(currentLocation, location.coordinates);
      currentLocation = location.coordinates;
    }
    
    return totalDistance;
  }
  
  // Get route details for optimized locations
  Future<Map<String, dynamic>> _getRouteForLocations(
    LatLng startLocation,
    List<DeliveryLocation> locations,
  ) async {
    if (locations.isEmpty) {
      return {
        'routePoints': <LatLng>[],
        'totalDistance': 0.0,
        'estimatedDuration': Duration.zero,
      };
    }
    
    List<LatLng> allPoints = [startLocation];
    allPoints.addAll(locations.map((loc) => loc.coordinates));
    
    // Get route from Google Directions API
    String waypoints = '';
    if (locations.length > 1) {
      waypoints = '&waypoints=' + 
          locations.take(locations.length - 1)
              .map((loc) => '${loc.coordinates.latitude},${loc.coordinates.longitude}')
              .join('|');
    }
    
    final String url = '$_directionsBaseUrl?'
        'origin=${startLocation.latitude},${startLocation.longitude}'
        '&destination=${locations.last.coordinates.latitude},${locations.last.coordinates.longitude}'
        '$waypoints'
        '&key=$_googleMapsApiKey'
        '&mode=driving';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Decode polyline
          String polylinePoints = route['overview_polyline']['points'];
          List<List<num>> decodedPoints = decodePolyline(polylinePoints);
          List<LatLng> routePoints = decodedPoints
              .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
              .toList();
          
          // Calculate total distance and duration
          double totalDistance = 0.0;
          int totalDurationSeconds = 0;
          
          for (var leg in route['legs']) {
            totalDistance += leg['distance']['value'] / 1000.0; // Convert to km
            totalDurationSeconds += (leg['duration']['value'] as num).toInt();
          }
          
          return {
            'routePoints': routePoints,
            'totalDistance': totalDistance,
            'estimatedDuration': Duration(seconds: totalDurationSeconds),
          };
        }
      }
    } catch (e) {
      print('Error getting route details: $e');
    }
    
    // Fallback: return straight lines
    return {
      'routePoints': allPoints,
      'totalDistance': _calculateRouteDistance(startLocation, locations),
      'estimatedDuration': Duration(minutes: (locations.length * 15)), // Estimate 15 min per stop
    };
  }
  
  // Fallback optimization for large routes
  Future<Map<String, dynamic>> _fallbackOptimization(
    LatLng startLocation,
    List<DeliveryLocation> locations,
  ) async {
    // Use nearest neighbor for large routes
    List<DeliveryLocation> optimizedLocations = await _nearestNeighborOptimization(
      startLocation,
      locations,
    );
    
    return await _getRouteForLocations(startLocation, optimizedLocations);
  }
  
  // Calculate distance between two points (Haversine formula)
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (math.pi / 180);
    
    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  // Calculate arrival times for each location
  List<DateTime> calculateArrivalTimes(DeliveryRoute route, DateTime startTime) {
    List<DateTime> arrivalTimes = [];
    DateTime currentTime = startTime;
    
    // Assume average speed of 25 km/h and 5 minutes per stop
    const double averageSpeedKmh = 25.0;
    const int stopTimeMinutes = 5;
    
    LatLng currentLocation = route.routePoints.isNotEmpty 
        ? route.routePoints.first 
        : route.locations.first.coordinates;
    
    for (DeliveryLocation location in route.locations) {
      double distance = _calculateDistance(currentLocation, location.coordinates);
      double travelTimeHours = distance / averageSpeedKmh;
      
      currentTime = currentTime.add(Duration(
        milliseconds: (travelTimeHours * 3600 * 1000).round(),
      ));
      
      arrivalTimes.add(currentTime);
      
      // Add stop time
      currentTime = currentTime.add(Duration(minutes: stopTimeMinutes));
      currentLocation = location.coordinates;
    }
    
    return arrivalTimes;
  }
  
  // Get route alternatives
  Future<List<DeliveryRoute>> getRouteAlternatives({
    required LatLng startLocation,
    required List<DeliveryLocation> deliveryLocations,
  }) async {
    List<DeliveryRoute> alternatives = [];
    
    // Try different optimization algorithms
    List<String> algorithms = ['google_optimized', 'nearest_neighbor', 'genetic'];
    
    for (String algorithm in algorithms) {
      try {
        DeliveryRoute route = await optimizeRoute(
          startLocation: startLocation,
          deliveryLocations: deliveryLocations,
          algorithm: algorithm,
        );
        alternatives.add(route);
      } catch (e) {
        print('Error with algorithm $algorithm: $e');
      }
    }
    
    // Sort by total distance
    alternatives.sort((a, b) => a.totalDistance.compareTo(b.totalDistance));
    
    return alternatives;
  }
}

