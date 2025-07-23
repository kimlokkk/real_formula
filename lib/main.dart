// lib/main.dart - Fixed version with proper imports and calendar integration
import 'package:flutter/material.dart';
import 'package:real_formula/ui/career/race_weekend_loading.dart';
import 'ui/main_menu_page.dart';
import 'ui/race_setup_page.dart';
import 'ui/qualifying_page.dart';
import 'ui/race_simulator_page.dart';
import 'ui/race_results_page.dart'; // ✅ ONLY import from race_results_page.dart
import 'ui/career/driver_creation_page.dart';
import 'ui/career/career_home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // ✅ FIXED: Added key parameter

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Race Simulator - Career Mode',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Arial',
      ),
      debugShowCheckedModeBanner: false,

      // Set initial route to main menu
      initialRoute: '/',

      // Define all routes (existing + new career routes)
      routes: {
        // Existing routes
        '/': (context) => MainMenuPage(),
        '/setup': (context) => RaceSetupPage(),
        '/qualifying': (context) => QualifyingPage(),
        '/race': (context) => F1RaceSimulator(),
        '/results': (context) => const RaceResultsPage(), // ✅ FIXED: Added const and proper constructor
        '/race_weekend_loading': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RaceWeekendLoadingScreen(
            raceWeekend: args['raceWeekend'],
            careerDriver: args['careerDriver'],
          );
        },

        // Career Mode routes
        '/driver_creation': (context) => DriverCreationPage(),
        '/career_home': (context) => CareerHomePage(),
      },

      // Handle unknown routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => MainMenuPage(),
        );
      },
    );
  }
}
