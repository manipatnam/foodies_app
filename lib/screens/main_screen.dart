import 'package:flutter/material.dart';
import 'package:location/location.dart';

// Import screens individually to avoid conflicts
import 'package:foodies_app/screens/map_screen.dart' as map;
import 'package:foodies_app/screens/nearby_screen.dart' as nearby; 
import 'package:foodies_app/screens/favorites_screen.dart';
import 'package:foodies_app/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  LocationData? _currentLocation;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationWithRealGPS();
  }

  Future<void> _getCurrentLocationWithRealGPS() async {
    try {
      setState(() {
        _isLoadingLocation = true;
      });

      Location location = Location();
      
      // Step 1: Check and request permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {        
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          _setDefaultLocation();
          return;
        }
      }

      // Step 2: Try to enable location services
      try {
        bool serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            _setDefaultLocation();
            return;
          }
        }
      } catch (e) {
        print('Service check failed: $e');
        // Continue anyway - some phones don't support service check
      }

      // Step 3: Get actual GPS location
      try {
        final locationData = await location.getLocation().timeout(
          const Duration(seconds: 10),
        );
        
        // Success! Got real GPS location
        setState(() {
          _currentLocation = locationData;
          _isLoadingLocation = false;
        });
        
        print('✅ Real GPS Location: ${locationData.latitude}, ${locationData.longitude}');
        
      } catch (e) {
        print('GPS failed: $e');
        _setDefaultLocation();
      }
      
    } catch (e) {
      print('Location error: $e');
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    // Fallback to Hyderabad city center
    setState(() {
      _currentLocation = LocationData.fromMap({
        'latitude': 17.4518794,
        'longitude': 78.3557664,
        'accuracy': 1000.0,
        'altitude': 0.0,
        'speed': 0.0,
        'speedAccuracy': 0.0,
        'heading': 0.0,
        'time': DateTime.now().millisecondsSinceEpoch.toDouble(),
      });
      _isLoadingLocation = false;
    });
  }

  // Manual refresh location - silent refresh without showing messages
  Future<void> _refreshLocation() async {
    try {
      Location location = Location();
      
      // Get new location without showing messages
      final locationData = await location.getLocation().timeout(
        const Duration(seconds: 5),
      );
      
      // Update location silently
      setState(() {
        _currentLocation = locationData;
      });
      
      print('✅ Location refreshed: ${locationData.latitude}, ${locationData.longitude}');
      
    } catch (e) {
      print('Location refresh failed: $e');
      // Silently fail - no user notification needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingLocation
          ? _buildLoadingScreen()
          : IndexedStack(
              index: _currentIndex,
              children: [
                map.MapScreen(currentLocation: _currentLocation),
                nearby.NearbyScreen(currentLocation: _currentLocation),
                const FavoritesScreen(),
                const ProfileScreen(),
              ],
            ),
      bottomNavigationBar: _isLoadingLocation 
          ? null
          : BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: Theme.of(context).primaryColor,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant),
                  label: 'Nearby',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Favorites',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
      floatingActionButton: !_isLoadingLocation && _currentLocation != null
          ? FloatingActionButton(
              onPressed: _refreshLocation, // Silent refresh
              backgroundColor: Theme.of(context).primaryColor,
              tooltip: 'Refresh Location',
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat, // Positions FAB to bottom left
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              SizedBox(
                width: 100,
                height: 100,
                child: Icon(
                  Icons.restaurant,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: 40),
              
              // App Title
              Text(
                'Foodies',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              SizedBox(height: 60),
              
              // Loading Spinner
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Status Text
              Text(
                "Finding restaurants near you...",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}