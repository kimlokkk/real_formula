// lib/models/driver.dart - Enhanced version with realistic tire degradation

import 'package:flutter/material.dart';
import 'dart:math';
import 'enums.dart';

class Driver {
  String name;
  String team;
  int speed;
  int consistency;
  int tyreManagementSkill;
  int carPerformance;
  int reliability;
  int lapsCompleted;
  int lapsOnCurrentTires;
  int pitStops;
  double totalTime;
  int position;
  int startingPosition;
  int positionChangeFromStart;
  List<int> positionHistory;
  Color teamColor;

  // Error and failure tracking
  int errorCount;
  int mechanicalIssuesCount;
  bool hasActiveMechanicalIssue;
  int mechanicalIssueLapsRemaining;
  String currentIssueDescription;
  List<String> raceIncidents;

  // Tire compound tracking
  TireCompound currentCompound;
  List<TireCompound> usedCompounds;

  Driver({
    required this.name,
    required this.team,
    required this.speed,
    required this.consistency,
    required this.tyreManagementSkill,
    required this.carPerformance,
    required this.reliability,
    required this.teamColor,
    this.lapsCompleted = 0,
    this.lapsOnCurrentTires = 0,
    this.pitStops = 0,
    this.totalTime = 0.0,
    this.position = 1,
    this.startingPosition = 1,
    this.positionChangeFromStart = 0,
    this.errorCount = 0,
    this.mechanicalIssuesCount = 0,
    this.hasActiveMechanicalIssue = false,
    this.mechanicalIssueLapsRemaining = 0,
    this.currentIssueDescription = "",
    this.currentCompound = TireCompound.medium,
  })  : positionHistory = [],
        raceIncidents = [],
        usedCompounds = [];

  // Basic info getters
  String get skillsInfo {
    return "SPD:$speed CON:$consistency TYR:$tyreManagementSkill";
  }

  String get degradationInfo {
    return "${currentCompound.icon} ${currentCompound.name} | Age: ${lapsOnCurrentTires} laps | Deg: +${calculateTyreDegradation().toStringAsFixed(2)}s | Pits: $pitStops";
  }

  String get statusInfo {
    List<String> statusList = [];

    if (hasActiveMechanicalIssue) {
      statusList.add("⚠️ ${currentIssueDescription} (${mechanicalIssueLapsRemaining} laps)");
    }

    if (errorCount > 0) {
      statusList.add("🔄 ${errorCount} error${errorCount > 1 ? 's' : ''}");
    }

    if (mechanicalIssuesCount > 0) {
      statusList.add("🔧 ${mechanicalIssuesCount} mechanical issue${mechanicalIssuesCount > 1 ? 's' : ''}");
    }

    return statusList.join(" | ");
  }

  /// Enhanced compound tracking info for UI
  String get compoundRuleInfo {
    List<TireCompound> dryCompoundsUsed = usedCompounds
        .where((compound) =>
            compound == TireCompound.soft || compound == TireCompound.medium || compound == TireCompound.hard)
        .toSet()
        .toList();

    // Add current compound if not already tracked and is dry
    if (!dryCompoundsUsed.contains(currentCompound) &&
        (currentCompound == TireCompound.soft ||
            currentCompound == TireCompound.medium ||
            currentCompound == TireCompound.hard)) {
      dryCompoundsUsed.add(currentCompound);
    }

    if (dryCompoundsUsed.length >= 2) {
      return "✅ Compound rule satisfied (${dryCompoundsUsed.length} compounds used)";
    } else if (dryCompoundsUsed.length == 1) {
      String usedCompound = dryCompoundsUsed.first.name;
      return "⚠️ Must use 2nd compound (only used $usedCompound)";
    } else {
      return "🔄 No dry compounds used yet";
    }
  }

  /// Gets compound history string for UI
  String get compoundHistoryInfo {
    if (usedCompounds.isEmpty) {
      return "No compounds used yet";
    }

    List<String> compoundStrings = [];
    for (int i = 0; i < usedCompounds.length; i++) {
      TireCompound compound = usedCompounds[i];
      compoundStrings.add("${compound.icon}${compound.name}");
    }

    return "Used: ${compoundStrings.join(" → ")}";
  }

