import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/enums.dart';

class DriverData {
  /// Creates the default set of F1 drivers with realistic stats
  static List<Driver> createDefaultDrivers() {
    return [
      // Mercedes Team (High reliability: 92)
      Driver(
        name: "Hamilton",
        team: "Mercedes",
        speed: 95,
        consistency: 90,
        tyreManagementSkill: 95,
        carPerformance: 95,
        reliability: 92,
        teamColor: Colors.teal,
      ),
      Driver(
        name: "Russell",
        team: "Mercedes",
        speed: 80,
        consistency: 85,
        tyreManagementSkill: 80,
        carPerformance: 95,
        reliability: 92,
        teamColor: Colors.cyan,
      ),

      // Red Bull Team (Excellent reliability: 95)
      Driver(
        name: "Verstappen",
        team: "Red Bull",
        speed: 98,
        consistency: 95,
        tyreManagementSkill: 90,
        carPerformance: 98,
        reliability: 95,
        teamColor: Colors.blue,
      ),
      Driver(
        name: "Perez",
        team: "Red Bull",
        speed: 78,
        consistency: 82,
        tyreManagementSkill: 85,
        carPerformance: 98,
        reliability: 95,
        teamColor: Colors.indigo,
      ),

      // Ferrari Team (Moderate reliability: 85)
      Driver(
        name: "Leclerc",
        team: "Ferrari",
        speed: 88,
        consistency: 75,
        tyreManagementSkill: 75,
        carPerformance: 92,
        reliability: 85,
        teamColor: Colors.red,
      ),
      Driver(
        name: "Sainz",
        team: "Ferrari",
        speed: 82,
        consistency: 88,
        tyreManagementSkill: 85,
        carPerformance: 92,
        reliability: 85,
        teamColor: Colors.redAccent,
      ),

      // McLaren Team (Good reliability: 88)
      Driver(
        name: "Norris",
        team: "McLaren",
        speed: 85,
        consistency: 82,
        tyreManagementSkill: 80,
        carPerformance: 88,
        reliability: 88,
        teamColor: Colors.orange,
      ),
      Driver(
        name: "Piastri",
        team: "McLaren",
        speed: 78,
        consistency: 75,
        tyreManagementSkill: 75,
        carPerformance: 88,
        reliability: 88,
        teamColor: Colors.deepOrange,
      ),

      // Aston Martin Team (Decent reliability: 82)
      Driver(
        name: "Alonso",
        team: "Aston Martin",
        speed: 92,
        consistency: 95,
        tyreManagementSkill: 90,
        carPerformance: 85,
        reliability: 82,
        teamColor: Colors.green,
      ),

      // Williams Team (Lower reliability: 78)
      Driver(
        name: "Rookie",
        team: "Williams",
        speed: 60,
        consistency: 50,
        tyreManagementSkill: 55,
        carPerformance: 75,
        reliability: 78,
        teamColor: Colors.grey,
      ),
    ];
  }

  /// Creates a custom driver with specified attributes
  static Driver createCustomDriver({
    required String name,
    required String team,
    required int speed,
    required int consistency,
    required int tyreManagementSkill,
    required int carPerformance,
    required int reliability,
    required Color teamColor,
  }) {
    return Driver(
      name: name,
      team: team,
      speed: speed,
      consistency: consistency,
      tyreManagementSkill: tyreManagementSkill,
      carPerformance: carPerformance,
      reliability: reliability,
      teamColor: teamColor,
    );
  }

  /// Gets team information for UI display
  static Map<String, TeamInfo> getTeamInfo() {
    return {
      "Mercedes": TeamInfo(
        name: "Mercedes",
        primaryColor: Colors.teal,
        secondaryColor: Colors.cyan,
        carPerformance: 95,
        reliability: 92,
        strategy: "balanced",
      ),
      "Red Bull": TeamInfo(
        name: "Red Bull",
        primaryColor: Colors.blue,
        secondaryColor: Colors.indigo,
        carPerformance: 98,
        reliability: 95,
        strategy: "aggressive",
      ),
      "Ferrari": TeamInfo(
        name: "Ferrari",
        primaryColor: Colors.red,
        secondaryColor: Colors.redAccent,
        carPerformance: 92,
        reliability: 85,
        strategy: "aggressive",
      ),
      "McLaren": TeamInfo(
        name: "McLaren",
        primaryColor: Colors.orange,
        secondaryColor: Colors.deepOrange,
        carPerformance: 88,
        reliability: 88,
        strategy: "balanced",
      ),
      "Aston Martin": TeamInfo(
        name: "Aston Martin",
        primaryColor: Colors.green,
        secondaryColor: Colors.green,
        carPerformance: 85,
        reliability: 82,
        strategy: "conservative",
      ),
      "Williams": TeamInfo(
        name: "Williams",
        primaryColor: Colors.grey,
        secondaryColor: Colors.grey,
        carPerformance: 75,
        reliability: 78,
        strategy: "aggressive",
      ),
    };
  }

