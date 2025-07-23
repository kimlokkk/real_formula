// lib/main.dart - Career Mode Only
import 'package:flutter/material.dart';
import 'package:real_formula/ui/career/race_weekend_loading.dart';
import 'ui/main_menu_page.dart';
import 'ui/qualifying_page.dart';
import 'ui/race_simulator_page.dart';
import 'ui/race_results_page.dart';
import 'ui/career/driver_creation_page.dart';
import 'ui/career/career_home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F1 Career Simulator',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Arial',
      ),
      debugShowCheckedModeBanner: false,

      // Set initial route to main menu
      initialRoute: '/',

      // Define career-only routes
      routes: {
        // Main menu (career-focused)
        '/': (context) => MainMenuPage(),

        // Career Mode routes
        '/driver_creation': (context) => DriverCreationPage(),
        '/career_home': (context) => CareerHomePage(),

        // Race weekend flow (career only)
        '/race_weekend_loading': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return RaceWeekendLoadingScreen(
            raceWeekend: args['raceWeekend'],
            careerDriver: args['careerDriver'],
          );
        },

        // Race session routes (career context)
        '/qualifying': (context) => QualifyingPage(),
        '/race': (context) => F1RaceSimulator(),
        '/results': (context) => const RaceResultsPage(),
      },

      // Handle unknown routes - redirect to main menu
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => MainMenuPage(),
        );
      },
    );
  }
}
