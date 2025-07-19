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

  // Basic calculation methods
  double calculateTyreDegradation() {
    double factor = 0.0;

    if (lapsOnCurrentTires <= 5) {
      factor = lapsOnCurrentTires * 0.01;
    } else if (lapsOnCurrentTires <= 15) {
      factor = 0.05 + ((lapsOnCurrentTires - 5) * 0.03);
    } else if (lapsOnCurrentTires <= 25) {
      factor = 0.35 + ((lapsOnCurrentTires - 15) * 0.06);
    } else {
      factor = 0.95 + ((lapsOnCurrentTires - 25) * 0.08);
    }

    double managementMultiplier = 1.0 - (tyreManagementSkill / 200.0);
    double compoundMultiplier = currentCompound.degradationMultiplier;

    // NOTE: Track multiplier is applied in PerformanceCalculator.calculateCurrentLapTime()
    // to avoid circular dependencies
    return factor * managementMultiplier * compoundMultiplier;
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
    print(incident);
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