  /// Gets driver skill presets for easy driver creation
  static Map<String, DriverSkillPreset> getDriverSkillPresets() {
    return {
      "World Champion": DriverSkillPreset(
        speed: 95,
        consistency: 90,
        tyreManagementSkill: 90,
        description: "Elite driver with exceptional all-around skills",
      ),
      "Veteran": DriverSkillPreset(
        speed: 88,
        consistency: 95,
        tyreManagementSkill: 92,
        description: "Experienced driver with supreme consistency",
      ),
      "Young Talent": DriverSkillPreset(
        speed: 85,
        consistency: 75,
        tyreManagementSkill: 70,
        description: "Fast but inconsistent, learning tire management",
      ),
      "Rookie": DriverSkillPreset(
        speed: 65,
        consistency: 55,
        tyreManagementSkill: 60,
        description: "New to F1, still developing skills",
      ),
      "Midfield Regular": DriverSkillPreset(
        speed: 78,
        consistency: 80,
        tyreManagementSkill: 78,
        description: "Solid performer, reliable points scorer",
      ),
      "Tire Whisperer": DriverSkillPreset(
        speed: 82,
        consistency: 85,
        tyreManagementSkill: 95,
        description: "Exceptional tire management, makes rubber last",
      ),
      "Speed Demon": DriverSkillPreset(
        speed: 95,
        consistency: 70,
        tyreManagementSkill: 75,
        description: "Extremely fast but prone to mistakes",
      ),
    };
  }

  /// Initializes starting grid positions for drivers
  static void initializeStartingGrid(List<Driver> drivers) {
    for (int i = 0; i < drivers.length; i++) {
      drivers[i].position = i + 1;
      drivers[i].startingPosition = i + 1;
      drivers[i].positionChangeFromStart = 0;
    }
  }

  /// Resets all drivers for a new race
  static void resetAllDriversForNewRace(List<Driver> drivers, WeatherCondition weather) {
    for (Driver driver in drivers) {
      driver.resetForNewRace();
      driver.currentCompound = driver.getWeatherAppropriateStartingCompound(weather);
    }
    initializeStartingGrid(drivers);
  }

  /// Validates driver stats are within acceptable ranges
  static bool validateDriverStats(Driver driver) {
    return driver.speed >= 50 &&
        driver.speed <= 100 &&
        driver.consistency >= 50 &&
        driver.consistency <= 100 &&
        driver.tyreManagementSkill >= 50 &&
        driver.tyreManagementSkill <= 100 &&
        driver.carPerformance >= 70 &&
        driver.carPerformance <= 100 &&
        driver.reliability >= 70 &&
        driver.reliability <= 100;
  }

  /// Gets performance tier for a driver based on overall stats
  static String getDriverPerformanceTier(Driver driver) {
    double overallRating = (driver.speed + driver.consistency + driver.tyreManagementSkill) / 3.0;

    if (overallRating >= 90) return "Elite";
    if (overallRating >= 80) return "Top Tier";
    if (overallRating >= 70) return "Midfield";
    if (overallRating >= 60) return "Backmarker";
    return "Rookie";
  }

  /// Gets car performance tier for a driver
  static String getCarPerformanceTier(Driver driver) {
    if (driver.carPerformance >= 95) return "Championship Contender";
    if (driver.carPerformance >= 88) return "Regular Points Scorer";
    if (driver.carPerformance >= 80) return "Midfield Runner";
    return "Backmarker";
  }
}

/// Team information for UI and strategy
class TeamInfo {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final int carPerformance;
  final int reliability;
  final String strategy;

  TeamInfo({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.carPerformance,
    required this.reliability,
    required this.strategy,
  });
}

/// Driver skill preset for easy driver creation
class DriverSkillPreset {
  final int speed;
  final int consistency;
  final int tyreManagementSkill;
  final String description;

  DriverSkillPreset({
    required this.speed,
    required this.consistency,
    required this.tyreManagementSkill,
    required this.description,
  });
}
