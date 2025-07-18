// Enhanced Strategy Engine with Mandatory Compound Rule
import 'dart:math';
import '../models/driver.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

class StrategyEngine {
  static bool shouldPitStop(Driver driver, int currentLap, int totalLaps, double gapBehind, double gapAhead) {
    // SAFETY CONSTRAINTS FIRST (prevent unrealistic decisions)
    if (currentLap < F1Constants.minLapsBeforePit) return false;
    if (driver.pitStops >= F1Constants.maxPitStops) return false;
    if (driver.lapsOnCurrentTires < F1Constants.minLapsForPit) return false;
    if (currentLap > totalLaps - F1Constants.lastLapsToPit) return false;

    double currentDegradation = driver.calculateTyreDegradation();

    // MANDATORY PIT STOP: Must pit at least once
    bool mustPitSoon = driver.pitStops == 0 && currentLap >= totalLaps - F1Constants.lastMandatoryPitLaps;

    // MANDATORY COMPOUND CHANGE: Must use different compound if only used one type
    bool mustChangeCompound = _mustUseSecondCompound(driver, currentLap, totalLaps);

    // Enhanced pit strategy with skill-based thinking
    int basePitLap = F1Constants.basePitLapMin + (driver.tyreManagementSkill ~/ 4);
    int pitWindowVariation = Random().nextInt(F1Constants.pitVariation) - (F1Constants.pitVariation ~/ 2);
    int idealPitLap = basePitLap + pitWindowVariation;

    // Track position influences
    bool inLeadingGroup = driver.position <= 3;
    bool inMidfield = driver.position >= 4 && driver.position <= 7;
    bool atBack = driver.position >= 8;

    // EMERGENCY: Tire degradation is killing pace
    if (currentDegradation > 2.0) return true;

    // MANDATORY COMPOUND RULE: Force pit if must change compound and running out of time
    if (mustChangeCompound && currentLap >= totalLaps - 15) {
      return true;
    }

    // STRATEGIC DECISIONS based on driver skills
    if (driver.pitStops == 0 && currentLap >= 18) {
      // SPEED-BASED STRATEGY: Higher speed = more confident in aggressive moves
      double speedConfidence = driver.speed / 100.0;
      bool canUndercut = gapAhead < F1Constants.underCutGap && currentDegradation > 0.8 && currentLap >= 22;
      if (canUndercut && Random().nextDouble() < (0.1 + speedConfidence * 0.4)) {
        return true;
      }

      // SAFE PIT WINDOW: Large gap behind means minimal position loss
      bool safePitWindow = gapBehind > F1Constants.safeGap && currentDegradation > 0.6;
      if (safePitWindow && currentLap >= idealPitLap - 5) {
        return true;
      }

      // TIRE MANAGEMENT STRATEGY: Better tire management = willing to stay out longer
      double tireConfidence = driver.tyreManagementSkill / 100.0;
      double stayOutThreshold = 0.8 + (tireConfidence * 0.8);
      bool shouldStayOut = currentDegradation < stayOutThreshold && currentLap <= idealPitLap + 3;

      // Override stay out decision if must change compound
      if (mustChangeCompound) {
        shouldStayOut = false;
      }

      if (!shouldStayOut && currentLap >= idealPitLap) {
        return true;
      }

      // Position-specific strategies influenced by skills
      if (inLeadingGroup) {
        // SPECIAL LEADER LOGIC: P1 can make strategic moves
        if (driver.position == 1) {
          // DEFENSIVE UNDERCUT: Prevent P2 from undercutting
          bool defensiveUndercut = gapBehind < 18.0 && currentDegradation > 0.6;
          if (defensiveUndercut && Random().nextDouble() < 0.4) {
            return true;
          }

          // STRATEGIC UNDERCUT: Large gap allows safe early pit
          bool strategicUndercut = gapBehind > 28.0 && currentDegradation > 0.8;
          if (strategicUndercut && Random().nextDouble() < (0.15 + speedConfidence * 0.15)) {
            return true;
          }
        }

        // P2-P3 UNDERCUT ATTEMPTS: Attack the leader
        if (driver.position >= 2 && driver.position <= 3) {
          bool canAttackAhead = gapAhead < 25.0 && currentDegradation > 0.7 && currentLap >= 22;
          if (canAttackAhead && Random().nextDouble() < (speedConfidence * 0.4)) {
            return true;
          }
        }

        // TRADITIONAL LEADER LOGIC: Conservative degradation-based pitting
        double leaderThreshold = 1.0 + (tireConfidence * 0.6);

        // Consistent drivers are more conservative with thresholds
        if (driver.consistency > 85) {
          leaderThreshold *= 0.9;
        }

        if (currentDegradation > leaderThreshold && (gapBehind > 20.0 || gapAhead < 15.0)) {
          return true;
        }
      }

      if (inMidfield) {
        double aggressionChance = 0.1 + (speedConfidence * 0.3);
        // Increase aggression if must change compound
        if (mustChangeCompound) {
          aggressionChance *= 1.3;
        }
        if (currentDegradation > 0.9 && Random().nextDouble() < aggressionChance) {
          return true;
        }
      }

      if (atBack) {
        double desperationChance = 0.2 + (speedConfidence * 0.4);
        // Increase desperation if must change compound
        if (mustChangeCompound) {
          desperationChance *= 1.4;
        }
        if (currentDegradation > 0.6 && Random().nextDouble() < desperationChance) {
          return true;
        }
      }
    }

    // MANDATORY PIT: Force pit stop if really running out of time
    if (mustPitSoon) return true;

    return false;
  }

