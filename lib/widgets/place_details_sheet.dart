import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place_result.dart';
import '../main.dart';

class PlaceDetailsSheet extends StatelessWidget {
  final PlaceResult place;

  const PlaceDetailsSheet({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Place name and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: place.isOpen 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  place.isOpen ? 'Open Now' : 'Closed',
                  style: TextStyle(
                    color: place.isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Rating and reviews
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[600],
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${place.rating}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${place.userRatingsTotal} reviews)',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  place.vicinity,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Type/Category
          Row(
            children: [
              Icon(
                Icons.category,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _formatPlaceType(place.types.first),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openInMaps(place),
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callPlace(place),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Additional buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _sharePlace(place),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addToFavorites(place),
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text('Save'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Additional info
          if (place.priceLevel > 0)
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Price level: ${'₹' * place.priceLevel}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatPlaceType(String type) {
    switch (type) {
      case 'restaurant':
        return 'Restaurant';
      case 'cafe':
        return 'Cafe';
      case 'bakery':
        return 'Bakery';
      case 'meal_takeaway':
        return 'Takeaway';
      case 'food':
        return 'Food Store';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _openInMaps(PlaceResult place) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showSnackBar('Could not open maps');
    }
  }

  void _callPlace(PlaceResult place) {
    // This would require fetching place details with phone number from Places API
    // For now, we'll just show a message
    _showSnackBar('Phone number would be available with Places API integration');
  }

  void _sharePlace(PlaceResult place) {
    // Create a shareable text about the place
    final shareText = 'Check out ${place.name}!\n'
        'Rating: ${place.rating}⭐ (${place.userRatingsTotal} reviews)\n'
        'Location: ${place.vicinity}\n'
        'Status: ${place.isOpen ? 'Open Now' : 'Closed'}\n\n'
        'Find it on Google Maps: https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}';
    
    _showSnackBar('Share feature: $shareText');
    // In a real app, you would use the share_plus package:
    // Share.share(shareText);
  }

  void _addToFavorites(PlaceResult place) {
    // Add to favorites functionality
    _showSnackBar('${place.name} added to favorites!');
    // In a real app, you would save to local storage or database
  }

  void _showSnackBar(String message) {
    if (navigatorKey.currentContext != null) {
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}