import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/place_result.dart';

class SearchProvider extends ChangeNotifier {
  List<String> _searchHistory = [];
  List<PlaceResult> _recentSearches = [];
  List<PlaceResult> _currentSearchResults = [];
  bool _isLoading = false;
  String _lastQuery = '';
  
  List<String> get searchHistory => _searchHistory;
  List<PlaceResult> get recentSearches => _recentSearches;
  List<PlaceResult> get currentSearchResults => _currentSearchResults;
  bool get isLoading => _isLoading;
  String get lastQuery => _lastQuery;
  
  SearchProvider() {
    _loadSearchHistory();
  }
  
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setSearchResults(List<PlaceResult> results, String query) {
    _currentSearchResults = results;
    _lastQuery = query;
    _addToSearchHistory(query);
    _isLoading = false;
    notifyListeners();
  }
  
  void addToRecentSearches(PlaceResult place) {
    _recentSearches.removeWhere((p) => p.placeId == place.placeId);
    _recentSearches.insert(0, place);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.take(10).toList();
    }
    _saveSearchHistory();
    notifyListeners();
  }
  
  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;
    
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 20) {
      _searchHistory = _searchHistory.take(20).toList();
    }
    _saveSearchHistory();
  }
  
  void removeFromSearchHistory(String query) {
    _searchHistory.remove(query);
    _saveSearchHistory();
    notifyListeners();
  }
  
  void removeFromRecentSearches(String placeId) {
    _recentSearches.removeWhere((place) => place.placeId == placeId);
    _saveSearchHistory();
    notifyListeners();
  }
  
  void clearSearchHistory() {
    _searchHistory.clear();
    _saveSearchHistory();
    notifyListeners();
  }
  
  void clearRecentSearches() {
    _recentSearches.clear();
    _saveSearchHistory();
    notifyListeners();
  }
  
  void clearCurrentResults() {
    _currentSearchResults.clear();
    _lastQuery = '';
    _isLoading = false;
    notifyListeners();
  }
  
  // Get popular search terms
  List<String> getPopularSearches() {
    return [
      'Pizza',
      'Coffee',
      'Biryani',
      'Burger',
      'Chinese',
      'South Indian',
      'Desserts',
      'Fast Food',
      'Italian',
      'Mexican',
    ];
  }
  
  // Get search suggestions based on query
  List<String> getSearchSuggestions(String query) {
    if (query.trim().isEmpty) return [];
    
    final queryLower = query.toLowerCase();
    final suggestions = <String>[];
    
    // Add from search history
    for (final historyItem in _searchHistory) {
      if (historyItem.toLowerCase().contains(queryLower)) {
        suggestions.add(historyItem);
      }
    }
    
    // Add from popular searches
    for (final popular in getPopularSearches()) {
      if (popular.toLowerCase().contains(queryLower) && 
          !suggestions.contains(popular)) {
        suggestions.add(popular);
      }
    }
    
    return suggestions.take(5).toList();
  }
  
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load search history
      final historyJson = prefs.getString('search_history');
      if (historyJson != null) {
        _searchHistory = List<String>.from(json.decode(historyJson));
      }
      
      // Load recent searches
      final recentJson = prefs.getString('recent_searches');
      if (recentJson != null) {
        final recentData = json.decode(recentJson) as List;
        _recentSearches = recentData.map((data) {
          try {
            return PlaceResult(
              placeId: data['placeId'] ?? '',
              name: data['name'] ?? 'Unknown',
              vicinity: data['vicinity'] ?? '',
              rating: (data['rating'] ?? 0.0).toDouble(),
              userRatingsTotal: data['userRatingsTotal'] ?? 0,
              priceLevel: data['priceLevel'] ?? 0,
              latitude: (data['latitude'] ?? 0.0).toDouble(),
              longitude: (data['longitude'] ?? 0.0).toDouble(),
              types: List<String>.from(data['types'] ?? []),
              isOpen: data['isOpen'] ?? true,
            );
          } catch (e) {
            print('Error loading recent search: $e');
            return null;
          }
        }).where((place) => place != null).cast<PlaceResult>().toList();
      }
      
      notifyListeners();
      print('✅ Loaded search history: ${_searchHistory.length} terms, ${_recentSearches.length} recent searches');
    } catch (e) {
      print('❌ Error loading search history: $e');
    }
  }
  
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save search history
      await prefs.setString('search_history', json.encode(_searchHistory));
      
      // Save recent searches
      final recentData = _recentSearches.map((place) => {
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
      }).toList();
      
      await prefs.setString('recent_searches', json.encode(recentData));
      print('✅ Saved search history');
    } catch (e) {
      print('❌ Error saving search history: $e');
    }
  }
}