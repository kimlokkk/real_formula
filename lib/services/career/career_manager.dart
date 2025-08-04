// lib/services/career/career_manager.dart
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:real_formula/data/driver_data.dart';
import 'package:real_formula/models/career/race_weekend.dart';
import 'package:real_formula/services/career/career_calendar.dart';
import 'package:real_formula/services/career/championship_manager.dart';
import 'package:real_formula/services/career/save_manager.dart';

import '../../models/career/career_driver.dart';
import '../../models/career/contract.dart';
import '../../models/team.dart';
import '../../models/driver.dart';
import '../../data/team_data.dart';

class CareerManager {
  static CareerDriver? _currentCareerDriver;
  static int _currentSeason = 2025;
  static List<Driver> _currentSeasonDrivers = [];

  // Getters
  static CareerDriver? get currentCareerDriver => _currentCareerDriver;
  static int get currentSeason => _currentSeason;
  static List<Driver> get currentSeasonDrivers => _currentSeasonDrivers;

  // Initialize a new career
  static CareerDriver startNewCareer({
    required String driverName,
    required String abbreviation,
    required Team startingTeam,
    Map<String, int>? initialSkillDistribution,
  }) {
    // Create new career driver (this now generates a unique career ID)
    _currentCareerDriver = CareerDriver.createNew(
      name: driverName,
      abbreviation: abbreviation,
      startingTeam: startingTeam,
    );

    debugPrint("🆕 Created new career with ID: ${_currentCareerDriver!.careerId}");

    // Apply initial skill points (50 points to distribute)
    if (initialSkillDistribution != null) {
      _applyInitialSkillPoints(initialSkillDistribution);
    }

    // Create initial contract (1 year with starting team)
    double initialSalary = _calculateInitialSalary(startingTeam);
    _currentCareerDriver!.currentContract = Contract(
      team: startingTeam,
      lengthInYears: 1,
      salaryPerYear: initialSalary,
      startYear: _currentSeason,
    );

    // Initialize season drivers (replace one AI driver with player)
    initializeNewCareer(_currentCareerDriver!, _currentSeason);

    debugPrint("✅ New career started - ${_currentCareerDriver!.name} (ID: ${_currentCareerDriver!.careerId})");

    return _currentCareerDriver!;
  }

  // Apply initial skill point distribution (max 50 points)
  static void _applyInitialSkillPoints(Map<String, int> distribution) {
    if (_currentCareerDriver == null) return;

    int totalPoints = distribution.values.fold(0, (sum, points) => sum + points);
    if (totalPoints > 50) {
      throw Exception('Cannot distribute more than 50 initial skill points');
    }

    // Apply the points
    _currentCareerDriver!.speed += distribution['speed'] ?? 0;
    _currentCareerDriver!.consistency += distribution['consistency'] ?? 0;
    _currentCareerDriver!.tyreManagementSkill += distribution['tyreManagement'] ?? 0;
    _currentCareerDriver!.racecraft += distribution['racecraft'] ?? 0;
    _currentCareerDriver!.experience += distribution['experience'] ?? 0;

    // Ensure no stat goes above 99 or below 50
    _currentCareerDriver!.speed = _currentCareerDriver!.speed.clamp(50, 99);
    _currentCareerDriver!.consistency = _currentCareerDriver!.consistency.clamp(50, 99);
    _currentCareerDriver!.tyreManagementSkill = _currentCareerDriver!.tyreManagementSkill.clamp(50, 99);
    _currentCareerDriver!.racecraft = _currentCareerDriver!.racecraft.clamp(50, 99);
    _currentCareerDriver!.experience = _currentCareerDriver!.experience.clamp(50, 99);
  }

  // Calculate initial salary based on team tier
  static double _calculateInitialSalary(Team team) {
    // Lower tier teams pay less for rookies
    if (team.carPerformance >= 95) return 3.0; // Top teams: €3M
    if (team.carPerformance >= 88) return 2.0; // Good teams: €2M
    if (team.carPerformance >= 80) return 1.5; // Midfield: €1.5M
    return 1.0; // Backmarkers: €1M
  }

