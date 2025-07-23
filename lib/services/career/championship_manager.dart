// lib/services/career/championship_manager.dart
import 'package:flutter/material.dart';

import '../../models/driver.dart';
import '../../models/career/career_driver.dart';
import '../../data/driver_data.dart';
import '../../data/team_data.dart';

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

  // Initialize championship with all F1 drivers
  static void initializeChampionship() {
    debugPrint("=== INITIALIZING CHAMPIONSHIP ===");

    // Reset all standings
    _driverPoints.clear();
    _driverWins.clear();
    _driverPodiums.clear();
    _driverTeams.clear();

    // Get all F1 drivers and initialize their standings
    List<Driver> allDrivers = DriverData.createDefaultDrivers();

    for (Driver driver in allDrivers) {
      _driverPoints[driver.name] = 0;
      _driverWins[driver.name] = 0;
      _driverPodiums[driver.name] = 0;
      _driverTeams[driver.name] = driver.team.name;
    }

    debugPrint("✅ Championship initialized with ${allDrivers.length} drivers");
  }

  // Update standings after a race
  static void updateRaceResults(List<Driver> raceResults) {
    debugPrint("=== UPDATING CHAMPIONSHIP STANDINGS ===");

    const pointsSystem = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];

    for (Driver driver in raceResults) {
      if (driver.isDNF()) continue;

      int position = driver.position;
      int points = (position <= pointsSystem.length) ? pointsSystem[position - 1] : 0;

      // Update points
      _driverPoints[driver.name] = (_driverPoints[driver.name] ?? 0) + points;

      // Update wins
      if (position == 1) {
        _driverWins[driver.name] = (_driverWins[driver.name] ?? 0) + 1;
      }

      // Update podiums
      if (position <= 3) {
        _driverPodiums[driver.name] = (_driverPodiums[driver.name] ?? 0) + 1;
      }

      // Update team info
      _driverTeams[driver.name] = driver.team.name;

      debugPrint("${driver.name}: P$position, +$points pts (Total: ${_driverPoints[driver.name]})");
    }

    debugPrint("✅ Championship standings updated");
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
