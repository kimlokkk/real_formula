// lib/models/career/career_driver.dart
import '../driver.dart';
import '../team.dart';
import 'contract.dart';

class CareerDriver extends Driver {
  // Career progression
  int experiencePoints;
  int totalCareerXP;

  // Career statistics
  int careerWins;
  int careerPodiums;
  int careerPoles;
  int careerPoints;
  int careerRaces;
  int seasonsCompleted;

  // Current season stats
  int currentSeasonWins;
  int currentSeasonPodiums;
  int currentSeasonPoles;
  int currentSeasonPoints;

  // Career management
  Contract? currentContract;
  Map<String, int> teamReputation; // Team name -> reputation (0-100)
  DateTime careerStartDate;

  // Constructor
  CareerDriver({
    required super.name,
    required super.abbreviation,
    required super.team,
    required super.speed,
    required super.consistency,
    required super.tyreManagementSkill,
    required super.racecraft,
    required super.experience,
    this.experiencePoints = 0,
    this.totalCareerXP = 0,
    this.careerWins = 0,
    this.careerPodiums = 0,
    this.careerPoles = 0,
    this.careerPoints = 0,
    this.careerRaces = 0,
    this.seasonsCompleted = 0,
    this.currentSeasonWins = 0,
    this.currentSeasonPodiums = 0,
    this.currentSeasonPoles = 0,
    this.currentSeasonPoints = 0,
    this.currentContract,
    Map<String, int>? teamReputation,
    DateTime? careerStartDate,
  })  : teamReputation = teamReputation ?? {},
        careerStartDate = careerStartDate ?? DateTime.now();

  // Factory constructor for creating new career driver
  factory CareerDriver.createNew({
    required String name,
    required String abbreviation,
    required Team startingTeam,
  }) {
    return CareerDriver(
      name: name,
      abbreviation: abbreviation,
      team: startingTeam,
      // All stats start at 70 as planned
      speed: 70,
      consistency: 70,
      tyreManagementSkill: 70,
      racecraft: 70,
      experience: 70,
      // Initialize team reputation (neutral with all teams)
      teamReputation: _initializeTeamReputation(),
    );
  }

  // Initialize neutral reputation with all teams
  static Map<String, int> _initializeTeamReputation() {
    return {
      "McLaren": 50,
      "Red Bull": 50,
      "Ferrari": 50,
      "Mercedes": 50,
      "Aston Martin": 50,
      "Alpine": 50,
      "Haas": 50,
      "Racing Bulls": 50,
      "Williams": 50,
      "Sauber": 50,
    };
  }

  // XP and skill upgrade methods
  void addExperiencePoints(int xp) {
    experiencePoints += xp;
    totalCareerXP += xp;
  }

  // Calculate cost to upgrade a skill
  int getUpgradeCost(int currentSkillLevel) {
    if (currentSkillLevel < 80) {
      return 100; // 70-79 costs 100 XP
    } else if (currentSkillLevel < 90) {
      return 150; // 80-89 costs 150 XP
    } else {
      return 200; // 90-99 costs 200 XP
    }
  }

  // Check if player can afford skill upgrade
  bool canUpgradeSkill(int currentSkillLevel) {
    if (currentSkillLevel >= 99) return false;
    return experiencePoints >= getUpgradeCost(currentSkillLevel);
  }

  // Upgrade specific skills
  bool upgradeSpeed() {
    if (canUpgradeSkill(speed)) {
      int cost = getUpgradeCost(speed);
      experiencePoints -= cost;
      speed++;
      return true;
    }
    return false;
  }

  bool upgradeConsistency() {
    if (canUpgradeSkill(consistency)) {
      int cost = getUpgradeCost(consistency);
      experiencePoints -= cost;
      consistency++;
      return true;
    }
    return false;
  }

  bool upgradeTyreManagement() {
    if (canUpgradeSkill(tyreManagementSkill)) {
      int cost = getUpgradeCost(tyreManagementSkill);
      experiencePoints -= cost;
      tyreManagementSkill++;
      return true;
    }
    return false;
  }

  bool upgradeRacecraft() {
    if (canUpgradeSkill(racecraft)) {
      int cost = getUpgradeCost(racecraft);
      experiencePoints -= cost;
      racecraft++;
      return true;
    }
    return false;
  }

  bool upgradeExperience() {
    if (canUpgradeSkill(experience)) {
      int cost = getUpgradeCost(experience);
      experiencePoints -= cost;
      experience++;
      return true;
    }
    return false;
  }

  // Career statistics methods
  void recordRaceResult({
    required int position,
    required int points,
    required bool polePosition,
    required bool fastestLap,
  }) {
    careerRaces++;

    // Add championship points
    careerPoints += points;
    currentSeasonPoints += points;

    // Check for wins and podiums
    if (position == 1) {
      careerWins++;
      currentSeasonWins++;
    }

    if (position <= 3) {
      careerPodiums++;
      currentSeasonPodiums++;
    }

    if (polePosition) {
      careerPoles++;
      currentSeasonPoles++;
    }

    // Award XP based on performance
    int xpEarned = _calculateRaceXP(position, points, polePosition, fastestLap);
    addExperiencePoints(xpEarned);
  }

