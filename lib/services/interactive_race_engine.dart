// lib/services/interactive_race_engine.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/interactive_race.dart';
import '../models/team.dart';

class InteractiveRaceEngine {
  static const int totalLaps = 50;

  /// Simulate race start for all AI drivers while player does Launch Control mini-game
  static List<Driver> simulateRaceStart(List<Driver> startingGrid, {String? playerDriverName}) {
    List<Driver> raceStartResults = List.from(startingGrid);

    // Simulate each AI driver's race start
    for (Driver driver in raceStartResults) {
      if (playerDriverName != null && driver.name == playerDriverName) {
        continue; // Skip player, their result comes from mini-game
      }

      // Calculate race start performance based on driver stats and randomness
      double startPerformance = _calculateRaceStartPerformance(driver);
      driver.raceStartPerformance = startPerformance;
    }

    // Sort AI drivers only by race start performance
    List<Driver> aiDrivers = raceStartResults.where((d) => d.name != playerDriverName).toList();
    aiDrivers.sort((a, b) => b.raceStartPerformance.compareTo(a.raceStartPerformance));

    // Reassign positions to AI drivers only
    for (int i = 0; i < aiDrivers.length; i++) {
      aiDrivers[i].position = i + 1; // Will be adjusted when player result is integrated
    }

    return raceStartResults;
  }

  /// Calculate race start performance for AI drivers
  static double _calculateRaceStartPerformance(Driver driver) {
    // Base performance from driver stats and car
    double basePerformance = (driver.speed * 0.3) + (driver.consistency * 0.4) + (driver.team.carPerformance * 0.3);

    // Add controlled randomness (more consistent drivers have less variance)
    double variance = (100 - driver.consistency) / 100 * 15; // 0-15 point swing
    double randomFactor = (Random().nextDouble() - 0.5) * variance;

    // Special race start factors
    double experienceFactor = driver.experience * 0.1; // Experience helps with starts
    double pressureFactor = _calculateStartPressure(driver); // Championship pressure

    return (basePerformance + randomFactor + experienceFactor - pressureFactor).clamp(0, 100);
  }

  /// Calculate pressure factor affecting race start
  static double _calculateStartPressure(Driver driver) {
    // Championship leaders feel more pressure
    if (driver.name.contains("Verstappen") || driver.name.contains("Hamilton")) {
      return Random().nextDouble() * 3; // 0-3 points pressure penalty
    }

    // Rookies and backmarkers feel less pressure
    if (driver.experience < 70) {
      return 0; // No pressure, nothing to lose
    }

    return Random().nextDouble() * 1.5; // 0-1.5 points pressure penalty
  }

  /// Integrate player's mini-game result into the race start
  static List<Driver> integratePlayerStartResult(
      List<Driver> aiResults, LaunchControlResult playerResult, String playerDriverName, int startingPosition) {
    List<Driver> finalResults = List.from(aiResults);

    // Find player driver
    Driver? playerDriver = finalResults.firstWhere(
      (driver) => driver.name == playerDriverName,
      orElse: () => throw Exception("Player driver not found"),
    );

    // Calculate player's new position based on mini-game result
    int positionChange = _calculatePositionChangeFromLaunchControl(playerResult, playerDriver, startingPosition);

    int newPosition = (startingPosition + positionChange).clamp(1, finalResults.length);

    // Remove player from current position
    finalResults.removeWhere((driver) => driver.name == playerDriverName);

    // Insert player at new position
    finalResults.insert(newPosition - 1, playerDriver);

    // Update all position numbers
    for (int i = 0; i < finalResults.length; i++) {
      finalResults[i].position = i + 1;
    }

    // Store the position change for feedback
    playerDriver.lastPositionChange = positionChange;

    return finalResults;
  }