  // Process race result and update career statistics
  static void processRaceResult({
    required int position,
    required int championshipPoints,
    required bool polePosition,
    required bool fastestLap,
    required bool beatTeammate,
  }) {
    if (_currentCareerDriver == null) return;

    // Record the race result
    _currentCareerDriver!.recordRaceResult(
      position: position,
      points: championshipPoints,
      polePosition: polePosition,
      fastestLap: fastestLap,
    );

    // Additional XP for beating teammate
    if (beatTeammate) {
      _currentCareerDriver!.addExperiencePoints(15);
    }

    // Update team reputation based on performance
    _updateTeamReputation(position, championshipPoints, beatTeammate);
  }

  // Update team reputation based on race performance
  static void _updateTeamReputation(int position, int points, bool beatTeammate) {
    if (_currentCareerDriver == null) return;

    String currentTeam = _currentCareerDriver!.team.name;
    int reputationChange = 0;

    // Base reputation change based on result
    if (position == 1)
      reputationChange = 3;
    else if (position <= 3)
      reputationChange = 2;
    else if (position <= 6)
      reputationChange = 1;
    else if (position <= 10)
      reputationChange = 0;
    else
      reputationChange = -1;

    // Bonus for beating teammate
    if (beatTeammate) reputationChange += 1;

    // Apply reputation change
    _currentCareerDriver!.updateTeamReputation(currentTeam, reputationChange);
  }

  static void initializeNewCareer(CareerDriver careerDriver, int season) {
    debugPrint("=== INITIALIZING NEW CAREER ===");

    // 🔧 FIX: Force complete reset before starting new career
    resetCareer(); // This now clears championship too

    _currentCareerDriver = careerDriver;
    _currentSeason = season;

    // Initialize season drivers (replace one AI driver with player)
    _initializeSeasonDrivers();

    // 🔧 FIX: Initialize calendar for new careers
    debugPrint("📅 Initializing fresh calendar for new career");
    CareerCalendar.instance.initialize();

    // 🔧 FIX: Initialize fresh championship standings with season drivers
    debugPrint("🏆 Initializing fresh championship for new career");
    ChampionshipManager.initializeChampionship(seasonDrivers: _currentSeasonDrivers);

    debugPrint("✅ New career initialized completely fresh");
    debugPrint("   Driver: ${careerDriver.name} (ID: ${careerDriver.careerId})");
    debugPrint("   Season drivers: ${_currentSeasonDrivers.length}");
    debugPrint("   Championship drivers: ${ChampionshipManager.isInitialized()}");
  }

// 🔧 ADD this method to load existing careers without resetting calendar:
  static void loadCareerDriver(CareerDriver driver, int season) {
    _currentCareerDriver = driver;
    _currentSeason = season;

    debugPrint("✅ Career driver loaded - preserving existing calendar state");
    // Note: Don't call calendar.initialize() here as it would reset completed races
  }

// 🆕 NEW: Auto-save career progress after race completion
  static Future<void> _autoSaveCareerProgress() async {
    try {
      // Use the existing SaveManager to auto-save
      await SaveManager.autoSave();
      debugPrint("✅ Career auto-saved successfully");
    } catch (e) {
      debugPrint("❌ Auto-save failed: $e");
      throw Exception("Failed to save career progress: $e");
    }
  }

// 🆕 NEW: Update season-specific progress tracking
  static void _updateSeasonProgress() {
    if (_currentCareerDriver == null) return;

    try {
      // Check if season is complete (all 24 races done)
      int completedRaces = CareerCalendar.instance.getCompletedRaces().length;

      debugPrint("Season progress: $completedRaces/24 races completed");

      // If season is complete, prepare for next season
      if (completedRaces >= 24) {
        debugPrint("🏁 Season complete! Preparing for next season...");
        _prepareForNextSeason();
      }

      // Update any other season-specific data here
      // (e.g., contract renewals, team changes, etc.)
    } catch (e) {
      debugPrint("⚠️ Error updating season progress: $e");
      // Don't throw - this is not critical enough to fail the whole operation
    }
  }

// 🆕 NEW: Prepare for next season when current season is complete
  static void _prepareForNextSeason() {
    if (_currentCareerDriver == null) return;

    try {
      // This will be expanded later, but for now just log
      debugPrint("🎉 Congratulations on completing the season!");
      debugPrint(
          "Final season stats: ${_currentCareerDriver!.currentSeasonWins} wins, ${_currentCareerDriver!.currentSeasonPoints} points");

      // TODO: Add season-end processing:
      // - Check championship position
      // - Handle contract renewals
      // - Award season bonuses
      // - Generate season summary
    } catch (e) {
      debugPrint("⚠️ Error preparing for next season: $e");
    }
  }