  /// Checks if driver has satisfied the mandatory compound rule
  bool get hasUsedTwoCompounds {
    List<TireCompound> dryCompoundsUsed = usedCompounds
        .where((compound) =>
            compound == TireCompound.soft || compound == TireCompound.medium || compound == TireCompound.hard)
        .toSet()
        .toList();

    // Add current compound if not already tracked and is dry
    if (!dryCompoundsUsed.contains(currentCompound) &&
        (currentCompound == TireCompound.soft ||
            currentCompound == TireCompound.medium ||
            currentCompound == TireCompound.hard)) {
      dryCompoundsUsed.add(currentCompound);
    }

    return dryCompoundsUsed.length >= 2;
  }

  /// Gets remaining compounds that can be used
  List<TireCompound> get availableDryCompounds {
    List<TireCompound> allDryCompounds = [TireCompound.soft, TireCompound.medium, TireCompound.hard];

    List<TireCompound> dryCompoundsUsed =
        usedCompounds.where((compound) => allDryCompounds.contains(compound)).toSet().toList();

    // Add current compound if not already tracked
    if (!dryCompoundsUsed.contains(currentCompound) && allDryCompounds.contains(currentCompound)) {
      dryCompoundsUsed.add(currentCompound);
    }

    // If only used one compound type, must use different compounds
    if (dryCompoundsUsed.length == 1) {
      return allDryCompounds.where((compound) => !dryCompoundsUsed.contains(compound)).toList();
    }

    // If already used 2+ compounds, can use any
    return allDryCompounds;
  }

  // ENHANCED TIRE DEGRADATION CALCULATION - Much more aggressive and realistic
  double calculateTyreDegradation() {
    double factor = 0.0;

    // NEW: Much more aggressive progression with exponential late-stint penalty
    if (lapsOnCurrentTires <= 3) {
      factor = lapsOnCurrentTires * 0.005; // Minimal early wear (0-0.015s)
    } else if (lapsOnCurrentTires <= 10) {
      factor = 0.015 + ((lapsOnCurrentTires - 3) * 0.015); // Gentle increase (0.015-0.12s)
    } else if (lapsOnCurrentTires <= 20) {
      factor = 0.12 + ((lapsOnCurrentTires - 10) * 0.04); // Moderate increase (0.12-0.52s)
    } else if (lapsOnCurrentTires <= 30) {
      factor = 0.52 + ((lapsOnCurrentTires - 20) * 0.08); // Steep increase (0.52-1.32s)
    } else {
      // EXPONENTIAL penalty for extreme stint lengths (1.32s+)
      double extremeLaps = (lapsOnCurrentTires - 30).toDouble();
      factor = 1.32 + (extremeLaps * 0.15) + (extremeLaps * extremeLaps * 0.02);
    }

    // Apply compound cliff penalty
    factor += getCompoundCliffPenalty();

    // Tire management skill impact (50% to 100% of base degradation)
    double managementMultiplier = 1.0 - (tyreManagementSkill / 200.0);

    // Compound multiplier (this is where soft tires get punished heavily)
    double compoundMultiplier = currentCompound.degradationMultiplier;

    return factor * managementMultiplier * compoundMultiplier;
  }

  // NEW: Compound-specific cliff effects
  double getCompoundCliffPenalty() {
    // Additional penalty when tires hit their performance cliff
    int cliffPoint = 0;
    double cliffMultiplier = 1.0;

    switch (currentCompound) {
      case TireCompound.soft:
        cliffPoint = 15;
        cliffMultiplier = 2.5; // Massive penalty after cliff for softs
        break;
      case TireCompound.medium:
        cliffPoint = 25;
        cliffMultiplier = 1.8; // Significant penalty for mediums
        break;
      case TireCompound.hard:
        cliffPoint = 40;
        cliffMultiplier = 1.3; // Moderate penalty for hards
        break;
      case TireCompound.intermediate:
        cliffPoint = 20;
        cliffMultiplier = 2.0;
        break;
      case TireCompound.wet:
        cliffPoint = 15;
        cliffMultiplier = 2.2;
        break;
    }

    if (lapsOnCurrentTires > cliffPoint) {
      int lapsOverCliff = lapsOnCurrentTires - cliffPoint;
      return lapsOverCliff * 0.12 * cliffMultiplier; // Escalating cliff penalty
    }

    return 0.0;
  }

