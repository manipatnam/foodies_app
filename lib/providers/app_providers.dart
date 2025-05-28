import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'restaurant_provider.dart';
import 'user_provider.dart';
import 'favorites_provider.dart';
import 'search_provider.dart';
import 'theme_provider.dart';

class AppProviders {
  static List<SingleChildWidget> get providers => [
    // Theme Provider
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    
    // User Provider
    ChangeNotifierProvider(create: (_) => UserProvider()),
    
    // Restaurant Provider
    ChangeNotifierProvider(create: (_) => RestaurantProvider()),
    
    // Favorites Provider
    ChangeNotifierProvider(create: (_) => FavoritesProvider()),
    
    // Search Provider
    ChangeNotifierProvider(create: (_) => SearchProvider()),
  ];
}