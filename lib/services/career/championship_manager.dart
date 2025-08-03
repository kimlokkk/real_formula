// lib/services/career/championship_manager.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/driver.dart';
import '../../data/driver_data.dart';

class ChampionshipStanding {
  final String driverName;
  final String teamName;
  final int points;
  final int wins;
  final int podiums;
  final bool isCareerDriver;

  ChampionshipStanding({
    required this.driverName,
    required this.teamName,
    required this.points,
    required this.wins,
    required this.podiums,
    this.isCareerDriver = false,
  });
}

class ChampionshipManager {
  static Map<String, int> _driverPoints = {};
  static Map<String, int> _driverWins = {};
  static Map<String, int> _driverPodiums = {};
  static Map<String, String> _driverTeams = {};

  // ✅ NEW: Check if championship is properly initialized
  static bool isInitialized() {
    return _driverPoints.isNotEmpty && _driverTeams.isNotEmpty;
  }

  /// ✅ NEW: Safe initialization - only initialize if not already done
  static void ensureInitialized() {
    if (!isInitialized()) {
      debugPrint("⚠️ Championship not initialized - initializing now");
      initializeChampionship();
    } else {
      debugPrint("✅ Championship already initialized with ${_driverPoints.length} drivers");
    }
  }

  /// ✅ ENHANCED: Safer race results update with validation
  static void updateRaceResults(List<Driver> raceResults) {
    if (raceResults.isEmpty) {
      debugPrint("⚠️ No race results provided to update championship");
      return;
    }

    debugPrint("=== UPDATING CHAMPIONSHIP STANDINGS ===");
    debugPrint("Processing ${raceResults.length} drivers");

    // Ensure championship is initialized before updating
    ensureInitialized();

    const pointsSystem = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];
    int updatedDrivers = 0;

    for (Driver driver in raceResults) {
      if (driver.isDNF()) {
        debugPrint("${driver.name}: DNF - no points awarded");
        continue;
      }

      int position = driver.position;
      int points = (position <= pointsSystem.length) ? pointsSystem[position - 1] : 0;

      // Initialize driver if not in championship (shouldn't happen, but safety check)
      if (!_driverPoints.containsKey(driver.name)) {
        debugPrint("⚠️ Driver ${driver.name} not in championship - adding now");
        _driverPoints[driver.name] = 0;
        _driverWins[driver.name] = 0;
        _driverPodiums[driver.name] = 0;
        _driverTeams[driver.name] = driver.team.name;
      }

      // Store previous values for logging
      int previousPoints = _driverPoints[driver.name]!;
      int previousWins = _driverWins[driver.name]!;
      int previousPodiums = _driverPodiums[driver.name]!;

      // Update points
      _driverPoints[driver.name] = previousPoints + points;

      // Update wins
      if (position == 1) {
        _driverWins[driver.name] = previousWins + 1;
      }

      // Update podiums
      if (position <= 3) {
        _driverPodiums[driver.name] = previousPodiums + 1;
      }

      // Update team info
      _driverTeams[driver.name] = driver.team.name;

      debugPrint("${driver.name}: P$position, +$points pts (${previousPoints} → ${_driverPoints[driver.name]})");
      updatedDrivers++;
    }