  /// Calculate position change based on Launch Control performance
  static int _calculatePositionChangeFromLaunchControl(
      LaunchControlResult result, Driver playerDriver, int startingPosition) {
    // Base position change from mini-game performance
    int baseChange = 0;

    switch (result.performance) {
      case MiniGamePerformance.perfect:
        baseChange = -3; // Gain 3 positions
        break;
      case MiniGamePerformance.excellent:
        baseChange = -2; // Gain 2 positions
        break;
      case MiniGamePerformance.good:
        baseChange = -1; // Gain 1 position
        break;
      case MiniGamePerformance.average:
        baseChange = 0; // No change
        break;
      case MiniGamePerformance.poor:
        baseChange = 1; // Lose 1 position
        break;
      case MiniGamePerformance.terrible:
        baseChange = 2; // Lose 2 positions
        break;
    }

    // Modify based on driver/car capabilities
    double modifier = _calculateDriverCarModifier(playerDriver);

    // Better drivers/cars get more benefit from good results, less penalty from bad
    if (baseChange < 0) {
      // Gaining positions
      baseChange = (baseChange * modifier).round();
    } else if (baseChange > 0) {
      // Losing positions
      baseChange = (baseChange / modifier).round();
    }

    // Consider starting position (harder to gain from front, easier from back)
    if (startingPosition <= 5 && baseChange < 0) {
      baseChange = (baseChange * 0.7).round(); // Harder to gain from front
    } else if (startingPosition >= 15 && baseChange < 0) {
      baseChange = (baseChange * 1.3).round(); // Easier to gain from back
    }

    return baseChange;
  }

  /// Calculate driver/car capability modifier
  static double _calculateDriverCarModifier(Driver driver) {
    double driverFactor = (driver.speed + driver.consistency + driver.experience) / 300;
    double carFactor = driver.team.carPerformance / 100;

    return (driverFactor * 0.6 + carFactor * 0.4).clamp(0.5, 1.5);
  }

  /// Generate mini-game schedule for the race
  static List<int> generateMiniGameSchedule(int totalLaps) {
    List<int> schedule = [];

    // Race start is always lap 1
    schedule.add(1);

    // Early race opportunities (laps 8-12)
    schedule.add(8 + Random().nextInt(5));

    // Pit window chaos (laps 20-30)
    schedule.add(20 + Random().nextInt(11));

    // Mid race battle (laps 32-38)
    schedule.add(32 + Random().nextInt(7));

    // Final stint pressure (laps 42-47)
    schedule.add(42 + Random().nextInt(6));

    return schedule;
  }

  /// Create starting grid with realistic F1 field
  static List<Driver> createDemoStartingGrid() {
    // Use existing driver data but set specific starting positions
    List<Driver> drivers = [
      // Front row - Championship contenders
      Driver(
        name: "Max Verstappen",
        abbreviation: "VER",
        team: _createTeam("Red Bull", 98, 95),
        speed: 97,
        consistency: 96,
        tyreManagementSkill: 94,
        racecraft: 97,
        experience: 92,
      )..position = 1,

      Driver(
        name: "Charles Leclerc",
        abbreviation: "LEC",
        team: _createTeam("Ferrari", 93, 85),
        speed: 94,
        consistency: 84,
        tyreManagementSkill: 88,
        racecraft: 92,
        experience: 84,
      )..position = 2,

      // Second row
      Driver(
        name: "Lando Norris",
        abbreviation: "NOR",
        team: _createTeam("McLaren", 90, 88),
        speed: 92,
        consistency: 88,
        tyreManagementSkill: 90,
        racecraft: 89,
        experience: 84,
      )..position = 3,

      Driver(
        name: "Lewis Hamilton",
        abbreviation: "HAM",
        team: _createTeam("Mercedes", 87, 92),
        speed: 95,
        consistency: 94,
        tyreManagementSkill: 96,
        racecraft: 98,
        experience: 100,
      )..position = 4,

      // Third row
      Driver(
        name: "Carlos Sainz",
        abbreviation: "SAI",
        team: _createTeam("Ferrari", 93, 85),
        speed: 89,
        consistency: 87,
        tyreManagementSkill: 85,
        racecraft: 88,
        experience: 86,
      )..position = 5,

      Driver(
        name: "George Russell",
        abbreviation: "RUS",
        team: _createTeam("Mercedes", 87, 92),
        speed: 89,
        consistency: 91,
        tyreManagementSkill: 87,
        racecraft: 85,
        experience: 80,
      )..position = 6,

      // Fourth row
      Driver(
        name: "Fernando Alonso",
        abbreviation: "ALO",
        team: _createTeam("Aston Martin", 85, 82),
        speed: 91,
        consistency: 95,
        tyreManagementSkill: 95,
        racecraft: 96,
        experience: 98,
      )..position = 7,

      // PLAYER STARTING POSITION
      Driver(
        name: "YOUR DRIVER", // This will be replaced with actual career driver
        abbreviation: "YOU",
        team: _createTeam("Alpine", 82, 80),
        speed: 78, consistency: 72, tyreManagementSkill: 75,
        racecraft: 76, experience: 65,
      )..position = 8,

      // Rest of the field
      Driver(
        name: "Oscar Piastri",
        abbreviation: "PIA",
        team: _createTeam("McLaren", 90, 88),
        speed: 88,
        consistency: 86,
        tyreManagementSkill: 85,
        racecraft: 87,
        experience: 72,
      )..position = 9,

      Driver(
        name: "Pierre Gasly",
        abbreviation: "GAS",
        team: _createTeam("Alpine", 82, 80),
        speed: 84,
        consistency: 85,
        tyreManagementSkill: 82,
        racecraft: 86,
        experience: 86,
      )..position = 10,
    ];

    return drivers;
  }