  /// Checks if driver must use a second compound type
  static bool _mustUseSecondCompound(Driver driver, int currentLap, int totalLaps) {
    // Rule doesn't apply in wet conditions
    if (driver.currentCompound == TireCompound.intermediate || driver.currentCompound == TireCompound.wet) {
      return false;
    }

    // If driver has only used one type of dry compound, they must use another
    List<TireCompound> dryCompoundsUsed = driver.usedCompounds
        .where((compound) =>
            compound == TireCompound.soft || compound == TireCompound.medium || compound == TireCompound.hard)
        .toSet()
        .toList();

    // Add current compound if not already tracked
    if (!dryCompoundsUsed.contains(driver.currentCompound) &&
        (driver.currentCompound == TireCompound.soft ||
            driver.currentCompound == TireCompound.medium ||
            driver.currentCompound == TireCompound.hard)) {
      dryCompoundsUsed.add(driver.currentCompound);
    }

    // Must use second compound if only used one type and race is progressing
    return dryCompoundsUsed.length == 1 && currentLap >= 10;
  }

  /// Gets mandatory compound info for UI display
  static String getMandatoryCompoundStatus(Driver driver) {
    List<TireCompound> dryCompoundsUsed = driver.usedCompounds
        .where((compound) =>
            compound == TireCompound.soft || compound == TireCompound.medium || compound == TireCompound.hard)
        .toSet()
        .toList();

    // Add current compound if not already tracked
    if (!dryCompoundsUsed.contains(driver.currentCompound) &&
        (driver.currentCompound == TireCompound.soft ||
            driver.currentCompound == TireCompound.medium ||
            driver.currentCompound == TireCompound.hard)) {
      dryCompoundsUsed.add(driver.currentCompound);
    }

    if (dryCompoundsUsed.length >= 2) {
      return "✅ Rule satisfied";
    } else if (dryCompoundsUsed.length == 1) {
      return "⚠️ Must use 2nd compound";
    } else {
      return "🔄 No compounds used";
    }
  }

