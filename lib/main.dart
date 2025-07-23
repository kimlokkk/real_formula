// lib/main.dart - Updated with Career Mode routes
import 'package:flutter/material.dart';
import 'ui/main_menu_page.dart';
import 'ui/race_setup_page.dart';
import 'ui/qualifying_page.dart';
import 'ui/race_simulator_page.dart';
import 'ui/race_results_page.dart';
// NEW: Career Mode imports
import 'ui/career/driver_creation_page.dart';
import 'ui/career/career_home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
        '/results': (context) => RaceResultsPage(),

        // NEW: Career Mode routes
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