  /// Helper to create team objects
  static Team _createTeam(String name, int performance, int reliability) {
    // Create teams with all required parameters based on name
    switch (name) {
      case "Red Bull":
        return Team(
          name: name,
          fullName: "Oracle Red Bull Racing",
          carPerformance: performance,
          reliability: reliability,
          primaryColor: Colors.indigo,
          secondaryColor: Colors.yellow,
          strategy: "aggressive",
          engineSupplier: "Honda RBPT",
          pitStopSpeed: 1.2,
          headquarters: "Milton Keynes, UK",
        );
      case "Ferrari":
        return Team(
          name: name,
          fullName: "Scuderia Ferrari",
          carPerformance: performance,
          reliability: reliability,
          primaryColor: Colors.red,
          secondaryColor: Colors.yellow,
          strategy: "aggressive",
          engineSupplier: "Ferrari",
          pitStopSpeed: 0.9,
          headquarters: "Maranello, Italy",
        );
      case "McLaren":
        return Team(
          name: name,
          fullName: "McLaren F1 Team",
          carPerformance: performance,
          reliability: reliability,
          primaryColor: Colors.orange,
          secondaryColor: Colors.blue,
          strategy: "balanced",
          engineSupplier: "Mercedes",
          pitStopSpeed: 1.1,
          headquarters: "Woking, UK",
        );
      case "Mercedes":
        return Team(
          name: name,
          fullName: "Mercedes-AMG PETRONAS F1 Team",
          carPerformance: performance,
          reliability: reliability,
          primaryColor: Colors.teal,
          secondaryColor: Colors.grey,
          strategy: "conservative",
          engineSupplier: "Mercedes",
          pitStopSpeed: 1.0,
          headquarters: "Brackley, UK",
        );
      case "Aston Martin":
        return Team(
          name: name,
          fullName: "Aston Martin Aramco Cognizant F1 Team",
          carPerformance: performance,
          reliability: reliability,
          primaryColor: Colors.green,
          secondaryColor: Colors.black,
          strategy: "balanced",
          engineSupplier: "Honda",
          pitStopSpeed: 1.0,
          headquarters: "Silverstone, UK",
        );
      case "Alpine":
        return Team(
          name: name,
          fullName: "BWT Alpine F1 Team",
          carPerformance: performance,
          reliability: reliability,
          primaryColor: Colors.pink,
          secondaryColor: Colors.blue,
          strategy: "aggressive",
          engineSupplier: "Renault",
          pitStopSpeed: 0.95,
          headquarters: "Enstone, UK",
        );
      default:
        return Team(
          name: name,
          fullName: "$name F1 Team",
          carPerformance: performance,
          reliability: reliability,
          primaryColor: Colors.blue,
          secondaryColor: Colors.white,
          strategy: "balanced",
          engineSupplier: "Mercedes",
          pitStopSpeed: 1.0,
          headquarters: "Unknown",
        );
    }
  }
}

// Extension to add race start performance tracking
extension DriverExtensions on Driver {
  static final Map<String, double> _raceStartPerformances = {};
  static final Map<String, int> _lastPositionChanges = {};

  double get raceStartPerformance => _raceStartPerformances[name] ?? 0.0;
  set raceStartPerformance(double value) => _raceStartPerformances[name] = value;

  int get lastPositionChange => _lastPositionChanges[name] ?? 0;
  set lastPositionChange(int value) => _lastPositionChanges[name] = value;
}
