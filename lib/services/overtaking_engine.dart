// lib/services/overtaking_engine.dart
import 'dart:math';
import '../models/driver.dart';
import '../models/track.dart';
import '../models/enums.dart';

/// Comprehensive overtaking system for realistic F1 racing dynamics
class OvertakingEngine {
  /// Process all potential overtaking opportunities for the current lap
  static List<String> processOvertakingOpportunities(
      List<Driver> drivers, int currentLap, Track track, WeatherCondition weather) {
    List<String> overtakingIncidents = [];
    List<Driver> sortedDrivers = List.from(drivers);

    // Sort by current race position (not total time) for overtaking calculations
    sortedDrivers.sort((a, b) => a.position.compareTo(b.position));

    // Process overtaking attempts from back to front to avoid position conflicts
    for (int i = sortedDrivers.length - 1; i >= 1; i--) {
      Driver behindDriver = sortedDrivers[i];
      Driver aheadDriver = sortedDrivers[i - 1];

      // Skip if either driver is DNF
      if (behindDriver.isDNF() || aheadDriver.isDNF()) continue;

      // Calculate overtaking probability
      double overtakeChance = calculateOvertakingProbability(behindDriver, aheadDriver, track, weather, currentLap);

      // Attempt overtake if probability is significant
      if (Random().nextDouble() < overtakeChance) {
        OvertakingResult result = attemptOvertake(behindDriver, aheadDriver, track, weather, currentLap);

        if (result.successful) {
          _executeSuccessfulOvertake(behindDriver, aheadDriver, sortedDrivers);
          overtakingIncidents
              .add("Lap $currentLap: ${behindDriver.name} overtakes ${aheadDriver.name} ${result.method}");

          // Record incidents for both drivers
          behindDriver.recordIncident("Lap $currentLap: Overtook ${aheadDriver.name} ${result.method}");
          aheadDriver.recordIncident("Lap $currentLap: Overtaken by ${behindDriver.name} ${result.method}");
        } else {
          // Failed overtaking attempt - potential incident
          _processFailliedOvertake(behindDriver, aheadDriver, result, currentLap);
          if (result.incidentDescription.isNotEmpty) {
            overtakingIncidents.add("Lap $currentLap: ${result.incidentDescription}");
          }
        }
      }
    }

    // Apply DRS effects for drivers within DRS range
    _applyDRSEffects(sortedDrivers, track);

    return overtakingIncidents;
  }

  /// Calculate the probability of a successful overtaking attempt
  static double calculateOvertakingProbability(
      Driver behindDriver, Driver aheadDriver, Track track, WeatherCondition weather, int currentLap) {
    double baseProbability = 0.0;

    // PERFORMANCE DIFFERENTIAL (most important factor)
    double performanceGap = _calculatePerformanceGap(behindDriver, aheadDriver);

    // Convert performance gap to base overtaking probability
    if (performanceGap > 0.8) {
      baseProbability = 0.25; // Significant pace advantage
    } else if (performanceGap > 0.4) {
      baseProbability = 0.15; // Clear pace advantage
    } else if (performanceGap > 0.1) {
      baseProbability = 0.08; // Slight pace advantage
    } else if (performanceGap > -0.1) {
      baseProbability = 0.03; // Similar pace
    } else {
      baseProbability = 0.01; // Pace disadvantage
    }

    // TRACK OVERTAKING DIFFICULTY
    baseProbability *= track.overtakingDifficulty;

    // TIRE PERFORMANCE DIFFERENTIAL (REDUCED IMPACT)
    double tireDelta = _calculateTireAdvantage(behindDriver, aheadDriver);
    baseProbability *= (1.0 + tireDelta * 0.6); // Reduced from 1.0 to 0.6

    // DRIVER SKILL FACTORS
    double skillMultiplier = _calculateDriverSkillMultiplier(behindDriver, aheadDriver);
    baseProbability *= skillMultiplier;

    // EARLY RACE POSITION PROTECTION (NEW)
    double positionProtection = _getPositionProtectionMultiplier(aheadDriver, behindDriver, currentLap);
    baseProbability *= positionProtection;

    // RACE SITUATION MODIFIERS
    baseProbability *= _getRaceSituationMultiplier(behindDriver, aheadDriver, currentLap);

    // WEATHER EFFECTS
    if (weather == WeatherCondition.rain) {
      // Wet weather increases overtaking opportunities but also risks
      baseProbability *= 1.4;
    }

    // DRS BOOST (if within DRS detection zone)
    if (_isWithinDRSRange(behindDriver, aheadDriver)) {
      baseProbability *= 1.8; // Significant DRS boost
    }

    // SLIPSTREAM EFFECT (on power tracks)
    if (track.type == TrackType.power) {
      baseProbability *= 1.3; // Slipstream advantage on power tracks
    }

    // Cap maximum probability per lap
    return baseProbability.clamp(0.0, 0.35);
  }