  static double calculatePitStopTime(Driver driver) {
    // Base pit stop time calculation based on team performance
    double performanceRange = 98.0 - 75.0;

    // Calculate base time: better performance = faster pit stops
    double teamEfficiencyFactor = (driver.carPerformance - 75.0) / performanceRange;
    double baseTime =
        F1Constants.maxPitTime - (teamEfficiencyFactor * (F1Constants.maxPitTime - F1Constants.minPitTime));

    // 25% chance of "exceptional" pit stop (good or bad)
    bool isExceptionalStop = Random().nextDouble() < F1Constants.exceptionalPitChance;

    if (isExceptionalStop) {
      // Exceptional stops have much more variance
      double performanceFactor = driver.carPerformance / 100.0;
      double exceptionRange = F1Constants.exceptionalPitVariation;
      double bias = (performanceFactor - 0.75) / 0.23;

      // Biased random: good teams lean toward negative (faster), bad teams toward positive (slower)
      double biasedRandom = (Random().nextDouble() - 0.5 + (bias - 0.5) * 0.6) * 2;
      double exceptionalVariation = biasedRandom * exceptionRange;

      double finalTime = baseTime + exceptionalVariation;
      return finalTime.clamp(20.0, 30.0);
    } else {
      // Normal stops with small variance
      double normalVariation =
          (Random().nextDouble() * F1Constants.normalPitVariation * 2) - F1Constants.normalPitVariation;
      double finalTime = baseTime + normalVariation;
      return finalTime.clamp(22.0, 27.0);
    }
  }

  static TireCompound selectCompoundDynamic(
      Driver driver, WeatherCondition weather, int currentLap, int totalLaps, double gapAhead, double gapBehind) {
    // WEATHER FIRST (mandatory)
    if (weather == WeatherCondition.rain) {
      return TireCompound.intermediate;
    }

    // MANDATORY COMPOUND RULE: Must use different compound if only used one type
    List<TireCompound> availableCompounds = _getAvailableCompounds(driver, weather);

    if (availableCompounds.isEmpty) {
      // Fallback - this shouldn't happen but safety first
      return TireCompound.medium;
    }

    // BASE STRATEGIC PREFERENCE (position-based) - filtered by available compounds
    List<TireCompound> strategicOptions = _getStrategicOptions(driver, currentLap, totalLaps, gapAhead, gapBehind)
        .where((compound) => availableCompounds.contains(compound))
        .toList();

    if (strategicOptions.isEmpty) {
      strategicOptions = availableCompounds;
    }

    // ADD VARIABILITY FACTORS
    Map<TireCompound, double> compoundProbabilities = {};

    for (TireCompound compound in strategicOptions) {
      double probability = _getBaseProbability(compound, strategicOptions);

      // Apply all variability factors
      probability *= _getSkillMultiplier(driver, compound);
      probability *= _getPerformancePressureMultiplier(driver, compound);
      probability *= _getTeamStrategyMultiplier(driver, compound);
      probability *= _getRandomDecisionMultiplier();
      probability *= _getCompoundHistoryMultiplier(driver, compound);

      compoundProbabilities[compound] = probability;
    }

    // SELECT COMPOUND BASED ON WEIGHTED PROBABILITIES
    return _selectFromWeightedProbabilities(compoundProbabilities);
  }

  /// Gets available compounds considering mandatory compound rule
  static List<TireCompound> _getAvailableCompounds(Driver driver, WeatherCondition weather) {
    // In wet weather, all wet compounds are available
    if (weather == WeatherCondition.rain) {
      return [TireCompound.intermediate, TireCompound.wet];
    }

    // Get all dry compounds
    List<TireCompound> allDryCompounds = [TireCompound.soft, TireCompound.medium, TireCompound.hard];

    // Get dry compounds already used
    List<TireCompound> dryCompoundsUsed =
        driver.usedCompounds.where((compound) => allDryCompounds.contains(compound)).toSet().toList();

    // Add current compound if not already tracked
    if (!dryCompoundsUsed.contains(driver.currentCompound) && allDryCompounds.contains(driver.currentCompound)) {
      dryCompoundsUsed.add(driver.currentCompound);
    }

    // If only used one compound type, must use different compounds
    if (dryCompoundsUsed.length == 1) {
      return allDryCompounds.where((compound) => !dryCompoundsUsed.contains(compound)).toList();
    }

    // If already used 2+ compounds, can use any
    return allDryCompounds;
  }