  static bool _calculateTeammateBeaten(int position) {
    // Simple logic - in real implementation, compare with teammate position
    // For now, assume if in points (top 10), you beat teammate
    return position <= 10;
  }

  // Complete current season and prepare for next
  static void completeCurrentSeason() {
    if (_currentCareerDriver == null) return;

    // Update season statistics
    _currentCareerDriver!.startNewSeason();
    _currentSeason++;

    // Check contract status
    if (_currentCareerDriver!.currentContract?.isFinalYear(_currentSeason - 1) == true) {
      // Contract has expired, need new contract for next season
      _currentCareerDriver!.currentContract?.expire();
      _currentCareerDriver!.currentContract = null;
    }

    // Update AI drivers for next season (simplified)
    _updateAIDriversForNewSeason();
  }

  // Generate contract offers for the player
  static List<ContractOffer> generateContractOffers() {
    if (_currentCareerDriver == null) return [];

    List<ContractOffer> offers = [];
    DateTime expirationDate = DateTime.now().add(Duration(days: 30));

    // Go through each team and determine if they'll make an offer
    for (Team team in TeamData.teams) {
      int reputation = _currentCareerDriver!.getTeamReputation(team.name);

      // Check if team will make an offer (based on reputation and team needs)
      if (_willTeamMakeOffer(team, reputation)) {
        ContractOffer offer = _generateTeamOffer(team, reputation, expirationDate);
        offers.add(offer);
      }
    }

    // Sort offers by salary (best first)
    offers.sort((a, b) => b.salaryPerYear.compareTo(a.salaryPerYear));

    return offers;
  }

  // Determine if a team will make an offer
  static bool _willTeamMakeOffer(Team team, int reputation) {
    // Current team always makes an offer if reputation is decent
    if (team.name == _currentCareerDriver!.team.name && reputation >= 40) {
      return true;
    }

    // Other teams based on reputation and random factor
    double baseChance = 0.0;
    if (reputation >= 80)
      baseChance = 0.9;
    else if (reputation >= 60)
      baseChance = 0.7;
    else if (reputation >= 40)
      baseChance = 0.4;
    else if (reputation >= 20)
      baseChance = 0.2;
    else
      baseChance = 0.05;

    // Top teams are more selective
    if (team.carPerformance >= 95)
      baseChance *= 0.6;
    else if (team.carPerformance >= 88) baseChance *= 0.8;

    return Random().nextDouble() < baseChance;
  }

  // Generate a contract offer from a specific team
  static ContractOffer _generateTeamOffer(Team team, int reputation, DateTime expiration) {
    // Calculate salary based on team tier, reputation, and performance
    double baseSalary = _calculateOfferSalary(team, reputation);

    // Contract length (1-3 years)
    int length = _calculateContractLength(team, reputation);

    return ContractOffer(
      team: team,
      lengthInYears: length,
      salaryPerYear: baseSalary,
      forYear: _currentSeason,
      offerExpirationDate: expiration,
    );
  }

