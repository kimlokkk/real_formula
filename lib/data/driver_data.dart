// lib/data/driver_data.dart - Clean version without debug logging

import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import 'team_data.dart';

class DriverData {
  /// Creates the default set of F1 drivers with realistic stats
  /// Creates the default set of F1 drivers with realistic stats (10 drivers for gameplay)
  // lib/data/driver_data.dart - Updated with F1-style 3-letter abbreviations

  static List<Driver> createDefaultDrivers() {
    return [
      // Red Bull Team
      Driver(
        name: "Max Verstappen",
        abbreviation: "VER", // F1 official abbreviation
        team: TeamData.getTeamByName("Red Bull"),
        speed: 99,
        consistency: 96,
        tyreManagementSkill: 94,
        racecraft: 97,
        experience: 92,
      ),
      Driver(
        name: "Yuki Tsunoda",
        abbreviation: "TSU",
        team: TeamData.getTeamByName("Red Bull"),
        speed: 82,
        consistency: 78,
        tyreManagementSkill: 80,
        racecraft: 84,
        experience: 76,
      ),

      // Ferrari Team
      Driver(
        name: "Lewis Hamilton",
        abbreviation: "HAM", // F1 official abbreviation
        team: TeamData.getTeamByName("Ferrari"),
        speed: 95,
        consistency: 94,
        tyreManagementSkill: 96,
        racecraft: 98,
        experience: 100,
      ),
      Driver(
        name: "Charles Leclerc",
        abbreviation: "LEC", // F1 official abbreviation
        team: TeamData.getTeamByName("Ferrari"),
        speed: 94,
        consistency: 84,
        tyreManagementSkill: 88,
        racecraft: 92,
        experience: 84,
      ),

      // McLaren Team
      Driver(
        name: "Lando Norris",
        abbreviation: "NOR", // F1 official abbreviation
        team: TeamData.getTeamByName("McLaren"),
        speed: 92,
        consistency: 88,
        tyreManagementSkill: 90,
        racecraft: 89,
        experience: 84,
      ),
      Driver(
        name: "Oscar Piastri",
        abbreviation: "PIA", // F1 official abbreviation
        team: TeamData.getTeamByName("McLaren"),
        speed: 88,
        consistency: 86,
        tyreManagementSkill: 85,
        racecraft: 87,
        experience: 72,
      ),

      // Mercedes Team
      Driver(
        name: "George Russell",
        abbreviation: "RUS", // F1 official abbreviation
        team: TeamData.getTeamByName("Mercedes"),
        speed: 89,
        consistency: 91,
        tyreManagementSkill: 87,
        racecraft: 85,
        experience: 80,
      ),
      Driver(
        name: "Andrea Kimi Antonelli",
        abbreviation: "ANT", // New driver - logical abbreviation
        team: TeamData.getTeamByName("Mercedes"),
        speed: 86,
        consistency: 75,
        tyreManagementSkill: 78,
        racecraft: 82,
        experience: 60,
      ),

      // Aston Martin Team
      Driver(
        name: "Fernando Alonso",
        abbreviation: "ALO", // F1 official abbreviation
        team: TeamData.getTeamByName("Aston Martin"),
        speed: 91,
        consistency: 95,
        tyreManagementSkill: 95,
        racecraft: 96,
        experience: 98,
      ),
      Driver(
        name: "Lance Stroll",
        abbreviation: "STR", // F1 official abbreviation
        team: TeamData.getTeamByName("Aston Martin"),
        speed: 75,
        consistency: 82,
        tyreManagementSkill: 78,
        racecraft: 74,
        experience: 82,
      ),

      // Alpine Team
      Driver(
        name: "Pierre Gasly",
        abbreviation: "GAS", // F1 official abbreviation
        team: TeamData.getTeamByName("Alpine"),
        speed: 84,
        consistency: 85,
        tyreManagementSkill: 82,
        racecraft: 86,
        experience: 86,
      ),
      Driver(
        name: "Franco Colapinto",
        abbreviation: "COL", // New driver - logical abbreviation
        team: TeamData.getTeamByName("Alpine"),
        speed: 83,
        consistency: 79,
        tyreManagementSkill: 76,
        racecraft: 81,
        experience: 62,
      ),

      // Haas Team
      Driver(
        name: "Esteban Ocon",
        abbreviation: "OCO", // F1 official abbreviation
        team: TeamData.getTeamByName("Haas"),
        speed: 80,
        consistency: 87,
        tyreManagementSkill: 84,
        racecraft: 82,
        experience: 86,
      ),
      Driver(
        name: "Oliver Bearman",
        abbreviation: "BEA", // New driver - logical abbreviation
        team: TeamData.getTeamByName("Haas"),
        speed: 81,
        consistency: 76,
        tyreManagementSkill: 74,
        racecraft: 79,
        experience: 58,
      ),

      // Racing Bulls Team
      Driver(
        name: "Liam Lawson",
        abbreviation: "LAW", // New driver - logical abbreviation
        team: TeamData.getTeamByName("Racing Bulls"),
        speed: 85,
        consistency: 81,
        tyreManagementSkill: 79,
        racecraft: 83,
        experience: 70,
      ),
      Driver(
        name: "Isack Hadjar",
        abbreviation: "HAD", // New driver - logical abbreviation
        team: TeamData.getTeamByName("Racing Bulls"),
        speed: 78,
        consistency: 74,
        tyreManagementSkill: 72,
        racecraft: 77,
        experience: 55,
      ),

      // Williams Team
      Driver(
        name: "Alex Albon",
        abbreviation: "ALB", // F1 official abbreviation
        team: TeamData.getTeamByName("Williams"),
        speed: 84,
        consistency: 88,
        tyreManagementSkill: 83,
        racecraft: 80,
        experience: 82,
      ),
      Driver(
        name: "Carlos Sainz",
        abbreviation: "SAI", // F1 official abbreviation
        team: TeamData.getTeamByName("Williams"),
        speed: 87,
        consistency: 89,
        tyreManagementSkill: 86,
        racecraft: 85,
        experience: 88,
      ),

      // Sauber Team
      Driver(
        name: "Nico Hulkenberg",
        abbreviation: "HUL", // F1 official abbreviation
        team: TeamData.getTeamByName("Sauber"),
        speed: 82,
        consistency: 92,
        tyreManagementSkill: 88,
        racecraft: 84,
        experience: 94,
      ),
      Driver(
        name: "Gabriel Bortoleto",
        abbreviation: "BOR", // New driver - logical abbreviation
        team: TeamData.getTeamByName("Sauber"),
        speed: 80,
        consistency: 77,
        tyreManagementSkill: 75,
        racecraft: 78,
        experience: 56,
      ),
    ];
  }

// Add method to create rookie driver with abbreviation
  static Driver createRookieDriver() {
    return Driver(
      name: "Rookie",
      abbreviation: "YOU", // Special abbreviation for user
      team: TeamData.getTeamByName("Williams"),
      speed: 70,
      consistency: 65,
      tyreManagementSkill: 68,
      racecraft: 72,
      experience: 55,
    );
  }