  static List<TireCompound> _getStrategicOptions(
      Driver driver, int currentLap, int totalLaps, double gapAhead, double gapBehind) {
    List<TireCompound> options = [];

    // POSITION-BASED STRATEGIC FOUNDATION
    if (driver.position <= 3) {
      // LEADERS: Usually avoid extremes unless situation demands
      if (gapBehind < 10.0) {
        // Under pressure: more aggressive options
        options = [TireCompound.soft, TireCompound.medium];
      } else if (gapBehind > 30.0) {
        // Safe lead: conservative options
        options = [TireCompound.medium, TireCompound.hard];
      } else {
        // Balanced situation: all options available
        options = [TireCompound.soft, TireCompound.medium, TireCompound.hard];
      }
    } else if (driver.position <= 7) {
      // MIDFIELD: Usually more aggressive to gain positions
      if (gapAhead < 15.0) {
        // Close to overtaking: aggressive options
        options = [TireCompound.soft, TireCompound.medium];
      } else {
        // Standard midfield: balanced options
        options = [TireCompound.soft, TireCompound.medium, TireCompound.hard];
      }
    } else {
      // BACKMARKERS: Often desperate, all options available
      options = [TireCompound.soft, TireCompound.medium, TireCompound.hard];
    }

    return options;
  }

  static double _getBaseProbability(TireCompound compound, List<TireCompound> options) {
    return 1.0 / options.length;
  }

  static double _getSkillMultiplier(Driver driver, TireCompound compound) {
    double multiplier = 1.0;

    // HIGH SPEED DRIVERS: Prefer softs
    if (driver.speed > 90) {
      if (compound == TireCompound.soft) multiplier *= 1.2;
      if (compound == TireCompound.hard) multiplier *= 0.9;
    }

    // HIGH CONSISTENCY DRIVERS: Prefer medium/hard
    if (driver.consistency > 85) {
      if (compound == TireCompound.medium || compound == TireCompound.hard) multiplier *= 1.15;
      if (compound == TireCompound.soft) multiplier *= 0.9;
    }

    // HIGH TIRE MANAGEMENT: Prefer harder compounds
    if (driver.tyreManagementSkill > 85) {
      if (compound == TireCompound.hard) multiplier *= 1.2;
      if (compound == TireCompound.soft) multiplier *= 0.95;
    }

    // ROOKIE/LOW SKILL: More unpredictable
    if (driver.speed < 70 || driver.consistency < 60) {
      multiplier *= 0.9 + (Random().nextDouble() * 0.2);
    }

    return multiplier;
  }

  static double _getPerformancePressureMultiplier(Driver driver, TireCompound compound) {
    double multiplier = 1.0;

    // UNDER-PERFORMING vs EXPECTATIONS
    int performanceDelta = driver.position - driver.startingPosition;

    if (performanceDelta > 2) {
      // Performing worse: more desperate/aggressive
      if (compound == TireCompound.soft) multiplier *= 1.15;
      if (compound == TireCompound.hard) multiplier *= 0.9;
    } else if (performanceDelta < -2) {
      // Performing better: more conservative
      if (compound == TireCompound.soft) multiplier *= 0.9;
      if (compound == TireCompound.hard) multiplier *= 1.1;
    }

    // RECENT ERRORS increase desperation
    if (driver.errorCount > 0) {
      double desperationFactor = 1.0 + (driver.errorCount * 0.05);
      if (compound == TireCompound.soft) multiplier *= desperationFactor;
    }

    return multiplier;
  }