  // Calculate salary offer based on multiple factors
  static double _calculateOfferSalary(Team team, int reputation) {
    double baseSalary = 1.0; // Minimum €1M

    // Team tier affects base salary
    if (team.carPerformance >= 95)
      baseSalary = 8.0;
    else if (team.carPerformance >= 88)
      baseSalary = 5.0;
    else if (team.carPerformance >= 80)
      baseSalary = 3.0;
    else
      baseSalary = 1.5;

    // Reputation multiplier
    double reputationMultiplier = 0.5 + (reputation / 100.0); // 0.5x to 1.5x

    // Performance multiplier based on career stats
    double performanceMultiplier = 1.0;
    if (_currentCareerDriver!.careerWins > 0) performanceMultiplier += 0.3;
    if (_currentCareerDriver!.careerPodiums > 5) performanceMultiplier += 0.2;
    if (_currentCareerDriver!.careerRating > 85) performanceMultiplier += 0.2;

    // Apply multipliers
    double finalSalary = baseSalary * reputationMultiplier * performanceMultiplier;

    // Add some random variation (±20%)
    double variation = 0.8 + (Random().nextDouble() * 0.4);
    finalSalary *= variation;

    // Round to nearest 0.5M and cap at reasonable limits
    return ((finalSalary * 2).round() / 2).clamp(0.5, 40.0);
  }

  // Calculate contract length offer
  static int _calculateContractLength(Team team, int reputation) {
    // Higher reputation = longer contracts offered
    if (reputation >= 80) {
      return Random().nextBool() ? 3 : 2; // 2-3 years
    } else if (reputation >= 60) {
      return Random().nextBool() ? 2 : 1; // 1-2 years
    } else {
      return 1; // Only 1 year offers for low reputation
    }
  }

  // Accept a contract offer
  static bool acceptContractOffer(ContractOffer offer) {
    if (_currentCareerDriver == null || !offer.isValid) return false;

    // Accept the offer
    offer.accept();

    // Create new contract
    _currentCareerDriver!.currentContract = offer.toContract();

    // Update driver's team
    _currentCareerDriver!.team = offer.team;

    return true;
  }

  // Initialize drivers for current season
  static void _initializeSeasonDrivers() {
    if (_currentCareerDriver == null) return;

    debugPrint("=== INITIALIZING SEASON DRIVERS ===");

    // Get all default F1 drivers
    List<Driver> allF1Drivers = DriverData.createDefaultDrivers();

    // Find drivers from the same team as career driver
    List<Driver> teamMates =
        allF1Drivers.where((driver) => driver.team.name == _currentCareerDriver!.team.name).toList();

    Driver? driverToReplace;
    if (teamMates.isNotEmpty) {
      // Replace the first teammate
      driverToReplace = teamMates.first;
      allF1Drivers.removeWhere((driver) => driver.name == driverToReplace?.name);

      debugPrint(
          "🔄 Replacing ${driverToReplace.name} with ${_currentCareerDriver!.name} at ${_currentCareerDriver!.team.name}");
    } else {
      // Fallback: replace the last driver if no teammate found
      driverToReplace = allF1Drivers.removeLast();
      debugPrint("⚠️ No teammate found, replacing ${driverToReplace.name} with ${_currentCareerDriver!.name}");
    }

    // Create Driver version of career driver for season
    Driver careerDriverForSeason = Driver(
      name: _currentCareerDriver!.name,
      abbreviation: _currentCareerDriver!.abbreviation,
      team: _currentCareerDriver!.team,
      speed: _currentCareerDriver!.speed,
      consistency: _currentCareerDriver!.consistency,
      tyreManagementSkill: _currentCareerDriver!.tyreManagementSkill,
      racecraft: _currentCareerDriver!.racecraft,
      experience: _currentCareerDriver!.experience,
    );

    // Build final season drivers list
    _currentSeasonDrivers = [careerDriverForSeason];
    _currentSeasonDrivers.addAll(allF1Drivers);

    debugPrint("✅ Season drivers initialized: ${_currentSeasonDrivers.length} total drivers");
    debugPrint("   Career driver: ${_currentCareerDriver!.name} (${_currentCareerDriver!.team.name})");
    debugPrint("   Replaced: ${driverToReplace.name}");
  }

  // Update AI drivers for new season (simplified)
  static void _updateAIDriversForNewSeason() {
    // TODO: Implement AI driver aging, retirement, and new drivers
    // For now, this is a placeholder
  }

  // Check if player needs a new contract
  static bool needsNewContract() {
    if (_currentCareerDriver?.currentContract == null) return true;
    return !_currentCareerDriver!.currentContract!.isValidForYear(_currentSeason);
  }