  /// Calculate performance gap between two drivers
  static double _calculatePerformanceGap(Driver behind, Driver ahead) {
    // Current lap pace differential based on multiple factors

    // Base car performance difference
    double carGap = (behind.team.carPerformance - ahead.team.carPerformance) / 100.0;

    // Driver skill difference (speed more important for overtaking)
    double speedGap = (behind.speed - ahead.speed) / 200.0;
    double consistencyGap = (behind.consistency - ahead.consistency) / 300.0;

    // Tire degradation difference (fresher tires = advantage)
    double tireDeg = ahead.calculateTyreDegradation() - behind.calculateTyreDegradation();

    // Mechanical issues impact
    double mechanicalImpact = 0.0;
    if (ahead.hasActiveMechanicalIssue) mechanicalImpact += 0.3;
    if (behind.hasActiveMechanicalIssue) mechanicalImpact -= 0.3;

    return carGap + speedGap + consistencyGap + (tireDeg / 3.0) + mechanicalImpact;
  }

  /// Calculate tire advantage for overtaking (UPDATED with realistic values)
  static double _calculateTireAdvantage(Driver behind, Driver ahead) {
    // Fresher tires provide overtaking advantage (reduced impact)
    double ageAdvantage = (ahead.lapsOnCurrentTires - behind.lapsOnCurrentTires) / 30.0; // Reduced from 20.0

    // Compound advantage (UPDATED to match new realistic compound deltas)
    double compoundAdvantage = 0.0;
    if (behind.currentCompound == TireCompound.soft && ahead.currentCompound == TireCompound.medium) {
      compoundAdvantage = 0.06; // Reduced to match new 0.25s delta
    } else if (behind.currentCompound == TireCompound.soft && ahead.currentCompound == TireCompound.hard) {
      compoundAdvantage = 0.08; // Reduced to match new 0.4s total gap
    } else if (behind.currentCompound == TireCompound.medium && ahead.currentCompound == TireCompound.hard) {
      compoundAdvantage = 0.03; // Reduced to match new 0.15s delta
    }

    return (ageAdvantage + compoundAdvantage).clamp(-0.15, 0.15); // Reduced max from 0.2 to 0.15
  }

  /// Calculate driver skill multiplier for overtaking ability
  static double _calculateDriverSkillMultiplier(Driver behind, Driver ahead) {
    // Overtaking skill derived from speed and consistency
    double behindOvertakingSkill = (behind.speed * 0.7 + behind.consistency * 0.3) / 100.0;
    double aheadDefendingSkill = (ahead.consistency * 0.6 + ahead.speed * 0.4) / 100.0;

    // Racing craft - some drivers are naturally better at wheel-to-wheel combat
    double racecraft = _getDriverRacecraft(behind) - _getDriverRacecraft(ahead);

    return (1.0 + (behindOvertakingSkill - aheadDefendingSkill) + racecraft * 0.2).clamp(0.3, 2.0);
  }

  /// Get driver racecraft rating (wheel-to-wheel ability)
  static double _getDriverRacecraft(Driver driver) {
    // Elite drivers have better racecraft
    switch (driver.name) {
      case "Hamilton":
      case "Verstappen":
      case "Alonso":
        return 0.9;
      case "Leclerc":
      case "Russell":
      case "Norris":
        return 0.7;
      case "Sainz":
      case "Perez":
      case "Piastri":
        return 0.5;
      default:
        return 0.3; // Rookies and less experienced drivers
    }
  }

