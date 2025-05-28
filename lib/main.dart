import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Error loading .env file: $e');
    // Continue without .env file - will use mock data
  }
  
  runApp(const FoodiesApp());
}

class FoodiesApp extends StatelessWidget {
  const FoodiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Foodies - Find Nearby Food',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.orange,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}