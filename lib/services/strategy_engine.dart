// Enhanced Strategy Engine with FIXED pit stop logic - no more unnecessary stops
import 'dart:math';
import '../models/driver.dart';
import '../models/enums.dart';
import '../models/track.dart';
import '../utils/constants.dart';

class StrategyEngine {
  static bool shouldPitStop(
      Driver driver, int currentLap, int totalLaps, double gapBehind, double gapAhead, Track track) {
    // SAFETY CONSTRAINTS FIRST (prevent unrealistic decisions)
    if (currentLap < F1Constants.minLapsBeforePit) return false;
    if (driver.pitStops >= F1Constants.maxPitStops) return false;
    if (driver.lapsOnCurrentTires < F1Constants.minLapsForPit) return false;
    if (currentLap > totalLaps - F1Constants.lastLapsToPit) return false;

    double currentDegradation = driver.calculateTyreDegradation();
    double trackAdjustedDegradation = currentDegradation * track.tireDegradationMultiplier;

    // MANDATORY PIT STOP: Must pit at least once
    bool mustPitSoon = driver.pitStops == 0 && currentLap >= totalLaps - F1Constants.lastMandatoryPitLaps;

    // MANDATORY COMPOUND CHANGE: Must use different compound if only used one type
    bool mustChangeCompound = _mustUseSecondCompound(driver, currentLap, totalLaps);

    // TRACK-SPECIFIC STRATEGY ADJUSTMENTS - REDUCED IMPACT
    double trackAggressionMultiplier = _calculateTrackAggressionMultiplier(track);

    // ENHANCED: Compound-specific emergency thresholds
    double emergencyThreshold = _getEmergencyThreshold(driver.currentCompound);
    double aggressiveThreshold = _getAggressiveThreshold(driver.currentCompound);
    double conservativeThreshold = _getConservativeThreshold(driver.currentCompound);

    // EMERGENCY: Tire degradation is killing pace - ONLY for truly bad degradation
    if (trackAdjustedDegradation > emergencyThreshold) {
      return true;
    }

    // CLIFF WARNING: Approaching tire performance cliff AND degradation is already bad
    if (driver.isApproachingTireCliff() && trackAdjustedDegradation > (conservativeThreshold * 1.2)) {
      return true;
    }

    // MANDATORY COMPOUND RULE: Force pit if must change compound and running out of time
    if (mustChangeCompound && currentLap >= totalLaps - 15) {
      return true;
    }

    // Enhanced pit strategy with skill-based thinking
    int basePitLap = F1Constants.basePitLapMin + (driver.tyreManagementSkill ~/ 4);
    int pitWindowVariation = Random().nextInt(F1Constants.pitVariation) - (F1Constants.pitVariation ~/ 2);

    // ENHANCED: Adjust pit window based on compound being used
    int compoundAdjustment = _getCompoundPitAdjustment(driver.currentCompound);
    int idealPitLap = basePitLap + pitWindowVariation + compoundAdjustment;

    // Track position influences
    bool inLeadingGroup = driver.position <= 3;
    bool inMidfield = driver.position >= 4 && driver.position <= 7;
    bool atBack = driver.position >= 8;

    // STRATEGIC DECISIONS based on driver skills and realistic thresholds
    if (driver.pitStops == 0 && currentLap >= 18) {
      // SPEED-BASED STRATEGY: Higher speed = more confident in aggressive moves
      double speedConfidence = driver.speed / 100.0;

      // FIXED: Much stricter undercut logic - only if degradation is actually significant
      bool canUndercut = gapAhead < F1Constants.underCutGap &&
          trackAdjustedDegradation > (aggressiveThreshold / trackAggressionMultiplier) &&
          currentLap >= 22;
      if (canUndercut && Random().nextDouble() < (0.05 + speedConfidence * 0.2) * trackAggressionMultiplier) {
        // REDUCED from 0.1 + 0.4
        return true;
      }

      // SAFE PIT WINDOW: Large gap behind means minimal position loss - STRICTER
      bool safePitWindow = gapBehind > F1Constants.safeGap &&
          trackAdjustedDegradation >
              (aggressiveThreshold / trackAggressionMultiplier); // INCREASED from conservative to aggressive
      if (safePitWindow && currentLap >= idealPitLap - 3) {
        // REDUCED from -5
        return true;
      }

      // TIRE MANAGEMENT STRATEGY: Better tire management = willing to stay out MUCH longer
      double tireConfidence = driver.tyreManagementSkill / 100.0;
      double stayOutThreshold = (aggressiveThreshold + (tireConfidence * emergencyThreshold)) /
          trackAggressionMultiplier; // INCREASED from conservative+aggressive to aggressive+emergency
      bool shouldStayOut =
          trackAdjustedDegradation < stayOutThreshold && currentLap <= idealPitLap + 5; // INCREASED from +3

      // Override stay out decision if must change compound or approaching cliff WITH bad degradation
      if ((mustChangeCompound && trackAdjustedDegradation > conservativeThreshold) ||
          (driver.isApproachingTireCliff() && trackAdjustedDegradation > aggressiveThreshold)) {
        shouldStayOut = false;
      }

      if (!shouldStayOut && currentLap >= idealPitLap) {
        return true;
      }

      // FIXED: Much more conservative position-specific strategies
      if (inLeadingGroup) {
        // SPECIAL LEADER LOGIC: P1 can make strategic moves - MORE CONSERVATIVE
        if (driver.position == 1) {
          // DEFENSIVE UNDERCUT: Prevent P2 from undercutting - STRICTER
          bool defensiveUndercut = gapBehind < 15.0 &&
              trackAdjustedDegradation >
                  (aggressiveThreshold / trackAggressionMultiplier); // REDUCED from 18.0 and conservative to aggressive
          if (defensiveUndercut && Random().nextDouble() < 0.2 * trackAggressionMultiplier) {
            // REDUCED from 0.4
            return true;
          }

          // STRATEGIC UNDERCUT: Large gap allows safe early pit - STRICTER
          bool strategicUndercut = gapBehind > 35.0 &&
              trackAdjustedDegradation > (aggressiveThreshold / trackAggressionMultiplier); // INCREASED from 28.0
          if (strategicUndercut &&
              Random().nextDouble() < (0.08 + speedConfidence * 0.08) * trackAggressionMultiplier) {
            // REDUCED from 0.15+0.15
            return true;
          }
        }

        // P2-P3 UNDERCUT ATTEMPTS: Attack the leader - MORE CONSERVATIVE
        if (driver.position >= 2 && driver.position <= 3) {
          bool canAttackAhead = gapAhead < 20.0 && // REDUCED from 25.0
              trackAdjustedDegradation > (aggressiveThreshold / trackAggressionMultiplier) &&
              currentLap >= 25; // INCREASED from 22
          if (canAttackAhead && Random().nextDouble() < (speedConfidence * 0.2) * trackAggressionMultiplier) {
            // REDUCED from 0.4
            return true;
          }
        }

        // TRADITIONAL LEADER LOGIC: Conservative degradation-based pitting - STRICTER
        double leaderThreshold =
            (aggressiveThreshold + (tireConfidence * conservativeThreshold)) / trackAggressionMultiplier;

        // Consistent drivers are more conservative with thresholds
        if (driver.consistency > 85) {
          leaderThreshold *= 1.2; // INCREASED from 0.9 - MORE conservative
        }

        if (trackAdjustedDegradation > leaderThreshold && (gapBehind > 25.0 || gapAhead < 12.0)) {
          // INCREASED gap requirements
          return true;
        }
      }

      // FIXED: Much more conservative midfield strategy
      if (inMidfield) {
        double aggressionChance = (0.05 + (speedConfidence * 0.15)) * trackAggressionMultiplier; // REDUCED from 0.1+0.3
        // Only increase aggression if degradation is actually BAD and must change compound
        if (mustChangeCompound && trackAdjustedDegradation > conservativeThreshold) {
          aggressionChance *= 1.2; // REDUCED from 1.3
        }
        if (trackAdjustedDegradation > (aggressiveThreshold / trackAggressionMultiplier) &&
            Random().nextDouble() < aggressionChance) {
          return true;
        }
      }

      // FIXED: More conservative back of pack strategy
      if (atBack) {
        double desperationChance = (0.1 + (speedConfidence * 0.2)) * trackAggressionMultiplier; // REDUCED from 0.2+0.4
        // Only increase desperation if degradation is BAD and must change compound
        if (mustChangeCompound && trackAdjustedDegradation > conservativeThreshold) {
          desperationChance *= 1.2; // REDUCED from 1.4
        }
        if (trackAdjustedDegradation >
                (aggressiveThreshold / trackAggressionMultiplier) && // INCREASED from conservative
            Random().nextDouble() < desperationChance) {
          return true;
        }
      }
    }

    // MANDATORY PIT: Force pit stop if really running out of time
    if (mustPitSoon) return true;

    return false;
  }