  // Calculate XP earned from race performance
  int _calculateRaceXP(int position, int points, bool pole, bool fastestLap) {
    int baseXP = 0;

    // Position-based XP
    if (position == 1)
      baseXP = 50;
    else if (position <= 3)
      baseXP = 35;
    else if (position <= 6)
      baseXP = 25;
    else if (position <= 10)
      baseXP = 15;
    else
      baseXP = 10;

    // Bonus XP
    if (pole) baseXP += 20;
    if (fastestLap) baseXP += 15;
    if (points > 0) baseXP += 10; // Bonus for scoring points

    return baseXP;
  }

  // Team reputation methods
  int getTeamReputation(String teamName) {
    return teamReputation[teamName] ?? 50;
  }

  void updateTeamReputation(String teamName, int change) {
    int currentRep = getTeamReputation(teamName);
    teamReputation[teamName] = (currentRep + change).clamp(0, 100);
  }

  // Season management
  void startNewSeason() {
    seasonsCompleted++;
    currentSeasonWins = 0;
    currentSeasonPodiums = 0;
    currentSeasonPoles = 0;
    currentSeasonPoints = 0;
  }

  // Career summary getters
  double get averagePointsPerSeason {
    if (seasonsCompleted == 0) return 0.0;
    return careerPoints / seasonsCompleted;
  }

  double get winPercentage {
    if (careerRaces == 0) return 0.0;
    return (careerWins / careerRaces) * 100;
  }

  double get podiumPercentage {
    if (careerRaces == 0) return 0.0;
    return (careerPodiums / careerRaces) * 100;
  }

  // Overall career rating (0-100)
  double get careerRating {
    double skillAverage = (speed + consistency + tyreManagementSkill + racecraft + experience) / 5.0;

    // Boost based on achievements (max +15)
    double achievementBonus = 0;
    if (careerWins > 0) achievementBonus += (careerWins * 0.5).clamp(0, 5);
    if (careerPodiums > 0) achievementBonus += (careerPodiums * 0.2).clamp(0, 5);
    if (careerPoles > 0) achievementBonus += (careerPoles * 0.3).clamp(0, 5);

    return (skillAverage + achievementBonus).clamp(0, 100);
  }

  // Convert to/from JSON for save system
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'teamName': team.name,
      'speed': speed,
      'consistency': consistency,
      'tyreManagementSkill': tyreManagementSkill,
      'racecraft': racecraft,
      'experience': experience,
      'experiencePoints': experiencePoints,
      'totalCareerXP': totalCareerXP,
      'careerWins': careerWins,
      'careerPodiums': careerPodiums,
      'careerPoles': careerPoles,
      'careerPoints': careerPoints,
      'careerRaces': careerRaces,
      'seasonsCompleted': seasonsCompleted,
      'currentSeasonWins': currentSeasonWins,
      'currentSeasonPodiums': currentSeasonPodiums,
      'currentSeasonPoles': currentSeasonPoles,
      'currentSeasonPoints': currentSeasonPoints,
      'teamReputation': teamReputation,
      'careerStartDate': careerStartDate.toIso8601String(),
      'currentContract': currentContract?.toJson(),
    };
  }

  // Create CareerDriver from JSON
  static CareerDriver fromJson(Map<String, dynamic> json, Team team) {
    return CareerDriver(
      name: json['name'],
      abbreviation: json['abbreviation'],
      team: team,
      speed: json['speed'],
      consistency: json['consistency'],
      tyreManagementSkill: json['tyreManagementSkill'],
      racecraft: json['racecraft'],
      experience: json['experience'],
      experiencePoints: json['experiencePoints'] ?? 0,
      totalCareerXP: json['totalCareerXP'] ?? 0,
      careerWins: json['careerWins'] ?? 0,
      careerPodiums: json['careerPodiums'] ?? 0,
      careerPoles: json['careerPoles'] ?? 0,
      careerPoints: json['careerPoints'] ?? 0,
      careerRaces: json['careerRaces'] ?? 0,
      seasonsCompleted: json['seasonsCompleted'] ?? 0,
      currentSeasonWins: json['currentSeasonWins'] ?? 0,
      currentSeasonPodiums: json['currentSeasonPodiums'] ?? 0,
      currentSeasonPoles: json['currentSeasonPoles'] ?? 0,
      currentSeasonPoints: json['currentSeasonPoints'] ?? 0,
      teamReputation: Map<String, int>.from(json['teamReputation'] ?? {}),
      careerStartDate: DateTime.parse(json['careerStartDate']),
      currentContract: json['currentContract'] != null ? Contract.fromJson(json['currentContract'], team) : null,
    );
  }

  @override
  String toString() {
    return 'CareerDriver(name: $name, team: ${team.name}, rating: ${careerRating.toStringAsFixed(1)}, wins: $careerWins)';
  }
}