  // NEW: Check if approaching tire cliff (for strategy)
  bool isApproachingTireCliff() {
    int cliffPoint = 0;
    switch (currentCompound) {
      case TireCompound.soft:
        cliffPoint = 15;
        break;
      case TireCompound.medium:
        cliffPoint = 25;
        break;
      case TireCompound.hard:
        cliffPoint = 40;
        break;
      case TireCompound.intermediate:
        cliffPoint = 20;
        break;
      case TireCompound.wet:
        cliffPoint = 15;
        break;
    }

    // Return true if within 3 laps of cliff
    return lapsOnCurrentTires >= (cliffPoint - 3);
  }

  // NEW: Predict degradation in future laps
  double predictDegradationInLaps(int lapsAhead) {
    int futureLaps = lapsOnCurrentTires + lapsAhead;

    // Temporarily calculate what degradation would be
    int originalLaps = lapsOnCurrentTires;
    lapsOnCurrentTires = futureLaps;
    double futureDegradation = calculateTyreDegradation();
    lapsOnCurrentTires = originalLaps; // Restore original value

    return futureDegradation;
  }

  TireCompound getWeatherAppropriateStartingCompound(WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      return TireCompound.intermediate;
    } else {
      double random = Random().nextDouble();
      if (random < 0.4) return TireCompound.soft;
      if (random < 0.9) return TireCompound.medium;
      return TireCompound.hard;
    }
  }

  String getTeamStrategyTendency() {
    switch (team) {
      case "Red Bull":
        return "aggressive";
      case "Mercedes":
        return "balanced";
      case "Ferrari":
        return "aggressive";
      case "McLaren":
        return "balanced";
      case "Aston Martin":
        return "conservative";
      case "Williams":
        return "aggressive";
      default:
        return "balanced";
    }
  }

  // Reset methods
  void resetForNewRace() {
    lapsCompleted = 0;
    lapsOnCurrentTires = 0;
    pitStops = 0;
    totalTime = 0.0;
    positionChangeFromStart = 0;
    positionHistory.clear();
    errorCount = 0;
    mechanicalIssuesCount = 0;
    hasActiveMechanicalIssue = false;
    mechanicalIssueLapsRemaining = 0;
    currentIssueDescription = "";
    raceIncidents.clear();
    usedCompounds.clear();
  }

  void updatePosition(int newPosition) {
    position = newPosition;
    positionChangeFromStart = startingPosition - position;
    positionHistory.add(position);

    if (positionHistory.length > 10) {
      positionHistory.removeAt(0);
    }
  }

  void recordIncident(String incident) {
    raceIncidents.add(incident);
  }

  /// Records compound usage for tracking
  void recordCompoundUsage(TireCompound compound) {
    if (!usedCompounds.contains(compound)) {
      usedCompounds.add(compound);
    }
  }

  /// Validates pit stop compound selection
  bool canUseCompound(TireCompound compound, WeatherCondition weather) {
    // In wet weather, only wet compounds are valid
    if (weather == WeatherCondition.rain) {
      return compound == TireCompound.intermediate || compound == TireCompound.wet;
    }

    // In dry weather, check mandatory compound rule
    List<TireCompound> available = availableDryCompounds;
    return available.contains(compound);
  }

  /// Gets compound selection advice for UI
  String getCompoundAdvice(WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      return "Use wet compounds (Inter/Wet)";
    }

    List<TireCompound> available = availableDryCompounds;
    if (available.length == 3) {
      return "Any compound allowed";
    } else if (available.length == 2) {
      return "Must use: ${available.map((c) => c.name).join(" or ")}";
    } else if (available.length == 1) {
      return "Must use: ${available.first.name}";
    }

    return "No valid compounds available";
  }

  bool isDNF() {
    return totalTime.isInfinite;
  }
}
