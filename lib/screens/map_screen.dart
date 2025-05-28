import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../models/place_result.dart';
import '../widgets/place_card.dart';
import '../widgets/place_details_sheet.dart';
import '../services/places_service.dart';

class NearbyScreen extends StatefulWidget {
  final LocationData? currentLocation;
  
  const NearbyScreen({super.key, this.currentLocation});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  List<PlaceResult> _nearbyPlaces = [];
  bool _isLoading = false;
  String _selectedCategory = 'restaurant';

  final Map<String, String> _categories = {
    'restaurant': 'Restaurants',
    'cafe': 'Cafes',
    'bakery': 'Bakeries',
    'meal_takeaway': 'Takeaway',
    'food': 'Food Stores',
  };

  @override
  void didUpdateWidget(NearbyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Automatically refresh places when location changes
    if (widget.currentLocation != null && 
        (oldWidget.currentLocation == null ||
         oldWidget.currentLocation!.latitude != widget.currentLocation!.latitude ||
         oldWidget.currentLocation!.longitude != widget.currentLocation!.longitude)) {
      print('Location changed - refreshing nearby places');
      _loadNearbyPlaces();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _loadNearbyPlaces();
    }
  }

  Future<void> _loadNearbyPlaces() async {
    if (widget.currentLocation == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final places = await PlacesService.getNearbyPlaces(
        lat: widget.currentLocation!.latitude!,
        lng: widget.currentLocation!.longitude!,
        type: _selectedCategory,
      );

      setState(() {
        _nearbyPlaces = places;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Places'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: widget.currentLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting your location...'),
                ],
              ),
            )
          : Column(
              children: [
                // Category Filter
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories.keys.elementAt(index);
                      final isSelected = category == _selectedCategory;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_categories[category]!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                            _loadNearbyPlaces();
                          },
                          selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                        ),
                      );
                    },
                  ),
                ),
                
                // Places List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _nearbyPlaces.isEmpty
                          ? const Center(
                              child: Text('No places found nearby'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _nearbyPlaces.length,
                              itemBuilder: (context, index) {
                                return PlaceCard(
                                  place: _nearbyPlaces[index],
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (context) => PlaceDetailsSheet(place: _nearbyPlaces[index]),
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}