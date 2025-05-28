import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'providers/app_providers.dart';

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const FoodiesApp());
}

class FoodiesApp extends StatelessWidget {
  const FoodiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.providers,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Foodies - Find Nearby Food',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.orange,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}