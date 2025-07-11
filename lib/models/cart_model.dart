import 'package:flutter/foundation.dart';

class CartModel extends ChangeNotifier {
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  void addItem(Map<String, dynamic> item) {
    // Check if item with same name and restaurant already exists
    final index = _items.indexWhere((e) => e['name'] == item['name'] && e['restaurant'] == item['restaurant']);
    if (index != -1) {
      // If exists, increase quantity
      _items[index]['quantity'] = (_items[index]['quantity'] ?? 1) + (item['quantity'] ?? 1);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeItem(Map<String, dynamic> item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
} 