  static double _getTeamStrategyMultiplier(Driver driver, TireCompound compound) {
    double multiplier = 1.0;

    // HIGH PERFORMANCE TEAMS: More willing to take risks
    if (driver.carPerformance > 90) {
      if (compound == TireCompound.soft) multiplier *= 1.1;
    }

    // LOW RELIABILITY TEAMS: More conservative
    if (driver.reliability < 80) {
      if (compound == TireCompound.hard) multiplier *= 1.15;
      if (compound == TireCompound.soft) multiplier *= 0.9;
    }

    // TEAM STRATEGY TENDENCIES
    String teamStrategy = driver.getTeamStrategyTendency();
    switch (teamStrategy) {
      case "aggressive":
        if (compound == TireCompound.soft) multiplier *= 1.1;
        break;
      case "conservative":
        if (compound == TireCompound.hard) multiplier *= 1.1;
        break;
      case "balanced":
      default:
        if (compound == TireCompound.medium) multiplier *= 1.05;
        break;
    }

    return multiplier;
  }

  static double _getRandomDecisionMultiplier() {
    return 0.925 + (Random().nextDouble() * 0.15);
  }

  static double _getCompoundHistoryMultiplier(Driver driver, TireCompound compound) {
    double multiplier = 1.0;

    // AVOID REPEATING RECENT COMPOUND (but this is now handled by _getAvailableCompounds)
    if (driver.usedCompounds.isNotEmpty && driver.usedCompounds.last == compound) {
      multiplier *= 0.8;
    }

    // PREFER COMPOUNDS NOT YET USED
    if (!driver.usedCompounds.contains(compound)) {
      multiplier *= 1.1;
    }

    return multiplier;
  }

  static TireCompound _selectFromWeightedProbabilities(Map<TireCompound, double> probabilities) {
    // Normalize probabilities
    double totalWeight = probabilities.values.reduce((a, b) => a + b);

    // Generate random number
    double random = Random().nextDouble() * totalWeight;

    // Select compound based on weighted probability
    double cumulative = 0.0;
    for (MapEntry<TireCompound, double> entry in probabilities.entries) {
      cumulative += entry.value;
      if (random <= cumulative) {
        return entry.key;
      }
    }

    // Fallback
    return probabilities.keys.first;
  }

  static void executePitStop(
      Driver driver, WeatherCondition weather, int currentLap, int totalLaps, double gapAhead, double gapBehind) {
    driver.pitStops++;
    driver.lapsOnCurrentTires = 0;

    // Track old compound usage
    if (!driver.usedCompounds.contains(driver.currentCompound)) {
      driver.usedCompounds.add(driver.currentCompound);
    }

    // SELECT NEW COMPOUND STRATEGICALLY (with mandatory compound rule)
    TireCompound oldCompound = driver.currentCompound;
    driver.currentCompound = selectCompoundDynamic(driver, weather, currentLap, totalLaps, gapAhead, gapBehind);

    // Calculate pit time
    double pitTime = calculatePitStopTime(driver);

    // Slight penalty for compound changes
    if (oldCompound != driver.currentCompound) {
      pitTime += 0.5;
    }

    driver.totalTime += pitTime;

    // Log compound change with mandatory rule info
    String stopType = pitTime < 22.0 || pitTime > 27.0 ? " (EXCEPTIONAL)" : " (normal)";
    String compoundChange = oldCompound == driver.currentCompound
        ? "${driver.currentCompound.name}"
        : "${oldCompound.name} → ${driver.currentCompound.name}";

    // Add mandatory compound rule indicator
    String ruleInfo = _mustUseSecondCompound(driver, currentLap, totalLaps) ? " [MANDATORY]" : "";

    String incident =
        "Lap ${driver.lapsCompleted + 1}: Pit stop - $compoundChange (${pitTime.toStringAsFixed(1)}s$stopType)$ruleInfo";
    driver.recordIncident(incident);
  }
}