  // Get career summary for display
  static Map<String, dynamic> getCareerSummary() {
    if (_currentCareerDriver == null) return {};

    return {
      'driverName': _currentCareerDriver!.name,
      'currentTeam': _currentCareerDriver!.team.name,
      'currentSeason': _currentSeason,
      'careerRating': _currentCareerDriver!.careerRating,
      'seasonsCompleted': _currentCareerDriver!.seasonsCompleted,
      'careerWins': _currentCareerDriver!.careerWins,
      'careerPodiums': _currentCareerDriver!.careerPodiums,
      'careerPoints': _currentCareerDriver!.careerPoints,
      'currentSeasonPoints': _currentCareerDriver!.currentSeasonPoints,
      'availableXP': _currentCareerDriver!.experiencePoints,
      'contractInfo': _currentCareerDriver!.currentContract?.contractSummary ?? 'No contract',
    };
  }

  static Future<void> completeRaceWeekend(
    RaceWeekend raceWeekend, {
    required int position,
    required int points,
    bool polePosition = false,
    bool fastestLap = false,
    List<Driver>? allRaceResults,
  }) async {
    if (_currentCareerDriver == null) {
      debugPrint("❌ ERROR: No career driver found for race completion");
      return;
    }

    debugPrint("=== COMPLETING RACE WEEKEND ===");
    debugPrint("Driver: ${_currentCareerDriver!.name}");
    debugPrint("Race: ${raceWeekend.name}");
    debugPrint("Position: P$position");
    debugPrint("Points: $points");

    try {
      // STEP 1: Process race results and update career statistics
      processRaceResult(
        position: position,
        championshipPoints: points,
        polePosition: polePosition,
        fastestLap: fastestLap,
        beatTeammate: _calculateTeammateBeaten(position),
      );

      debugPrint("✅ Career statistics updated");

      // STEP 2: Update championship standings with all race results
      if (allRaceResults != null && allRaceResults.isNotEmpty) {
        ChampionshipManager.updateRaceResults(allRaceResults);
        int championshipPosition = ChampionshipManager.getCareerDriverPosition(_currentCareerDriver!.name);
        debugPrint("✅ Championship updated - Career driver now P$championshipPosition");
      } else {
        debugPrint("⚠️ No race results provided for championship update");
      }

      // 🔧 FIX: Use the new markRaceAsCompleted method
      debugPrint("🔍 Marking race '${raceWeekend.name}' as completed in calendar...");
      CareerCalendar.instance.markRaceAsCompleted(raceWeekend.name);

      debugPrint("✅ Calendar advanced to next race");

      // STEP 4: Auto-save career progress (CRITICAL FOR PERSISTENCE)
      await _autoSaveCareerProgress();

      // STEP 5: Update any season-specific data
      _updateSeasonProgress();

      // 🔧 FIX: Add explicit delay and notification to ensure UI updates
      await Future.delayed(Duration(milliseconds: 100));
      // ignore: invalid_use_of_protected_member
      CareerCalendar.instance.notifyListeners();

      debugPrint("✅ Race weekend completion successful");
      debugPrint(
          "Updated totals: ${_currentCareerDriver!.careerWins} wins, ${_currentCareerDriver!.careerPoints} points");

      // 🔧 FIX: Log calendar state for debugging
      debugPrint("📅 Calendar state after completion:");
      debugPrint("   Completed races: ${CareerCalendar.instance.getCompletedRaces().length}");
      debugPrint("   Next race: ${CareerCalendar.instance.nextRaceWeekend?.name ?? 'None'}");
    } catch (e) {
      debugPrint("❌ ERROR during race weekend completion: $e");
      try {
        await _autoSaveCareerProgress();
        debugPrint("⚠️ Emergency save completed despite error");
      } catch (saveError) {
        debugPrint("❌ CRITICAL: Failed to save career progress: $saveError");
      }
      rethrow;
    }
  }