  /// Creates a custom driver with specified attributes
  static Driver createCustomDriver({
    required String name,
    required String abbreviation,
    required String teamName, // CHANGED: Now takes team name string
    required int speed,
    required int consistency,
    required int tyreManagementSkill,
    required int racecraft, // NEW
    required int experience, // NEW
  }) {
    return Driver(
      name: name,
      abbreviation: abbreviation,
      team: TeamData.getTeamByName(teamName), // CHANGED: Gets Team object
      speed: speed,
      consistency: consistency,
      tyreManagementSkill: tyreManagementSkill,
      racecraft: racecraft, // NEW
      experience: experience, // NEW
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
      "GOAT (Hamilton/Verstappen level)": DriverSkillPreset(
        speed: 97,
        consistency: 95,
        tyreManagementSkill: 95,
        racecraft: 97,
        experience: 96,
        description: "Greatest of all time - elite in every category",
      ),
      "Elite Champion": DriverSkillPreset(
        speed: 92,
        consistency: 90,
        tyreManagementSkill: 88,
        racecraft: 90,
        experience: 85,
        description: "Championship-caliber driver, elite skills",
      ),
      "Veteran Expert": DriverSkillPreset(
        speed: 85,
        consistency: 92,
        tyreManagementSkill: 90,
        racecraft: 88,
        experience: 94,
        description: "Experienced driver with supreme consistency",
      ),
      "Rising Star": DriverSkillPreset(
        speed: 88,
        consistency: 82,
        tyreManagementSkill: 80,
        racecraft: 85,
        experience: 72,
        description: "Fast young talent, still developing",
      ),
      "Promising Rookie": DriverSkillPreset(
        speed: 80,
        consistency: 75,
        tyreManagementSkill: 72,
        racecraft: 78,
        experience: 58,
        description: "F1 rookie with potential, learning the ropes",
      ),
      "Solid Midfield": DriverSkillPreset(
        speed: 82,
        consistency: 85,
        tyreManagementSkill: 83,
        racecraft: 81,
        experience: 84,
        description: "Reliable points scorer, consistent performer",
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
        driver.racecraft >= 50 && // NEW
        driver.racecraft <= 100 && // NEW
        driver.experience >= 50 && // NEW
        driver.experience <= 100 && // NEW
        driver.team.carPerformance >= 70 && // CHANGED: Now uses team.carPerformance
        driver.team.carPerformance <= 100 && // CHANGED
        driver.team.reliability >= 70 && // CHANGED: Now uses team.reliability
        driver.team.reliability <= 100; // CHANGED
  }

  /// Gets performance tier for a driver based on overall stats
  /// Gets performance tier for a driver based on overall stats
  static String getDriverPerformanceTier(Driver driver) {
    double overallRating =
        (driver.speed + driver.consistency + driver.tyreManagementSkill + driver.racecraft + driver.experience) / 5.0;

    if (overallRating >= 95) return "GOAT";
    if (overallRating >= 90) return "Elite";
    if (overallRating >= 85) return "Top Tier";
    if (overallRating >= 80) return "Solid";
    if (overallRating >= 75) return "Promising";
    if (overallRating >= 70) return "Developing";
    if (overallRating >= 65) return "Rookie";
    return "Struggling";
  }

  /// Gets car performance tier for a driver
  static String getCarPerformanceTier(Driver driver) {
    if (driver.team.carPerformance >= 95) return "Championship Contender";
    if (driver.team.carPerformance >= 88) return "Regular Points Scorer";
    if (driver.team.carPerformance >= 80) return "Midfield Runner";
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
/// Driver skill preset for easy driver creation
class DriverSkillPreset {
  final int speed;
  final int consistency;
  final int tyreManagementSkill;
  final int racecraft; // NEW
  final int experience; // NEW
  final String description;

  DriverSkillPreset({
    required this.speed,
    required this.consistency,
    required this.tyreManagementSkill,
    required this.racecraft, // NEW
    required this.experience, // NEW
    required this.description,
  });
}
