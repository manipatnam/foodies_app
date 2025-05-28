import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../models/place_result.dart';
import '../widgets/place_card.dart';
import '../widgets/place_details_sheet.dart';
import '../services/places_service.dart';
import '../providers/favorites_provider.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PlaceResult> _searchResults = [];
  List<PlaceResult> _recentSearches = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  LocationData? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadRecentSearches();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Location location = Location();
      final locationData = await location.getLocation();
      setState(() {
        _currentLocation = locationData;
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _loadRecentSearches() async {
    // In a real app, you'd load this from local storage
    // For now, we'll use mock data
    setState(() {
      _recentSearches = [
        PlaceResult(
          placeId: 'recent_1',
          name: 'McDonald\'s',
          vicinity: 'Recent search',
          rating: 4.1,
          userRatingsTotal: 1250,
          priceLevel: 1,
          latitude: 17.4518794,
          longitude: 78.3557664,
          types: ['restaurant'],
          isOpen: true,
        ),
      ];
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final places = await PlacesService.searchPlaces(
        query: query,
        lat: _currentLocation?.latitude ?? 17.4518794,
        lng: _currentLocation?.longitude ?? 78.3557664,
      );

      setState(() {
        _searchResults = places;
        _isLoading = false;
      });

      // Add to recent searches (in real app, save to local storage)
      if (places.isNotEmpty) {
        _addToRecentSearches(places.first);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Search error: $e');
    }
  }

  void _addToRecentSearches(PlaceResult place) {
    setState(() {
      _recentSearches.removeWhere((p) => p.placeId == place.placeId);
      _recentSearches.insert(0, place);
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.take(5).toList();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Places'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for restaurants, cafes, places...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: _clearSearch,
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    onSubmitted: _searchPlaces,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () {
                      _showFilterDialog();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Search Results or Recent Searches
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Searching places...'),
                      ],
                    ),
                  )
                : _hasSearched
                    ? _buildSearchResults()
                    : _buildRecentSearches(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No places found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        return Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            final isFavorite = favoritesProvider.isFavorite(place.placeId);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  _showPlaceDetails(place);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Place Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: place.isOpen 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          _getIconForType(place.types.isNotEmpty ? place.types.first : 'place'),
                          color: place.isOpen ? Colors.green : Colors.red,
                          size: 24,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Place Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              place.vicinity,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${place.rating}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${place.userRatingsTotal})',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: place.isOpen 
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    place.isOpen ? 'Open' : 'Closed',
                                    style: TextStyle(
                                      color: place.isOpen ? Colors.green : Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Favorite Button
                                              IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_outline,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          favoritesProvider.toggleFavorite(place.placeId, place: place);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFavorite 
                                    ? '${place.name} removed from favorites'
                                    : '${place.name} added to favorites',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Recent Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        if (_recentSearches.isEmpty)
          const Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Search for places',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Find restaurants, cafes, and more',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _recentSearches.length,
              itemBuilder: (context, index) {
                final place = _recentSearches[index];
                return ListTile(
                  leading: Icon(
                    Icons.history,
                    color: Colors.grey[600],
                  ),
                  title: Text(place.name),
                  subtitle: Text(place.vicinity),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _recentSearches.removeAt(index);
                      });
                    },
                  ),
                  onTap: () {
                    _searchController.text = place.name;
                    _searchPlaces(place.name);
                  },
                );
              },
            ),
          ),
        
        // Quick Search Suggestions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Popular Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickSearchChip('Pizza'),
                  _buildQuickSearchChip('Coffee'),
                  _buildQuickSearchChip('Biryani'),
                  _buildQuickSearchChip('Burger'),
                  _buildQuickSearchChip('Chinese'),
                  _buildQuickSearchChip('South Indian'),
                  _buildQuickSearchChip('Desserts'),
                  _buildQuickSearchChip('Fast Food'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSearchChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _searchPlaces(label);
      },
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showPlaceDetails(PlaceResult place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PlaceDetailsSheet(place: place),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Restaurants'),
              onTap: () {
                Navigator.pop(context);
                _searchController.text = 'restaurants';
                _searchPlaces('restaurants');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_cafe),
              title: const Text('Cafes'),
              onTap: () {
                Navigator.pop(context);
                _searchController.text = 'cafes';
                _searchPlaces('cafes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_gas_station),
              title: const Text('Gas Stations'),
              onTap: () {
                Navigator.pop(context);
                _searchController.text = 'gas stations';
                _searchPlaces('gas stations');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_grocery_store),
              title: const Text('Grocery Stores'),
              onTap: () {
                Navigator.pop(context);
                _searchController.text = 'grocery stores';
                _searchPlaces('grocery stores');
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'bakery':
        return Icons.bakery_dining;
      case 'meal_takeaway':
        return Icons.takeout_dining;
      case 'food':
        return Icons.local_grocery_store;
      case 'gas_station':
        return Icons.local_gas_station;
      default:
        return Icons.place;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}