  /// Calculate race situation multiplier
  static double _getRaceSituationMultiplier(Driver behind, Driver ahead, int currentLap) {
    double multiplier = 1.0;

    // Desperation factor - drivers behind their starting position are more aggressive
    if (behind.position > behind.startingPosition) {
      multiplier *= 1.2;
    }

    // Points pressure - drivers fighting for top 10
    if (behind.position >= 9 && behind.position <= 12) {
      multiplier *= 1.1;
    }

    // Late race desperation
    if (currentLap > 40) {
      multiplier *= 1.15;
    }

    // Championship fight simulation (could be enhanced)
    if (behind.position <= 3 && ahead.position <= 3) {
      multiplier *= 1.3; // Championship contenders fight harder
    }

    return multiplier;
  }

  /// NEW: Calculate position protection multiplier - heavily protects track position early in race
  static double _getPositionProtectionMultiplier(Driver ahead, Driver behind, int currentLap) {
    // Early race protection - track position is king
    if (currentLap <= 5) {
      // MASSIVE protection for pole position (P1)
      if (ahead.position == 1) {
        return 0.15; // 85% reduction in overtaking probability
      }

      // Strong protection for front row (P2)
      if (ahead.position == 2) {
        return 0.25; // 75% reduction
      }

      // Good protection for top 3
      if (ahead.position <= 3) {
        return 0.4; // 60% reduction
      }

      // Moderate protection for top 6 (Q3 positions)
      if (ahead.position <= 6) {
        return 0.6; // 40% reduction
      }

      // Some protection for top 10
      if (ahead.position <= 10) {
        return 0.8; // 20% reduction
      }

      // Everyone else has minimal protection
      return 0.9; // 10% reduction
    }

    // Reduced protection for laps 6-15 (still some track position value)
    else if (currentLap <= 15) {
      if (ahead.position == 1) {
        return 0.7; // 30% reduction for leader
      }
      if (ahead.position <= 3) {
        return 0.85; // 15% reduction for podium positions
      }
      return 0.95; // 5% reduction for others
    }

    // After lap 15, no special position protection
    return 1.0;
  }

  /// Check if driver is within DRS detection zone (1 second behind)
  static bool _isWithinDRSRange(Driver behind, Driver ahead) {
    // Simplified: assume drivers are within DRS range if they're consecutive positions
    // and the behind driver has reasonable pace
    return ahead.position == behind.position - 1;
  }

  /// Attempt an overtaking maneuver
  static OvertakingResult attemptOvertake(
      Driver behind, Driver ahead, Track track, WeatherCondition weather, int currentLap) {
    // Determine overtaking method based on track and situation
    OvertakingMethod method = _selectOvertakingMethod(track, weather);

    // Calculate success probability for this specific method
    double successProbability = _getMethodSuccessProbability(behind, ahead, method, track, weather);

    bool successful = Random().nextDouble() < successProbability;

    if (successful) {
      return OvertakingResult(
        successful: true,
        method: _getMethodDescription(method),
        timeLost: 0.0,
        incidentDescription: "",
      );
    } else {
      // Failed overtaking attempt
      return _generateFailedOvertakeResult(behind, ahead, method, track);
    }
  }

  /// Select overtaking method based on track characteristics
  static OvertakingMethod _selectOvertakingMethod(Track track, WeatherCondition weather) {
    double random = Random().nextDouble();

    if (weather == WeatherCondition.rain) {
      // Wet weather favors late braking and opportunistic moves
      return random < 0.6 ? OvertakingMethod.lateBraking : OvertakingMethod.cornerExit;
    }

    switch (track.type) {
      case TrackType.power:
        // Power tracks favor slipstream overtakes
        return random < 0.7 ? OvertakingMethod.slipstream : OvertakingMethod.lateBraking;

      case TrackType.street:
        // Street circuits - limited opportunities, mostly late braking
        return random < 0.8 ? OvertakingMethod.lateBraking : OvertakingMethod.cornerExit;

      case TrackType.technical:
        // Technical tracks - various methods possible
        if (random < 0.4) return OvertakingMethod.cornerExit;
        if (random < 0.7) return OvertakingMethod.lateBraking;
        return OvertakingMethod.slipstream;

      default:
        // Mixed tracks - balanced approach
        if (random < 0.4) return OvertakingMethod.slipstream;
        if (random < 0.7) return OvertakingMethod.lateBraking;
        return OvertakingMethod.cornerExit;
    }
  }

