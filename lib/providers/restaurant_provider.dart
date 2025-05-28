import 'package:flutter/material.dart';

class RestaurantProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _restaurants = [];
  bool _isLoading = false;
  String? _error;
  
  List<Map<String, dynamic>> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> fetchRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Implement API call
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      // Mock data
      _restaurants = [
        {
          'id': '1',
          'name': 'Pizza Palace',
          'cuisine': 'Italian',
          'rating': 4.5,
          'image': 'assets/images/pizza_palace.jpg',
        },
        {
          'id': '2',
          'name': 'Burger Barn',
          'cuisine': 'American',
          'rating': 4.2,
          'image': 'assets/images/burger_barn.jpg',
        },
      ];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Map<String, dynamic>? getRestaurantById(String id) {
    try {
      return _restaurants.firstWhere((restaurant) => restaurant['id'] == id);
    } catch (e) {
      return null;
    }
  }
}