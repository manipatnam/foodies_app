import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<String> _favoriteRestaurantIds = [];
  
  List<String> get favoriteRestaurantIds => _favoriteRestaurantIds;
  
  bool isFavorite(String restaurantId) {
    return _favoriteRestaurantIds.contains(restaurantId);
  }
  
  void toggleFavorite(String restaurantId) {
    if (_favoriteRestaurantIds.contains(restaurantId)) {
      _favoriteRestaurantIds.remove(restaurantId);
    } else {
      _favoriteRestaurantIds.add(restaurantId);
    }
    notifyListeners();
  }
  
  void addToFavorites(String restaurantId) {
    if (!_favoriteRestaurantIds.contains(restaurantId)) {
      _favoriteRestaurantIds.add(restaurantId);
      notifyListeners();
    }
  }
  
  void removeFromFavorites(String restaurantId) {
    if (_favoriteRestaurantIds.contains(restaurantId)) {
      _favoriteRestaurantIds.remove(restaurantId);
      notifyListeners();
    }
  }
  
  void clearFavorites() {
    _favoriteRestaurantIds.clear();
    notifyListeners();
  }
}