  /// Get success probability for specific overtaking method
  static double _getMethodSuccessProbability(
      Driver behind, Driver ahead, OvertakingMethod method, Track track, WeatherCondition weather) {
    double baseProbability = 0.5;

    switch (method) {
      case OvertakingMethod.slipstream:
        // Favor high-speed drivers and good cars
        baseProbability = (behind.speed + behind.carPerformance) / 200.0;
        break;

      case OvertakingMethod.lateBraking:
        // Favor consistent drivers who can brake precisely
        baseProbability = (behind.consistency * 0.6 + behind.speed * 0.4) / 100.0;
        break;

      case OvertakingMethod.cornerExit:
        // Favor tire management and car balance
        baseProbability = (behind.tyreManagementSkill * 0.4 + behind.carPerformance * 0.6) / 100.0;
        break;

      case OvertakingMethod.opportunistic:
        // Favor experienced drivers who can spot opportunities
        baseProbability = _getDriverRacecraft(behind);
        break;
    }

    // Weather affects success rates
    if (weather == WeatherCondition.rain) {
      baseProbability *= 0.8; // Riskier in wet conditions
    }

    return baseProbability.clamp(0.2, 0.8);
  }

  /// Generate description for overtaking method
  static String _getMethodDescription(OvertakingMethod method) {
    switch (method) {
      case OvertakingMethod.slipstream:
        return "(slipstream down main straight)";
      case OvertakingMethod.lateBraking:
        return "(late braking into corner)";
      case OvertakingMethod.cornerExit:
        return "(better corner exit)";
      case OvertakingMethod.opportunistic:
        return "(opportunistic move)";
    }
  }

  /// Generate result for failed overtaking attempt
  static OvertakingResult _generateFailedOvertakeResult(
      Driver behind, Driver ahead, OvertakingMethod method, Track track) {
    double timeLost = 0.5 + Random().nextDouble() * 1.5; // 0.5-2.0 seconds lost
    String incident = "";

    // Small chance of collision or major incident
    if (Random().nextDouble() < 0.05) {
      if (Random().nextDouble() < 0.3) {
        // Contact/collision
        incident = "${behind.name} and ${ahead.name} make contact in overtaking attempt";
        timeLost = 3.0 + Random().nextDouble() * 5.0;
        behind
            .recordIncident("Contact with ${ahead.name} during overtaking attempt (+${timeLost.toStringAsFixed(1)}s)");
        ahead.recordIncident("Contact with ${behind.name} during defensive move (+1.0s)");
      } else {
        // Lock-up or error
        incident = "${behind.name} locks up attempting to overtake ${ahead.name}";
        timeLost = 2.0 + Random().nextDouble() * 3.0;
        behind.recordIncident("Lock-up during overtaking attempt (+${timeLost.toStringAsFixed(1)}s)");
      }
    }

    return OvertakingResult(
      successful: false,
      method: _getMethodDescription(method),
      timeLost: timeLost,
      incidentDescription: incident,
    );
  }

  /// Execute successful overtaking move
  static void _executeSuccessfulOvertake(Driver overtaker, Driver overtaken, List<Driver> sortedDrivers) {
    // Swap positions
    int overtakerPos = overtaker.position;
    int overtakenPos = overtaken.position;

    overtaker.updatePosition(overtakenPos);
    overtaken.updatePosition(overtakerPos);
  }

  /// Process failed overtaking attempt consequences
  static void _processFailliedOvertake(Driver behind, Driver ahead, OvertakingResult result, int currentLap) {
    if (result.timeLost > 0) {
      behind.totalTime += result.timeLost;
    }

    // Small chance the defending driver also loses time
    if (Random().nextDouble() < 0.2) {
      double defenderTimeLoss = 0.2 + Random().nextDouble() * 0.5;
      ahead.totalTime += defenderTimeLoss;
    }
  }

