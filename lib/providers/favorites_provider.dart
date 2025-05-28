import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/place_result.dart';

class FavoritesProvider extends ChangeNotifier {
  final Map<String, PlaceResult> _favoritePlaces = {};
  
  List<PlaceResult> get favoritePlaces => _favoritePlaces.values.toList();
  List<String> get favoriteRestaurantIds => _favoritePlaces.keys.toList();
  
  FavoritesProvider() {
    _loadFavorites();
  }
  
  bool isFavorite(String placeId) {
    return _favoritePlaces.containsKey(placeId);
  }
  
  void toggleFavorite(String placeId, {PlaceResult? place}) {
    if (_favoritePlaces.containsKey(placeId)) {
      _favoritePlaces.remove(placeId);
    } else if (place != null) {
      _favoritePlaces[placeId] = place;
    }
    _saveFavorites();
    notifyListeners();
  }
  
  void addToFavorites(PlaceResult place) {
    if (!_favoritePlaces.containsKey(place.placeId)) {
      _favoritePlaces[place.placeId] = place;
      _saveFavorites();
      notifyListeners();
    }
  }
  
  void removeFromFavorites(String placeId) {
    if (_favoritePlaces.containsKey(placeId)) {
      _favoritePlaces.remove(placeId);
      _saveFavorites();
      notifyListeners();
    }
  }
  
  void clearFavorites() {
    _favoritePlaces.clear();
    _saveFavorites();
    notifyListeners();
  }
  
  PlaceResult? getFavoritePlace(String placeId) {
    return _favoritePlaces[placeId];
  }
  
  // Sort favorites by different criteria
  List<PlaceResult> getFavoritesSortedByRating() {
    final favorites = favoritePlaces;
    favorites.sort((a, b) => b.rating.compareTo(a.rating));
    return favorites;
  }
  
  List<PlaceResult> getFavoritesSortedByName() {
    final favorites = favoritePlaces;
    favorites.sort((a, b) => a.name.compareTo(b.name));
    return favorites;
  }
  
  // Filter favorites by type
  List<PlaceResult> getFavoritesByType(String type) {
    return favoritePlaces.where((place) => 
      place.types.contains(type)
    ).toList();
  }
  
  // Get favorites statistics
  int get totalFavorites => _favoritePlaces.length;
  
  double get averageRating {
    if (_favoritePlaces.isEmpty) return 0.0;
    final total = _favoritePlaces.values.fold<double>(
      0.0, (sum, place) => sum + place.rating
    );
    return total / _favoritePlaces.length;
  }
  
  Map<String, int> get favoritesByType {
    final typeCount = <String, int>{};
    for (final place in _favoritePlaces.values) {
      for (final type in place.types) {
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }
    }
    return typeCount;
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString('favorite_places');
      
      if (favoritesJson != null) {
        final Map<String, dynamic> favoritesMap = json.decode(favoritesJson);
        
        for (final entry in favoritesMap.entries) {
          try {
            final placeData = entry.value as Map<String, dynamic>;
            final place = PlaceResult(
              placeId: placeData['placeId'] ?? entry.key,
              name: placeData['name'] ?? 'Unknown',
              vicinity: placeData['vicinity'] ?? '',
              rating: (placeData['rating'] ?? 0.0).toDouble(),
              userRatingsTotal: placeData['userRatingsTotal'] ?? 0,
              priceLevel: placeData['priceLevel'] ?? 0,
              latitude: (placeData['latitude'] ?? 0.0).toDouble(),
              longitude: (placeData['longitude'] ?? 0.0).toDouble(),
              types: List<String>.from(placeData['types'] ?? []),
              isOpen: placeData['isOpen'] ?? true,
            );
            _favoritePlaces[entry.key] = place;
          } catch (e) {
            print('Error loading favorite place ${entry.key}: $e');
          }
        }
        
        notifyListeners();
        print('✅ Loaded ${_favoritePlaces.length} favorite places');
      }
    } catch (e) {
      print('❌ Error loading favorites: $e');
    }
  }
  
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesMap = <String, Map<String, dynamic>>{};
      
      for (final entry in _favoritePlaces.entries) {
        final place = entry.value;
        favoritesMap[entry.key] = {
          'placeId': place.placeId,
          'name': place.name,
          'vicinity': place.vicinity,
          'rating': place.rating,
          'userRatingsTotal': place.userRatingsTotal,
          'priceLevel': place.priceLevel,
          'latitude': place.latitude,
          'longitude': place.longitude,
          'types': place.types,
          'isOpen': place.isOpen,
        };
      }
      
      final favoritesJson = json.encode(favoritesMap);
      await prefs.setString('favorite_places', favoritesJson);
      print('✅ Saved ${_favoritePlaces.length} favorite places');
    } catch (e) {
      print('❌ Error saving favorites: $e');
    }
  }
  
  // Import/Export functionality
  String exportFavorites() {
    final favoritesMap = <String, Map<String, dynamic>>{};
    
    for (final entry in _favoritePlaces.entries) {
      final place = entry.value;
      favoritesMap[entry.key] = {
        'placeId': place.placeId,
        'name': place.name,
        'vicinity': place.vicinity,
        'rating': place.rating,
        'userRatingsTotal': place.userRatingsTotal,
        'priceLevel': place.priceLevel,
        'latitude': place.latitude,
        'longitude': place.longitude,
        'types': place.types,
        'isOpen': place.isOpen,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    }
    
    return json.encode({
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'totalFavorites': _favoritePlaces.length,
      'favorites': favoritesMap,
    });
  }
  
  Future<bool> importFavorites(String jsonData) async {
    try {
      final data = json.decode(jsonData);
      
      if (data['favorites'] != null) {
        final favoritesMap = data['favorites'] as Map<String, dynamic>;
        
        for (final entry in favoritesMap.entries) {
          final placeData = entry.value as Map<String, dynamic>;
          final place = PlaceResult(
            placeId: placeData['placeId'] ?? entry.key,
            name: placeData['name'] ?? 'Unknown',
            vicinity: placeData['vicinity'] ?? '',
            rating: (placeData['rating'] ?? 0.0).toDouble(),
            userRatingsTotal: placeData['userRatingsTotal'] ?? 0,
            priceLevel: placeData['priceLevel'] ?? 0,
            latitude: (placeData['latitude'] ?? 0.0).toDouble(),
            longitude: (placeData['longitude'] ?? 0.0).toDouble(),
            types: List<String>.from(placeData['types'] ?? []),
            isOpen: placeData['isOpen'] ?? true,
          );
          _favoritePlaces[entry.key] = place;
        }
        
        await _saveFavorites();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error importing favorites: $e');
      return false;
    }
  }
}