  // ENHANCED: Compound-specific emergency thresholds - SLIGHTLY INCREASED
  static double _getEmergencyThreshold(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return F1Constants.softEmergencyThreshold * 1.1; // 1.32s instead of 1.2s
      case TireCompound.medium:
        return F1Constants.mediumEmergencyThreshold * 1.1; // 1.65s instead of 1.5s
      case TireCompound.hard:
        return F1Constants.hardEmergencyThreshold * 1.1; // 2.2s instead of 2.0s
      case TireCompound.intermediate:
        return 2.0; // INCREASED from 1.8
      case TireCompound.wet:
        return 2.4; // INCREASED from 2.2
    }
  }

  // INCREASED aggressive thresholds to make pit stops less frequent
  static double _getAggressiveThreshold(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return F1Constants.softAggressiveThreshold * 1.3; // 0.78s instead of 0.6s
      case TireCompound.medium:
        return F1Constants.mediumAggressiveThreshold * 1.3; // 1.04s instead of 0.8s
      case TireCompound.hard:
        return F1Constants.hardAggressiveThreshold * 1.3; // 1.3s instead of 1.0s
      case TireCompound.intermediate:
        return 1.15; // INCREASED from 0.9
      case TireCompound.wet:
        return 1.4; // INCREASED from 1.1
    }
  }

  // INCREASED conservative thresholds
  static double _getConservativeThreshold(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return F1Constants.softConservativeThreshold * 1.5; // 0.6s instead of 0.4s
      case TireCompound.medium:
        return F1Constants.mediumConservativeThreshold * 1.5; // 0.75s instead of 0.5s
      case TireCompound.hard:
        return F1Constants.hardConservativeThreshold * 1.5; // 1.05s instead of 0.7s
      case TireCompound.intermediate:
        return 0.9; // INCREASED from 0.6
      case TireCompound.wet:
        return 1.2; // INCREASED from 0.8
    }
  }

  // ENHANCED: Compound-specific pit window adjustments
  static int _getCompoundPitAdjustment(TireCompound compound) {
    switch (compound) {
      case TireCompound.soft:
        return -3; // REDUCED from -5 (less eager to pit early)
      case TireCompound.medium:
        return 0; // Standard timing
      case TireCompound.hard:
        return 12; // INCREASED from 8 (can stay out much longer)
      case TireCompound.intermediate:
        return -2; // REDUCED from -3
      case TireCompound.wet:
        return -3; // REDUCED from -5
    }
  }

  // FIXED: Much more conservative track aggression calculation
  static double _calculateTrackAggressionMultiplier(Track track) {
    double multiplier = 1.0;

    // Hard-to-overtake tracks reduce pit aggression (Monaco, Hungary) - MORE CONSERVATIVE
    if (track.overtakingDifficulty < 0.4) {
      multiplier *= 0.4; // REDUCED from 0.6 - much more conservative
    }
    // Easy-to-overtake tracks increase pit aggression (Monza, Spa) - LESS AGGRESSIVE
    else if (track.overtakingDifficulty > 0.7) {
      multiplier *= 1.2; // REDUCED from 1.4
    }

    // High tire degradation tracks encourage earlier pit stops - REDUCED IMPACT
    if (track.tireDegradationMultiplier > 1.2) {
      multiplier *= 1.15; // REDUCED from 1.3
    }

    // Tracks that favor two-stop strategies - REDUCED IMPACT
    if (track.favorsTwoStop) {
      multiplier *= 1.1; // REDUCED from 1.2
    }

    return multiplier;
  }

  /// Checks if driver must use a second compound type - STRICTER LOGIC
  static bool _mustUseSecondCompound(Driver driver, int currentLap, int totalLaps) {
    // Rule doesn't apply in wet conditions
    if (driver.currentCompound == TireCompound.intermediate || driver.currentCompound == TireCompound.wet) {
      return false;
    }

    // Get dry compounds already used
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
    // FIXED: Only return true if we're actually late in the race
    return dryCompoundsUsed.length == 1 &&
        currentLap >= (totalLaps * 0.4); // CHANGED from lap 10 to 40% of race distance
  }

  static TireCompound selectCompoundDynamic(Driver driver, WeatherCondition weather, int currentLap, int totalLaps,
      double gapAhead, double gapBehind, Track track) {
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

    // ENHANCED: Calculate remaining stint length to choose optimal compound
    int estimatedStintLength = _estimateRemainingStintLength(currentLap, totalLaps, driver.pitStops);

    // CRITICAL FIX: Filter out impossible compounds based on stint length and track
    List<TireCompound> feasibleCompounds =
        _filterFeasibleCompounds(availableCompounds, estimatedStintLength, track.tireDegradationMultiplier);

    // If no feasible compounds (shouldn't happen), fall back to available
    if (feasibleCompounds.isEmpty) {
      feasibleCompounds = availableCompounds;
      print("WARNING: No feasible compounds for ${driver.name} - ${estimatedStintLength} laps remaining");
    }

    // ENHANCED: Choose compound based on stint length requirements and track characteristics
    TireCompound optimalCompound =
        _selectOptimalCompoundForStint(feasibleCompounds, estimatedStintLength, track.tireDegradationMultiplier);

    // FIXED: Only use probability system if multiple feasible compounds exist
    if (feasibleCompounds.length == 1) {
      // Only one feasible choice - use it regardless of preferences
      print(
          "COMPOUND FORCED: ${driver.name} must use ${feasibleCompounds.first.name} for ${estimatedStintLength} laps");
      return feasibleCompounds.first;
    }

    // Apply variability factors with bias toward optimal compound (only for feasible compounds)
    Map<TireCompound, double> compoundProbabilities = {};

    for (TireCompound compound in feasibleCompounds) {
      // CHANGED: Only consider feasible compounds
      // Start with higher probability for optimal compound
      double probability = compound == optimalCompound ? 0.7 : 0.3; // INCREASED optimal bias

      // Apply all variability factors
      probability *= _getSkillMultiplier(driver, compound);
      probability *= _getPerformancePressureMultiplier(driver, compound);
      probability *= _getTeamStrategyMultiplier(driver, compound);
      probability *= _getRandomDecisionMultiplier();
      probability *= _getCompoundHistoryMultiplier(driver, compound);

      compoundProbabilities[compound] = probability;
    }

    // SELECT COMPOUND BASED ON WEIGHTED PROBABILITIES
    TireCompound selectedCompound = _selectFromWeightedProbabilities(compoundProbabilities);
    return selectedCompound;
  }

  /// NEW: Filter compounds that can actually complete the required stint length
  static List<TireCompound> _filterFeasibleCompounds(
      List<TireCompound> available, int stintLength, double trackMultiplier) {
    List<TireCompound> feasible = [];

    for (TireCompound compound in available) {
      int maxViableLaps = _getMaxViableLapsForCompound(compound, trackMultiplier);

      if (stintLength <= maxViableLaps) {
        feasible.add(compound);
      } else {}
    }

    return feasible;
  }

  /// NEW: Calculate maximum viable laps for each compound considering track
  static int _getMaxViableLapsForCompound(TireCompound compound, double trackMultiplier) {
    // Base cliff points for each compound
    int baseCliff;
    switch (compound) {
      case TireCompound.soft:
        baseCliff = 15;
        break;
      case TireCompound.medium:
        baseCliff = 25;
        break;
      case TireCompound.hard:
        baseCliff = 40;
        break;
      case TireCompound.intermediate:
        baseCliff = 20;
        break;
      case TireCompound.wet:
        baseCliff = 15;
        break;
    }

    // Adjust for track degradation - harder tracks reduce viable stint length
    int adjustedCliff = (baseCliff / trackMultiplier).round();

    // Add small buffer (2-3 laps) beyond cliff for emergency situations
    int maxViable = adjustedCliff + 3;

    return maxViable;
  }

  /// ENHANCED: Better stint length estimation
  static int _estimateRemainingStintLength(int currentLap, int totalLaps, int pitStops) {
    int remainingLaps = totalLaps - currentLap;

    if (pitStops == 0) {
      // First stint, assume one more pit stop needed (unless very short race)
      if (remainingLaps <= 20) {
        return remainingLaps; // Short race, go to the end
      } else {
        return remainingLaps ~/ 2; // Split remaining laps
      }
    } else if (pitStops == 1) {
      // Second stint - more intelligent decision
      if (remainingLaps <= 35) {
        return remainingLaps; // Go to the end
      } else {
        // Long stint remaining, might need another stop
        return remainingLaps ~/ 2;
      }
    } else {
      // Multiple stops already, definitely going to the end
      return remainingLaps;
    }
  }

  /// ENHANCED: More intelligent optimal compound selection
  static TireCompound _selectOptimalCompoundForStint(
      List<TireCompound> available, int stintLength, double trackMultiplier) {
    // Calculate adjusted limits based on track degradation
    int softLimit = _getMaxViableLapsForCompound(TireCompound.soft, trackMultiplier) - 2; // Conservative
    int mediumLimit = _getMaxViableLapsForCompound(TireCompound.medium, trackMultiplier) - 2;
    int hardLimit = _getMaxViableLapsForCompound(TireCompound.hard, trackMultiplier) - 2;

    print("  Compound limits - Soft: $softLimit, Medium: $mediumLimit, Hard: $hardLimit");

    // Choose most appropriate compound for stint length
    if (stintLength <= softLimit && available.contains(TireCompound.soft)) {
      return TireCompound.soft;
    } else if (stintLength <= mediumLimit && available.contains(TireCompound.medium)) {
      return TireCompound.medium;
    } else if (available.contains(TireCompound.hard)) {
      return TireCompound.hard;
    }

    // Wet compounds
    if (available.contains(TireCompound.intermediate)) {
      return TireCompound.intermediate;
    }
    if (available.contains(TireCompound.wet)) {
      return TireCompound.wet;
    }

    // Fallback to first available (shouldn't reach here)
    return available.first;
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
    if (driver.team.reliability < 80) {
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

  static void executePitStop(Driver driver, WeatherCondition weather, int currentLap, int totalLaps, double gapAhead,
      double gapBehind, Track track) {
    driver.pitStops++;
    driver.lapsOnCurrentTires = 0;

    // Track old compound usage
    if (!driver.usedCompounds.contains(driver.currentCompound)) {
      driver.usedCompounds.add(driver.currentCompound);
    }

    // SELECT NEW COMPOUND STRATEGICALLY (with mandatory compound rule)
    TireCompound oldCompound = driver.currentCompound;
    driver.currentCompound = selectCompoundDynamic(driver, weather, currentLap, totalLaps, gapAhead, gapBehind, track);

    // Calculate pit time with track penalty
    double pitTime = calculatePitStopTime(driver, track);

    // Slight penalty for compound changes
    if (oldCompound != driver.currentCompound) {
      pitTime += 0.5;
    }

    driver.totalTime += pitTime;

    // Log compound change with mandatory rule info
    double maxNormalTime = 27.0 + track.pitStopTimePenalty;
    double minNormalTime = 22.0;
    String stopType = pitTime < minNormalTime || pitTime > maxNormalTime ? " (EXCEPTIONAL)" : " (normal)";
    String compoundChange = oldCompound == driver.currentCompound
        ? "${driver.currentCompound.name}"
        : "${oldCompound.name} → ${driver.currentCompound.name}";

    // Add mandatory compound rule indicator
    String ruleInfo = _mustUseSecondCompound(driver, currentLap, totalLaps) ? " [MANDATORY]" : "";

    String incident =
        "Lap ${driver.lapsCompleted + 1}: Pit stop - $compoundChange (${pitTime.toStringAsFixed(1)}s$stopType)$ruleInfo";
    driver.recordIncident(incident);
  }

  // Helper functions for gap analysis (if not already defined elsewhere)
  static bool hasSignificantAdvantage(Driver driver, double gapBehind) {
    return gapBehind > 20.0;
  }

  static bool hasSmallOpportunity(Driver driver, double gapAhead) {
    return gapAhead < 15.0;
  }

  /// DEBUG: Add logging to understand pit decisions
  static void debugPitDecision(Driver driver, int currentLap, bool shouldPit, String reason) {
    double degradation = driver.calculateTyreDegradation();
    print(
        "PIT DEBUG - ${driver.name} Lap $currentLap: Should pit: $shouldPit | Reason: $reason | Degradation: ${degradation.toStringAsFixed(2)}s | Tire: ${driver.currentCompound.name} (${driver.lapsOnCurrentTires} laps)");
  }

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
      return "🔄 No compounds used yet";
    }
  }

  static double calculatePitStopTime(Driver driver, Track track) {
    // Base pit stop time calculation based on team performance
    double performanceRange = 98.0 - 72.0; // Updated range for 2025

    // Calculate base time: better performance = faster pit stops
    double teamEfficiencyFactor = (driver.team.carPerformance - 72.0) / performanceRange;
    double baseTime =
        F1Constants.maxPitTime - (teamEfficiencyFactor * (F1Constants.maxPitTime - F1Constants.minPitTime));

    // Apply team-specific pit stop speed multiplier
    baseTime *= driver.team.pitStopSpeed;

    // 25% chance of "exceptional" pit stop (good or bad)
    bool isExceptionalStop = Random().nextDouble() < F1Constants.exceptionalPitChance;

    if (isExceptionalStop) {
      // Exceptional stops have much more variance
      double performanceFactor = driver.team.carPerformance / 100.0;
      double exceptionRange = F1Constants.exceptionalPitVariation;
      double bias = (performanceFactor - 0.72) / 0.26; // Updated for 2025 range

      // Biased random: good teams lean toward negative (faster), bad teams toward positive (slower)
      double biasedRandom = (Random().nextDouble() - 0.5 + (bias - 0.5) * 0.6) * 2;
      double exceptionalVariation = biasedRandom * exceptionRange;

      double finalTime = baseTime + exceptionalVariation;
      finalTime += track.pitStopTimePenalty; // Add track pit lane penalty
      return finalTime.clamp(18.0, 32.0 + track.pitStopTimePenalty); // Updated range
    } else {
      // Normal stops with small variance
      double normalVariation =
          (Random().nextDouble() * F1Constants.normalPitVariation * 2) - F1Constants.normalPitVariation;
      double finalTime = baseTime + normalVariation;
      finalTime += track.pitStopTimePenalty; // Add track pit lane penalty
      return finalTime.clamp(22.0, 27.0 + track.pitStopTimePenalty);
    }
  }
}
// ... rest of the methods remain unchanged
