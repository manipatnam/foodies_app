import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../models/place_result.dart';
import '../services/places_service.dart';
import '../widgets/place_details_sheet.dart';

class MapScreen extends StatefulWidget {
  final LocationData? currentLocation;
  
  const MapScreen({super.key, this.currentLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  Set<Marker> _markers = {};
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
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Automatically refresh places when location changes
    if (widget.currentLocation != null && 
        (oldWidget.currentLocation == null ||
         oldWidget.currentLocation!.latitude != widget.currentLocation!.latitude ||
         oldWidget.currentLocation!.longitude != widget.currentLocation!.longitude)) {
      print('Location changed - refreshing map');
      _loadNearbyPlaces();
      _updateCameraPosition();
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

      await _updateMarkers(places);

      setState(() {
        _nearbyPlaces = places;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading places: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateMarkers(List<PlaceResult> places) async {
    final Set<Marker> markers = {};

    // Add user location marker
    if (widget.currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            widget.currentLocation!.latitude!,
            widget.currentLocation!.longitude!,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Add place markers
    for (var place in places) {
      markers.add(
        Marker(
          markerId: MarkerId(place.placeId),
          position: LatLng(place.latitude, place.longitude),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: '${place.rating}⭐ • ${place.vicinity}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            place.isOpen ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          onTap: () => _showPlaceDetails(place),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updateCameraPosition() {
    if (_controller != null && widget.currentLocation != null) {
      _controller!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            widget.currentLocation!.latitude!,
            widget.currentLocation!.longitude!,
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
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
                
                // Google Map
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _controller = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        widget.currentLocation!.latitude!,
                        widget.currentLocation!.longitude!,
                      ),
                      zoom: 15.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true, // This provides the Google location button
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                    trafficEnabled: false,
                    buildingsEnabled: true,
                    indoorViewEnabled: true,
                    onTap: (LatLng position) {
                      // Close any open info windows when tapping on map
                    },
                  ),
                ),
              ],
            ),
      // Removed the custom FloatingActionButton since Google Maps provides its own location button
    );
  }
}