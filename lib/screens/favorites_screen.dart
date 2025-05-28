import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/favorites_provider.dart';
import '../widgets/place_card.dart';
import '../widgets/place_details_sheet.dart';
import '../models/place_result.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _sortBy = 'name'; // 'name', 'rating', 'type'
  String _filterBy = 'all'; // 'all', 'restaurant', 'cafe', 'bakery', etc.
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha),
                    SizedBox(width: 8),
                    Text('Sort by Name'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Sort by Rating'),
                  ],
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Places'),
              ),
              const PopupMenuItem(
                value: 'restaurant',
                child: Text('Restaurants'),
              ),
              const PopupMenuItem(
                value: 'cafe',
                child: Text('Cafes'),
              ),
              const PopupMenuItem(
                value: 'bakery',
                child: Text('Bakeries'),
              ),
              const PopupMenuItem(
                value: 'meal_takeaway',
                child: Text('Takeaway'),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              _handleMenuAction(value, context);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Favorites'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final favorites = _getFilteredAndSortedFavorites(favoritesProvider);
          
          if (favorites.isEmpty) {
            return _buildEmptyState();
          }
          
          return Column(
            children: [
              // Statistics Card
              _buildStatsCard(favoritesProvider),
              
              // Favorites List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final place = favorites[index];
                    return Dismissible(
                      key: Key(place.placeId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        return await _showDeleteConfirmation(context, place.name);
                      },
                      onDismissed: (direction) {
                        favoritesProvider.removeFromFavorites(place.placeId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${place.name} removed from favorites'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                favoritesProvider.addToFavorites(place);
                              },
                            ),
                          ),
                        );
                      },
                      child: Card(
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
                                // Place Icon with Favorite Badge
                                Stack(
                                  children: [
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
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.white, width: 1),
                                        ),
                                        child: const Icon(
                                          Icons.favorite,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
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
                                          if (place.priceLevel > 0)
                                            Row(
                                              children: [
                                                Text(
                                                  '₹' * place.priceLevel,
                                                  style: TextStyle(
                                                    color: Colors.green[600],
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                            ),
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
                                
                                // Menu Button
                                PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                                  onSelected: (value) {
                                    _handlePlaceAction(value, place, favoritesProvider);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline),
                                          SizedBox(width: 8),
                                          Text('View Details'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'directions',
                                      child: Row(
                                        children: [
                                          Icon(Icons.directions),
                                          SizedBox(width: 8),
                                          Text('Get Directions'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'share',
                                      child: Row(
                                        children: [
                                          Icon(Icons.share),
                                          SizedBox(width: 8),
                                          Text('Share'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.remove_circle_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Remove', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring and save your favorite places!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to search screen
              // You'll need to implement navigation based on your app structure
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.search),
            label: const Text('Search Places'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsCard(FavoritesProvider provider) {
    if (provider.totalFavorites == 0) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${provider.totalFavorites} Favorites',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Avg ${provider.averageRating.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Top categories
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ...provider.favoritesByType.entries
                  .take(2)
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '${_formatType(entry.key)}: ${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      )),
            ],
          ),
        ],
      ),
    );
  }
  
  List<PlaceResult> _getFilteredAndSortedFavorites(FavoritesProvider provider) {
    List<PlaceResult> favorites;
    
    // Filter
    if (_filterBy == 'all') {
      favorites = provider.favoritePlaces;
    } else {
      favorites = provider.getFavoritesByType(_filterBy);
    }
    
    // Sort
    switch (_sortBy) {
      case 'name':
        favorites.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        favorites.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    
    return favorites;
  }
  
  void _handleMenuAction(String action, BuildContext context) async {
    final provider = Provider.of<FavoritesProvider>(context, listen: false);
    
    switch (action) {
      case 'export':
        final exportData = provider.exportFavorites();
        // In a real app, you'd use the share package or file picker
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${provider.totalFavorites} favorites'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy to clipboard functionality would go here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export data copied to clipboard')),
                );
              },
            ),
          ),
        );
        break;
      case 'clear':
        final confirmed = await _showClearConfirmation(context);
        if (confirmed == true) {
          provider.clearFavorites();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All favorites cleared')),
          );
        }
        break;
    }
  }
  
  void _handlePlaceAction(String action, PlaceResult place, FavoritesProvider provider) {
    switch (action) {
      case 'details':
        _showPlaceDetails(place);
        break;
      case 'directions':
        _openDirections(place);
        break;
      case 'share':
        _sharePlace(place);
        break;
      case 'remove':
        provider.removeFromFavorites(place.placeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${place.name} removed from favorites'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                provider.addToFavorites(place);
              },
            ),
          ),
        );
        break;
    }
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
  
  void _openDirections(PlaceResult place) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps')),
      );
    }
  }
  
  void _sharePlace(PlaceResult place) {
    final shareText = 'Check out ${place.name}!\n'
        'Rating: ${place.rating}⭐ (${place.userRatingsTotal} reviews)\n'
        'Location: ${place.vicinity}\n'
        'Status: ${place.isOpen ? 'Open Now' : 'Closed'}\n\n'
        'Find it on Google Maps: https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
    
    // In a real app, you would use the share_plus package:
    // Share.share(shareText);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Share feature would open here'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }
  
  Future<bool?> _showDeleteConfirmation(BuildContext context, String placeName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: Text('Remove $placeName from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
  
  Future<bool?> _showClearConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text('This will remove all your favorite places. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
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
  
  String _formatType(String type) {
    switch (type) {
      case 'restaurant':
        return 'Restaurants';
      case 'cafe':
        return 'Cafes';
      case 'bakery':
        return 'Bakeries';
      case 'meal_takeaway':
        return 'Takeaway';
      case 'food':
        return 'Food';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }
}