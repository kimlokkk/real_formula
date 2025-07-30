// lib/main.dart - Career Mode Only with Formula 1 Fonts and Fixed Colors
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
        // Fix the purple color issue with proper color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
          primary: Colors.red[600]!,
          secondary: Colors.orange[600]!,
          surface: Colors.grey[900]!,
          background: Colors.black,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),

        // Use dark theme as base to prevent purple defaults
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // Formula 1 Font Configuration
        fontFamily: 'Formula1',

        // Enhanced text theme using Formula 1 fonts with proper default colors
        textTheme: TextTheme(
          // Display styles (large headings)
          displayLarge: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w900, // Formula1-Wide
            fontSize: 57,
            letterSpacing: -0.25,
            color: Colors.white, // Fix default color
          ),
          displayMedium: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 45,
            letterSpacing: 0,
            color: Colors.white,
          ),
          displaySmall: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 36,
            letterSpacing: 0,
            color: Colors.white,
          ),

          // Headline styles (medium headings)
          headlineLarge: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 32,
            letterSpacing: 0,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 28,
            letterSpacing: 0,
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400, // Formula1-Regular
            fontSize: 24,
            letterSpacing: 0,
            color: Colors.white,
          ),

          // Title styles (smaller headings)
          titleLarge: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 22,
            letterSpacing: 0,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 16,
            letterSpacing: 0.15,
            color: Colors.white,
          ),
          titleSmall: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400, // Formula1-Regular
            fontSize: 14,
            letterSpacing: 0.1,
            color: Colors.white,
          ),

          // Body text styles
          bodyLarge: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400, // Formula1-Regular
            fontSize: 16,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400, // Formula1-Regular
            fontSize: 14,
            letterSpacing: 0.25,
            color: Colors.white,
          ),
          bodySmall: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400, // Formula1-Regular
            fontSize: 12,
            letterSpacing: 0.4,
            color: Colors.grey[300],
          ),

          // Label styles (buttons, etc.)
          labelLarge: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 14,
            letterSpacing: 0.1,
            color: Colors.white,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700, // Formula1-Bold
            fontSize: 12,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400, // Formula1-Regular
            fontSize: 11,
            letterSpacing: 0.5,
            color: Colors.grey[400],
          ),
        ),

        // Enhanced app bar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.15,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
        ),

        // Enhanced button themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: TextStyle(
              fontFamily: 'Formula1',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: 1.25,
            ),
            foregroundColor: Colors.white,
          ),
        ),

        // Enhanced input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400,
            color: Colors.grey[300],
          ),
          hintStyle: TextStyle(
            fontFamily: 'Formula1',
            fontWeight: FontWeight.w400,
            color: Colors.grey[500],
          ),
        ),

        // Icon theme to fix purple icons
        iconTheme: IconThemeData(
          color: Colors.white,
        ),

        // Primary icon theme
        primaryIconTheme: IconThemeData(
          color: Colors.white,
        ),
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
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
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
