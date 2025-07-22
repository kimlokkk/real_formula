// lib/data/driver_data.dart - Clean version without debug logging

import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/enums.dart';
import 'team_data.dart';

class DriverData {
  /// Creates the default set of F1 drivers with realistic stats
  /// Creates the default set of F1 drivers with realistic stats (10 drivers for gameplay)
  static List<Driver> createDefaultDrivers() {
    return [
      // Mercedes Team (High reliability: 92)
      Driver(
        name: "Max Verstappen",
        team: TeamData.getTeamByName("Red Bull"),
        speed: 99, // Absolute elite pace
        consistency: 96, // Extremely consistent
        tyreManagementSkill: 94, // Excellent tire management
        racecraft: 97, // Outstanding wheel-to-wheel
        experience: 92, // Veteran with championships
      ),
      Driver(
        name: "Yuki Tsunoda",
        team: TeamData.getTeamByName("Red Bull"),
        speed: 82, // Good pace but not elite
        consistency: 78, // Sometimes inconsistent
        tyreManagementSkill: 80, // Decent tire management
        racecraft: 84, // Improving racecraft
        experience: 76, // Growing experience
      ),

      // FERRARI - Lewis Hamilton & Charles Leclerc
      Driver(
        name: "Lewis Hamilton",
        team: TeamData.getTeamByName("Ferrari"),
        speed: 95, // Still very fast at 40
        consistency: 94, // Legendary consistency
        tyreManagementSkill: 96, // Master of tire management
        racecraft: 98, // Greatest racer of all time
        experience: 100, // Maximum F1 experience
      ),
      Driver(
        name: "Charles Leclerc",
        team: TeamData.getTeamByName("Ferrari"),
        speed: 94, // Elite speed
        consistency: 84, // Sometimes makes mistakes under pressure
        tyreManagementSkill: 88, // Good tire management
        racecraft: 92, // Strong wheel-to-wheel
        experience: 84, // Good experience, still growing
      ),

      // MCLAREN - Lando Norris & Oscar Piastri
      Driver(
        name: "Lando Norris",
        team: TeamData.getTeamByName("McLaren"),
        speed: 92, // Very fast, elite level
        consistency: 88, // Generally consistent
        tyreManagementSkill: 90, // Excellent tire management
        racecraft: 89, // Strong in battles
        experience: 84, // Solid experience
      ),
      Driver(
        name: "Oscar Piastri",
        team: TeamData.getTeamByName("McLaren"),
        speed: 88, // Very promising pace
        consistency: 86, // Impressively consistent for rookie years
        tyreManagementSkill: 85, // Good natural tire feel
        racecraft: 87, // Learning but very promising
        experience: 72, // Still early in career
      ),

      // MERCEDES - George Russell & Andrea Kimi Antonelli
      Driver(
        name: "George Russell",
        team: TeamData.getTeamByName("Mercedes"),
        speed: 89, // Strong pace, not quite elite
        consistency: 91, // Very consistent
        tyreManagementSkill: 87, // Good tire management
        racecraft: 85, // Decent wheel-to-wheel
        experience: 80, // Building experience
      ),
      Driver(
        name: "Andrea Kimi Antonelli",
        team: TeamData.getTeamByName("Mercedes"),
        speed: 86, // Promising rookie pace
        consistency: 75, // Learning, some rookie mistakes expected
        tyreManagementSkill: 78, // Still learning F1 tires
        racecraft: 82, // Natural talent but inexperienced
        experience: 60, // F1 rookie
      ),

      // ASTON MARTIN - Fernando Alonso & Lance Stroll
      Driver(
        name: "Fernando Alonso",
        team: TeamData.getTeamByName("Aston Martin"),
        speed: 91, // Still incredibly fast at 43
        consistency: 95, // Master of consistency
        tyreManagementSkill: 95, // Tire whisperer
        racecraft: 96, // Legendary racecraft
        experience: 98, // One of the most experienced ever
      ),
      Driver(
        name: "Lance Stroll",
        team: TeamData.getTeamByName("Aston Martin"),
        speed: 75, // Decent pace but not elite
        consistency: 82, // Generally reliable
        tyreManagementSkill: 78, // Average tire management
        racecraft: 74, // Struggles in close battles
        experience: 82, // Good F1 experience
      ),

      // ALPINE - Pierre Gasly & Franco Colapinto
      Driver(
        name: "Pierre Gasly",
        team: TeamData.getTeamByName("Alpine"),
        speed: 84, // Good pace
        consistency: 85, // Generally consistent
        tyreManagementSkill: 82, // Decent tire management
        racecraft: 86, // Solid wheel-to-wheel
        experience: 86, // Good F1 experience
      ),
      Driver(
        name: "Franco Colapinto",
        team: TeamData.getTeamByName("Alpine"),
        speed: 83, // Impressive rookie pace
        consistency: 79, // Still learning but promising
        tyreManagementSkill: 76, // Learning F1 tire management
        racecraft: 81, // Good natural racing instincts
        experience: 62, // Very new to F1
      ),

      // HAAS - Esteban Ocon & Oliver Bearman
      Driver(
        name: "Esteban Ocon",
        team: TeamData.getTeamByName("Haas"),
        speed: 80, // Solid midfield pace
        consistency: 87, // Very consistent driver
        tyreManagementSkill: 84, // Good tire conservation
        racecraft: 82, // Decent in battles
        experience: 86, // Good F1 experience
      ),
      Driver(
        name: "Oliver Bearman",
        team: TeamData.getTeamByName("Haas"),
        speed: 81, // Promising pace for rookie
        consistency: 76, // Learning but showed promise
        tyreManagementSkill: 74, // Still developing
        racecraft: 79, // Good instincts, needs experience
        experience: 58, // F1 rookie
      ),

      // RACING BULLS - Liam Lawson & Isack Hadjar
      Driver(
        name: "Liam Lawson",
        team: TeamData.getTeamByName("Racing Bulls"),
        speed: 85, // Strong pace, Red Bull academy graduate
        consistency: 81, // Generally consistent
        tyreManagementSkill: 79, // Learning tire management
        racecraft: 83, // Good racing instincts
        experience: 70, // Limited F1 experience
      ),
      Driver(
        name: "Isack Hadjar",
        team: TeamData.getTeamByName("Racing Bulls"),
        speed: 78, // Promising rookie pace
        consistency: 74, // Rookie learning curve
        tyreManagementSkill: 72, // Still learning
        racecraft: 77, // Natural talent but inexperienced
        experience: 55, // F1 rookie
      ),

      // WILLIAMS - Alex Albon & Carlos Sainz
      Driver(
        name: "Alex Albon",
        team: TeamData.getTeamByName("Williams"),
        speed: 84, // Good pace, strong in difficult cars
        consistency: 88, // Very consistent and reliable
        tyreManagementSkill: 83, // Good tire management
        racecraft: 80, // Decent wheel-to-wheel
        experience: 82, // Good F1 experience
      ),
      Driver(
        name: "Carlos Sainz",
        team: TeamData.getTeamByName("Williams"),
        speed: 87, // Strong pace, proven race winner
        consistency: 89, // Very consistent driver
        tyreManagementSkill: 86, // Excellent tire management
        racecraft: 85, // Good in battles
        experience: 88, // Extensive F1 experience
      ),

      // SAUBER - Nico Hulkenberg & Gabriel Bortoleto
      Driver(
        name: "Nico Hulkenberg",
        team: TeamData.getTeamByName("Sauber"),
        speed: 82, // Solid pace, veteran quality
        consistency: 92, // Extremely consistent
        tyreManagementSkill: 88, // Excellent tire management
        racecraft: 84, // Good wheel-to-wheel
        experience: 94, // Veteran with extensive experience
      ),
      Driver(
        name: "Gabriel Bortoleto",
        team: TeamData.getTeamByName("Sauber"),
        speed: 80, // Promising F2 champion pace
        consistency: 77, // F2 champion shows good consistency
        tyreManagementSkill: 75, // Learning F1 tire management
        racecraft: 78, // F2 champion has good racing instincts
        experience: 56, // F1 rookie but F2 champion
      ),
    ];
  }

  /// Creates a custom driver with specified attributes
  /// Creates a custom driver with specified attributes
  static Driver createCustomDriver({
    required String name,
    required String teamName, // CHANGED: Now takes team name string
    required int speed,
    required int consistency,
    required int tyreManagementSkill,
    required int racecraft, // NEW
    required int experience, // NEW
  }) {
    return Driver(
      name: name,
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
