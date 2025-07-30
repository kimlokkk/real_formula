// lib/data/team_data.dart
import 'package:flutter/material.dart';
import '../models/team.dart';

class TeamData {
  /// All F1 teams for 2025 season with realistic performance ratings
  static List<Team> teams = [
    // McLaren - Current championship leader, excellent car and strategy
    const Team(
      name: "McLaren",
      fullName: "McLaren F1 Team",
      primaryColor: Colors.orange,
      secondaryColor: Colors.blue,
      carPerformance: 98, // Championship winning car
      reliability: 94, // Very reliable
      strategy: "balanced",
      engineSupplier: "Mercedes",
      pitStopSpeed: 1.1, // Fast pit crew
      headquarters: "Woking, UK",
    ),

    // Red Bull - Still very strong but not as dominant as 2021-2023
    const Team(
      name: "Red Bull",
      fullName: "Oracle Red Bull Racing",
      primaryColor: Colors.indigoAccent,
      secondaryColor: Colors.yellow,
      carPerformance: 96, // Still elite but slightly behind McLaren
      reliability: 92, // Good reliability
      strategy: "aggressive",
      engineSupplier: "Honda RBPT",
      pitStopSpeed: 1.2, // Excellent pit crew
      headquarters: "Milton Keynes, UK",
    ),

    // Ferrari - Strong car but strategic inconsistencies
    const Team(
      name: "Ferrari",
      fullName: "Scuderia Ferrari",
      primaryColor: Colors.red,
      secondaryColor: Colors.yellow,
      carPerformance: 94, // Fast car
      reliability: 86, // Some reliability concerns
      strategy: "aggressive",
      engineSupplier: "Ferrari",
      pitStopSpeed: 0.9, // Sometimes slow pit stops
      headquarters: "Maranello, Italy",
    ),

    // Mercedes - Recovering form, strong in 2025
    const Team(
      name: "Mercedes",
      fullName: "Mercedes-AMG PETRONAS F1 Team",
      primaryColor: Colors.teal,
      secondaryColor: Colors.grey,
      carPerformance: 91, // Good car, back in contention
      reliability: 96, // Excellent reliability
      strategy: "conservative",
      engineSupplier: "Mercedes",
      pitStopSpeed: 1.0, // Consistent pit stops
      headquarters: "Brackley, UK",
    ),

    // Aston Martin - Solid midfield performer
    const Team(
      name: "Aston Martin",
      fullName: "Aston Martin Aramco Cognizant F1 Team",
      primaryColor: Colors.green,
      secondaryColor: Colors.black,
      carPerformance: 84, // Competitive midfield car
      reliability: 88, // Decent reliability
      strategy: "balanced",
      engineSupplier: "Honda",
      pitStopSpeed: 1.0,
      headquarters: "Silverstone, UK",
    ),

    // Alpine - Midfield struggles but improving
    const Team(
      name: "Alpine",
      fullName: "BWT Alpine F1 Team",
      primaryColor: Colors.pink,
      secondaryColor: Colors.blue,
      carPerformance: 81, // Lower midfield
      reliability: 84, // Moderate reliability
      strategy: "aggressive",
      engineSupplier: "Renault",
      pitStopSpeed: 0.95,
      headquarters: "Enstone, UK",
    ),

    // Haas - Improved form with new drivers
    Team(
      name: "Haas",
      fullName: "MoneyGram Haas F1 Team",
      primaryColor: Colors.red[900]!,
      secondaryColor: Colors.red,
      carPerformance: 79, // Solid midfield car
      reliability: 82, // Improving reliability
      strategy: "balanced",
      engineSupplier: "Ferrari",
      pitStopSpeed: 0.9,
      headquarters: "Kannapolis, USA",
    ),

    // Racing Bulls (RB) - Solid junior team
    Team(
      name: "Racing Bulls",
      fullName: "Visa Cash App RB F1 Team",
      primaryColor: Colors.blue[600]!,
      secondaryColor: Colors.red,
      carPerformance: 77, // Decent midfield performance
      reliability: 86, // Good reliability
      strategy: "aggressive",
      engineSupplier: "Honda RBPT",
      pitStopSpeed: 1.05,
      headquarters: "Faenza, Italy",
    ),

    // Williams - Improved with Sainz but still struggling
    Team(
      name: "Williams",
      fullName: "Williams Racing",
      primaryColor: Colors.blue[300]!,
      secondaryColor: Colors.white,
      carPerformance: 75, // Lower midfield
      reliability: 88, // Good reliability
      strategy: "conservative",
      engineSupplier: "Mercedes",
      pitStopSpeed: 0.85,
      headquarters: "Grove, UK",
    ),

    // Sauber - Transitioning to Audi, struggling performance
    const Team(
      name: "Sauber",
      fullName: "Kick Sauber F1 Team",
      primaryColor: Colors.green,
      secondaryColor: Colors.white,
      carPerformance: 72, // Backmarker performance
      reliability: 80, // Moderate reliability in transition
      strategy: "conservative",
      engineSupplier: "Ferrari",
      pitStopSpeed: 0.8,
      headquarters: "Hinwil, Switzerland",
    ),
  ];

  /// Get team by name
  static Team getTeamByName(String name) {
    return teams.firstWhere(
      (team) => team.name == name,
      orElse: () => teams.last, // Default to Sauber if not found
    );
  }

  /// Get all team names
  static List<String> getTeamNames() {
    return teams.map((team) => team.name).toList();
  }

  /// Get teams sorted by performance
  static List<Team> getTeamsByPerformance() {
    List<Team> sortedTeams = List.from(teams);
    sortedTeams.sort((a, b) => b.carPerformance.compareTo(a.carPerformance));
    return sortedTeams;
  }

  /// Get teams sorted by reliability
  static List<Team> getTeamsByReliability() {
    List<Team> sortedTeams = List.from(teams);
    sortedTeams.sort((a, b) => b.reliability.compareTo(a.reliability));
    return sortedTeams;
  }

  /// Get championship contenders (performance >= 90)
  static List<Team> getChampionshipContenders() {
    return teams.where((team) => team.carPerformance >= 90).toList();
  }

  /// Get midfield teams (performance 80-89)
  static List<Team> getMidfieldTeams() {
    return teams
        .where((team) => team.carPerformance >= 80 && team.carPerformance < 90)
        .toList();
  }

  /// Get backmarker teams (performance < 80)
  static List<Team> getBackmarkerTeams() {
    return teams.where((team) => team.carPerformance < 80).toList();
  }

  /// Get team statistics for UI display
  static Map<String, dynamic> getTeamStatistics() {
    List<Team> sortedByPerformance = getTeamsByPerformance();

    return {
      'strongest': sortedByPerformance.first.name,
      'mostReliable': getTeamsByReliability().first.name,
      'averagePerformance':
          teams.fold(0, (sum, team) => sum + team.carPerformance) /
              teams.length,
      'averageReliability':
          teams.fold(0, (sum, team) => sum + team.reliability) / teams.length,
      'championshipContenders': getChampionshipContenders().length,
      'midfieldBattle': getMidfieldTeams().length,
      'strugglingTeams': getBackmarkerTeams().length,
    };
  }
}