  // 🆕 ENHANCED: Load career from save data including championship
  static void loadCareer(Map<String, dynamic> saveData) {
    _currentSeason = saveData['currentSeason'] ?? 2025;

    // Load championship standings if available
    if (saveData.containsKey('championshipStandings')) {
      ChampionshipManager.fromJson(saveData['championshipStandings']);
      debugPrint("✅ Championship standings loaded from save");
    } else {
      // Initialize fresh championship if no saved data
      // First ensure we have season drivers
      if (_currentSeasonDrivers.isEmpty) {
        _initializeSeasonDrivers();
      }
      ChampionshipManager.initializeChampionship(seasonDrivers: _currentSeasonDrivers);
      debugPrint("✅ Fresh championship standings initialized with season drivers");
    }
  }

  // 🆕 ENHANCED: Save career data including championship standings
  static Map<String, dynamic> saveCareer() {
    return {
      'currentSeason': _currentSeason,
      'careerDriver': _currentCareerDriver?.toJson(),
      'currentSeasonDrivers': _currentSeasonDrivers.map((d) => d.name).toList(),
      'championshipStandings': ChampionshipManager.toJson(), // 🆕 NEW
    };
  }

  // Reset career (for starting new career)
  static void resetCareer() {
    debugPrint("=== RESETTING CAREER MANAGER ===");

    _currentCareerDriver = null;
    _currentSeason = 2025;
    _currentSeasonDrivers.clear();

    // 🔧 FIX: Reset championship data
    ChampionshipManager.resetChampionship();

    // 🔧 FIX: Reset calendar data too
    CareerCalendar.instance.forceReset();

    debugPrint("✅ Career manager reset - driver, season, championship, and calendar cleared");
  }

  // Add this public setter for current season
  static void setCurrentSeason(int season) {
    _currentSeason = season;
  }

  // Add this public setter for career driver
  static void setCurrentCareerDriver(CareerDriver? driver) {
    _currentCareerDriver = driver;
  }

  static void loadCareerWithChampionshipFix(Map<String, dynamic> saveData) {
    _currentSeason = saveData['currentSeason'] ?? 2025;

    // First ensure we have current season drivers (including career driver)
    if (_currentSeasonDrivers.isEmpty) {
      _initializeSeasonDrivers();
    }

    // Load championship standings if available
    if (saveData.containsKey('championshipStandings')) {
      Map<String, dynamic> championshipData = saveData['championshipStandings'];

      // 🔧 FIX: Re-initialize championship with current season drivers first
      ChampionshipManager.initializeChampionship(seasonDrivers: _currentSeasonDrivers);

      // 🔧 FIX: Then apply saved points only for drivers that exist in current season
      _applySavedChampionshipPoints(championshipData);

      debugPrint("✅ Championship standings loaded and synchronized with current season drivers");
    } else {
      // Initialize fresh championship if no saved data
      ChampionshipManager.initializeChampionship(seasonDrivers: _currentSeasonDrivers);
      debugPrint("✅ Fresh championship standings initialized with season drivers");
    }
  }

  static void _applySavedChampionshipPoints(Map<String, dynamic> savedChampionshipData) {
    try {
      Map<String, int> savedPoints = Map<String, int>.from(savedChampionshipData['driverPoints'] ?? {});
      Map<String, int> savedWins = Map<String, int>.from(savedChampionshipData['driverWins'] ?? {});
      Map<String, int> savedPodiums = Map<String, int>.from(savedChampionshipData['driverPodiums'] ?? {});

      debugPrint("🔧 Applying saved championship points...");

      // Get list of current season driver names
      Set<String> currentDriverNames = _currentSeasonDrivers.map((d) => d.name).toSet();

      // Apply saved points only for drivers that exist in current season
      for (String driverName in currentDriverNames) {
        if (savedPoints.containsKey(driverName)) {
          ChampionshipManager.setDriverPoints(driverName, savedPoints[driverName]!);
          ChampionshipManager.setDriverWins(driverName, savedWins[driverName] ?? 0);
          ChampionshipManager.setDriverPodiums(driverName, savedPodiums[driverName] ?? 0);

          debugPrint("   Applied for $driverName: ${savedPoints[driverName]} pts, ${savedWins[driverName] ?? 0} wins");
        }
      }

      debugPrint("✅ Championship points applied successfully");
    } catch (e) {
      debugPrint("❌ Error applying saved championship points: $e");
      // If error, championship is already initialized with 0 points for all drivers
    }
  }
}
