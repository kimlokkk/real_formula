import 'package:flutter/material.dart';
import 'ui/main_menu_page.dart';
import 'ui/race_setup_page.dart';
import 'ui/qualifying_page.dart'; // Updated to simple version
import 'ui/race_simulator_page.dart';
import 'ui/race_results_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Race Simulator',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Arial', // You can add a custom font later
      ),
      debugShowCheckedModeBanner: false,

      // Set initial route to main menu
      initialRoute: '/',

      // Define all routes
      routes: {
        '/': (context) => MainMenuPage(),
        '/setup': (context) => RaceSetupPage(),
        '/qualifying': (context) => QualifyingPage(), // NEW
        '/race': (context) => F1RaceSimulator(),
        '/results': (context) => RaceResultsPage(),
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