  /// Apply DRS effects to eligible drivers
  static void _applyDRSEffects(List<Driver> drivers, Track track) {
    // DRS provides advantage on power tracks
    if (track.type == TrackType.power || track.type == TrackType.mixed) {
      for (int i = 1; i < drivers.length; i++) {
        Driver driver = drivers[i];
        Driver driverAhead = drivers[i - 1];

        if (_isWithinDRSRange(driver, driverAhead) && !driver.isDNF() && !driverAhead.isDNF()) {
          // Small lap time improvement for DRS (already factored into overtaking probability)
          // This could be used for general lap time improvement when not overtaking
        }
      }
    }
  }

  /// Get overtaking statistics for the race
  static Map<String, dynamic> getOvertakingStatistics(List<Driver> drivers) {
    int totalOvertakes = 0;
    Map<String, int> driverOvertakes = {};
    Map<String, int> driverOvertaken = {};

    // Count position changes (simplified - would need better tracking in real implementation)
    for (Driver driver in drivers) {
      int positionGain = driver.startingPosition - driver.position;
      if (positionGain > 0) {
        driverOvertakes[driver.name] = positionGain;
        totalOvertakes += positionGain;
      } else if (positionGain < 0) {
        driverOvertaken[driver.name] = -positionGain;
      }
    }

    return {
      'totalOvertakes': totalOvertakes,
      'driverOvertakes': driverOvertakes,
      'driverOvertaken': driverOvertaken,
      'mostOvertaker':
          driverOvertakes.isNotEmpty ? driverOvertakes.entries.reduce((a, b) => a.value > b.value ? a : b).key : 'None',
    };
  }
}

/// Represents the result of an overtaking attempt
class OvertakingResult {
  final bool successful;
  final String method;
  final double timeLost;
  final String incidentDescription;

  OvertakingResult({
    required this.successful,
    required this.method,
    required this.timeLost,
    required this.incidentDescription,
  });
}

/// Different methods of overtaking
enum OvertakingMethod {
  slipstream, // Down the main straight with DRS/slipstream
  lateBraking, // Late braking into a corner
  cornerExit, // Better corner exit and acceleration
  opportunistic, // Taking advantage of mistakes/gaps
}

/// Enhanced constants for overtaking system
class OvertakingConstants {
  // Base overtaking probabilities per lap
  static const double baseOvertakingChance = 0.02;
  static const double maxOvertakingChance = 0.35;

  // DRS detection range (seconds gap)
  static const double drsDetectionRange = 1.0;
  static const double drsOvertakingBonus = 1.8;

  // Track type multipliers
  static const double streetCircuitMultiplier = 0.3;
  static const double powerTrackMultiplier = 1.4;
  static const double technicalTrackMultiplier = 0.8;

  // Method success rates
  static const double slipstreamSuccessRate = 0.7;
  static const double lateBrakingSuccessRate = 0.6;
  static const double cornerExitSuccessRate = 0.5;
  static const double opportunisticSuccessRate = 0.4;

  // Incident probabilities
  static const double contactChance = 0.05;
  static const double lockupChance = 0.1;

  // Time penalties
  static const double minTimeLoss = 0.5;
  static const double maxTimeLoss = 2.0;
  static const double contactTimeLoss = 5.0;
  static const double lockupTimeLoss = 3.0;

  // NEW: Position protection constants
  static const double poleProtectionLap1to5 = 0.15; // Massive protection for pole
  static const double frontRowProtectionLap1to5 = 0.25; // Strong protection for P2
  static const double topThreeProtectionLap1to5 = 0.4; // Good protection for P3

  // NEW: Tire advantage limits (UPDATED to match realistic compound deltas)
  static const double maxTireAdvantage = 0.15; // Reduced further to match new 0.25s max compound delta
  static const double softOverMediumAdvantage = 0.06; // Reduced to match new 0.25s delta
  static const double softOverHardAdvantage = 0.08; // Reduced to match new 0.4s total gap
  static const double mediumOverHardAdvantage = 0.03; // Reduced to match new 0.15s delta
}