    debugPrint("✅ Championship standings updated for $updatedDrivers drivers");
  }

  /// ✅ NEW: Get detailed championship statistics
  static Map<String, dynamic> getChampionshipStats() {
    List<ChampionshipStanding> standings = getCurrentStandings();

    if (standings.isEmpty) {
      return {
        'totalDrivers': 0,
        'totalPoints': 0,
        'leader': null,
        'raceCount': 0,
      };
    }

    int totalPoints = standings.fold(0, (sum, standing) => sum + standing.points);
    int totalWins = standings.fold(0, (sum, standing) => sum + standing.wins);

    // Estimate races completed based on leader's points
    // (rough estimate: top drivers average ~15 points per race)
    int estimatedRaces = standings.first.points > 0 ? (standings.first.points / 15).ceil() : 0;

    return {
      'totalDrivers': standings.length,
      'totalPoints': totalPoints,
      'totalWins': totalWins,
      'leader': standings.first.driverName,
      'leaderPoints': standings.first.points,
      'estimatedRaces': estimatedRaces,
    };
  }

  /// ✅ NEW: Validate championship data integrity
  static bool validateChampionshipData() {
    bool isValid = true;
    List<String> issues = [];

    Set<String> pointsKeys = _driverPoints.keys.toSet();
    Set<String> winsKeys = _driverWins.keys.toSet();
    Set<String> podiumsKeys = _driverPodiums.keys.toSet();
    Set<String> teamsKeys = _driverTeams.keys.toSet();

    if (!setEquals(pointsKeys, winsKeys) || !setEquals(pointsKeys, podiumsKeys) || !setEquals(pointsKeys, teamsKeys)) {
      issues.add("Inconsistent driver data across maps");
      isValid = false;
    }

    for (String driver in pointsKeys) {
      if ((_driverPoints[driver] ?? 0) < 0) {
        issues.add("Negative points for $driver");
        isValid = false;
      }
      if ((_driverWins[driver] ?? 0) < 0) {
        issues.add("Negative wins for $driver");
        isValid = false;
      }
      if ((_driverPodiums[driver] ?? 0) < 0) {
        issues.add("Negative podiums for $driver");
        isValid = false;
      }
    }

    if (!isValid) {
      debugPrint("❌ Championship data validation failed:");
      for (String issue in issues) {
        debugPrint("   - $issue");
      }
    }

    return isValid;
  }

  // NEW: Reset championship - ONLY NEW METHOD ADDED
  static void resetChampionship() {
    debugPrint("=== RESETTING CHAMPIONSHIP ===");
    _driverPoints.clear();
    _driverWins.clear();
    _driverPodiums.clear();
    _driverTeams.clear();
    debugPrint("✅ Championship reset - all data cleared");
  }

  static void initializeChampionship({List<Driver>? seasonDrivers}) {
    debugPrint("=== INITIALIZING CHAMPIONSHIP ===");

    // Reset all standings
    _driverPoints.clear();
    _driverWins.clear();
    _driverPodiums.clear();
    _driverTeams.clear();

    // Use provided season drivers or fall back to default
    List<Driver> driversToInitialize;

    if (seasonDrivers != null && seasonDrivers.isNotEmpty) {
      driversToInitialize = seasonDrivers;
      debugPrint("✅ Using provided season drivers (${seasonDrivers.length} drivers)");
    } else {
      // Fallback to default drivers (for non-career mode)
      driversToInitialize = DriverData.createDefaultDrivers();
      debugPrint("⚠️ Fallback: Using default F1 drivers (${driversToInitialize.length} drivers)");
    }

    // Initialize championship standings for each driver
    for (Driver driver in driversToInitialize) {
      _driverPoints[driver.name] = 0;
      _driverWins[driver.name] = 0;
      _driverPodiums[driver.name] = 0;
      _driverTeams[driver.name] = driver.team.name;

      debugPrint("   Initialized: ${driver.name} (${driver.team.name})");
    }

    debugPrint("✅ Championship initialized with ${driversToInitialize.length} drivers");
  }

  // Get current championship standings
  static List<ChampionshipStanding> getCurrentStandings({String? careerDriverName}) {
    List<ChampionshipStanding> standings = [];

    _driverPoints.forEach((driverName, points) {
      standings.add(ChampionshipStanding(
        driverName: driverName,
        teamName: _driverTeams[driverName] ?? 'Unknown',
        points: points,
        wins: _driverWins[driverName] ?? 0,
        podiums: _driverPodiums[driverName] ?? 0,
        isCareerDriver: driverName == careerDriverName,
      ));
    });

    // Sort by points (then by wins as tiebreaker)
    standings.sort((a, b) {
      if (a.points != b.points) return b.points.compareTo(a.points);
      return b.wins.compareTo(a.wins);
    });

    return standings;
  }

  // Get career driver's championship position
  static int getCareerDriverPosition(String careerDriverName) {
    List<ChampionshipStanding> standings = getCurrentStandings();

    for (int i = 0; i < standings.length; i++) {
      if (standings[i].driverName == careerDriverName) {
        return i + 1; // Position is 1-indexed
      }
    }

    return standings.length; // Last place if not found
  }

  // Get championship leader
  static ChampionshipStanding? getChampionshipLeader() {
    List<ChampionshipStanding> standings = getCurrentStandings();
    return standings.isNotEmpty ? standings.first : null;
  }

  // Get top 5 standings for quick display
  static List<ChampionshipStanding> getTop5Standings({String? careerDriverName}) {
    List<ChampionshipStanding> allStandings = getCurrentStandings(careerDriverName: careerDriverName);

    // Always include career driver even if not in top 5
    List<ChampionshipStanding> top5 = allStandings.take(5).toList();

    if (careerDriverName != null) {
      bool careerDriverInTop5 = top5.any((s) => s.driverName == careerDriverName);
      if (!careerDriverInTop5) {
        ChampionshipStanding? careerStanding = allStandings.firstWhere(
          (s) => s.driverName == careerDriverName,
          orElse: () => ChampionshipStanding(
            driverName: careerDriverName,
            teamName: 'Unknown',
            points: 0,
            wins: 0,
            podiums: 0,
            isCareerDriver: true,
          ),
        );

        // Replace 5th place with career driver
        if (top5.length == 5) {
          top5[4] = careerStanding;
        } else {
          top5.add(careerStanding);
        }
      }
    }

    return top5;
  }

  // Save/Load functionality (basic)
  static Map<String, dynamic> toJson() {
    return {
      'driverPoints': _driverPoints,
      'driverWins': _driverWins,
      'driverPodiums': _driverPodiums,
      'driverTeams': _driverTeams,
    };
  }

  static void fromJson(Map<String, dynamic> json) {
    _driverPoints = Map<String, int>.from(json['driverPoints'] ?? {});
    _driverWins = Map<String, int>.from(json['driverWins'] ?? {});
    _driverPodiums = Map<String, int>.from(json['driverPodiums'] ?? {});
    _driverTeams = Map<String, String>.from(json['driverTeams'] ?? {});
  }
}
