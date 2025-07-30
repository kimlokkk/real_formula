// lib/services/performance_calculator.dart - REALISTIC F1 performance calculation with racing context

import 'dart:math';
import 'package:real_formula/models/track.dart';

import '../models/driver.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

/// Enhanced performance calculator that accounts for realistic F1 racing dynamics
/// including dirty air, track position effects, tire warming, and strategic conservatism
class PerformanceCalculator {
  /// Calculate base lap time from car performance
  static double calculateBaseLapTime(Driver driver) {
    // Base lap time: 90 seconds + car performance penalty
    double baseTime = F1Constants.baseLapTime;

    // CAR PERFORMANCE (60% of total performance difference)
    // Range: 0 to +0.375s penalty (McLaren 98 -> Sauber 72)
    double carTimePenalty = (100 - driver.team.carPerformance) * F1Constants.carPerformanceWeight;

    return baseTime + carTimePenalty;
  }

  /// Calculate driver skills impact on lap time
  static double calculateDriverSkillsImpact(Driver driver) {
    // DRIVER SKILLS (40% of total performance difference)
    // Properly distributed based on lap time relevance

    // Speed: Main driver skill for lap time (25% of total performance)
    double speedFactor = (100 - driver.speed) * F1Constants.speedWeight;

    // Consistency: Affects baseline performance (10% of total performance)
    double consistencyFactor = (100 - driver.consistency) * F1Constants.consistencyWeight;

    // Tire Management: Base impact (5% of total performance)
    double tireManagementFactor = (100 - driver.tyreManagementSkill) * F1Constants.tireManagementWeight;

    return speedFactor + consistencyFactor + tireManagementFactor;
  }

  /// Calculate weather-related lap time penalty
  static double calculateWeatherLapTimePenalty(Driver driver, WeatherCondition weather) {
    if (weather == WeatherCondition.clear) return 0.0;

    // WET WEATHER PENALTY SYSTEM:
    // Uses same 60% car / 40% skill split as dry weather
    // But with different skill weightings for wet conditions

    // PART 1: CAR PERFORMANCE FACTOR (60% of total wet weather difference)
    // Worse cars struggle more in wet conditions
    double carWetPenalty = (100 - driver.team.carPerformance) * F1Constants.carWetPenalty;

    // PART 2: DRIVER SKILLS FACTOR (40% of total wet weather difference)
    // Consistency: 30% of total performance (main wet weather skill)
    double consistencyWetFactor = (100 - driver.consistency) * F1Constants.consistencyWetFactor;

    // Speed: 7% of total performance (still matters but less than dry)
    double speedWetFactor = (100 - driver.speed) * F1Constants.speedWetFactor;

    // Tire Management: 3% of total performance (wet tire feel)
    double tireWetFactor = (100 - driver.tyreManagementSkill) * F1Constants.tireWetFactor;

    // PART 3: BASE WET WEATHER PENALTY (affects everyone equally)
    double baseWetPenalty = F1Constants.baseWetPenalty;

    // PART 4: RANDOM TRACK CONDITIONS
    double randomFactor = (Random().nextDouble() * F1Constants.wetRandomVariation * 2) - F1Constants.wetRandomVariation;

    double totalPenalty =
        baseWetPenalty + carWetPenalty + consistencyWetFactor + speedWetFactor + tireWetFactor + randomFactor;

    return totalPenalty;
  }

  /// Calculate mechanical issue penalty per lap
  static double calculateMechanicalIssuePenalty(Driver driver) {
    if (!driver.hasActiveMechanicalIssue) return 0.0;

    double penalty = 0.0;

    switch (driver.currentIssueDescription) {
      case "Engine power loss":
        penalty = F1Constants.enginePenaltyMin +
            Random().nextDouble() * (F1Constants.enginePenaltyMax - F1Constants.enginePenaltyMin);
        break;
      case "Gearbox issues":
        penalty = Random().nextDouble() < F1Constants.gearboxPenaltyChance ? F1Constants.gearboxPenalty : 0.0;
        break;
      case "Brake problems":
        penalty = F1Constants.brakePenaltyMin +
            Random().nextDouble() * (F1Constants.brakePenaltyMax - F1Constants.brakePenaltyMin);
        break;
      case "Suspension damage":
        penalty = F1Constants.suspensionPenaltyMin +
            Random().nextDouble() * (F1Constants.suspensionPenaltyMax - F1Constants.suspensionPenaltyMin);
        break;
      case "Hydraulic leak":
        penalty = F1Constants.hydraulicPenaltyMin +
            Random().nextDouble() * (F1Constants.hydraulicPenaltyMax - F1Constants.hydraulicPenaltyMin);
        break;
    }

    return penalty;
  }

  /// Apply track-specific tire degradation multiplier
  static double calculateTrackAdjustedTireDegradation(Driver driver, Track currentTrack) {
    // Get base tire degradation from driver's enhanced calculation
    double baseTyreDeg = driver.calculateTyreDegradation();

    // Apply track-specific tire degradation multiplier
    double trackAdjustedTyreDeg = baseTyreDeg * currentTrack.tireDegradationMultiplier;

    return trackAdjustedTyreDeg;
  }

  /// NEW: Calculate realistic racing context effects
  /// This is what was missing - F1 cars don't race in isolation!
  static double calculateRacingContextEffects(
      Driver driver, int currentLap, int totalLaps, int driverPosition, List<Driver> allDrivers, Track track) {
    double contextPenalty = 0.0;

    // 1. DIRTY AIR EFFECTS - following cars lose significant performance
    if (driverPosition > 1) {
      Driver carAhead = allDrivers.firstWhere((d) => d.position == driverPosition - 1, orElse: () => driver);

      if (carAhead != driver && !carAhead.isDNF()) {
        double gapToCarAhead = driver.totalTime - carAhead.totalTime;

        // Dirty air penalty based on gap (closer = worse performance)
        // These values match real F1 dirty air effects (0.3-0.5s in reality)
        if (gapToCarAhead < 1.0) {
          contextPenalty += 0.4; // Severe dirty air penalty when very close
        } else if (gapToCarAhead < 2.0) {
          contextPenalty += 0.25; // Moderate dirty air penalty
        } else if (gapToCarAhead < 3.0) {
          contextPenalty += 0.15; // Light dirty air penalty
        }
        // Beyond 3 seconds gap = clean air

        // Track-specific dirty air effects
        if (track.type == TrackType.street || track.overtakingDifficulty < 0.4) {
          contextPenalty *= 1.3; // Worse dirty air on narrow street circuits (Monaco)
        } else if (track.type == TrackType.power) {
          contextPenalty *= 0.7; // Less dirty air impact on power tracks (Monza)
        }
      }
    }

    // 2. EARLY RACE CAUTION PHASE (laps 1-10)
    // Everyone drives more conservatively at race start to avoid incidents
    if (currentLap <= 10) {
      double cautionFactor = 1.0 - (currentLap / 10.0); // 100% caution on lap 1, 0% on lap 10
      contextPenalty += cautionFactor * 0.2; // Up to 0.2s penalty for early race caution

      // Extra caution for drivers in intense midfield battles
      if (driverPosition > 1 && driverPosition <= 6) {
        contextPenalty += cautionFactor * 0.1; // Extra 0.1s for midfield position fights
      }
    }

    // 3. TIRE WARMING EFFECTS - cold tires are slower
    // First few laps after pit stops have reduced performance
    if (driver.lapsOnCurrentTires <= 2) {
      if (driver.lapsOnCurrentTires == 0) {
        contextPenalty += 0.2; // Out-lap penalty (very cold tires)
      } else if (driver.lapsOnCurrentTires == 1) {
        contextPenalty += 0.1; // Still warming up on lap 2
      }
      // Lap 3+ = fully warmed tires
    }

    // 4. STRATEGIC POSITION PROTECTION
    // Leaders and podium contenders drive more conservatively early in race
    if (currentLap <= 15 && driverPosition <= 3) {
      // Front runners protect their position rather than taking risks
      contextPenalty += 0.1; // Conservative driving to protect track position
    }

    // 5. TRAFFIC MANAGEMENT
    // Cars in the midfield (fighting for points) drive more cautiously
    if (driverPosition >= 8 && driverPosition <= 12 && currentLap <= 20) {
      contextPenalty += 0.05; // Slight caution in points battles
    }

    return contextPenalty;
  }

  /// NEW: Calculate contextual tire compound advantages
  /// Tire compound advantages are reduced in certain racing conditions
  static double calculateContextualCompoundDelta(
      Driver driver, int currentLap, int driverPosition, List<Driver> allDrivers) {
    double baseDelta = driver.currentCompound.lapTimeDelta;

    // DIRTY AIR REDUCTION
    // Compound advantages are significantly reduced when following other cars
    if (driverPosition > 1) {
      Driver carAhead = allDrivers.firstWhere((d) => d.position == driverPosition - 1, orElse: () => driver);

      if (carAhead != driver && !carAhead.isDNF()) {
        double gapToCarAhead = driver.totalTime - carAhead.totalTime;

        // The closer you follow, the less tire compound advantage you get
        if (gapToCarAhead < 2.0) {
          baseDelta *= 0.6; // 40% reduction in compound advantage in heavy dirty air
        } else if (gapToCarAhead < 4.0) {
          baseDelta *= 0.8; // 20% reduction in moderate dirty air
        }
        // Clean air = full compound advantage
      }
    }

    // EARLY RACE TIRE WARMING
    // Compound differences are smaller when tires aren't fully warmed up
    if (currentLap <= 5) {
      baseDelta *= 0.7; // 30% reduction in early race (tires still warming)
    } else if (currentLap <= 10) {
      baseDelta *= 0.85; // 15% reduction in mid-early race
    }
    // After lap 10 = full compound advantage

    return baseDelta;
  }

  /// MAIN METHOD: Calculate current lap time with full racing context
  /// This now accounts for all realistic F1 racing factors
  static double calculateCurrentLapTime(Driver driver, WeatherCondition weather, Track currentTrack,
      {int currentLap = 1, List<Driver>? allDrivers}) {
    // Get racing context
    int driverPosition = driver.position;
    List<Driver> driversForContext = allDrivers ?? [driver];
    int totalLaps = currentTrack.totalLaps;

    // CORE PERFORMANCE COMPONENTS
    double baseTime = calculateBaseLapTime(driver);
    double skillsImpact = calculateDriverSkillsImpact(driver);
    double tyreDeg = calculateTrackAdjustedTireDegradation(driver, currentTrack);

    // CONSISTENCY-BASED RANDOM VARIATION
    double consistencyFactor = driver.consistency / 100.0;
    double maxRandomVariation = 0.5 * (1.0 - consistencyFactor * 0.6);
    double random = (Random().nextDouble() * 2.0 * maxRandomVariation) - maxRandomVariation;

    // WEATHER EFFECTS
    double weatherPenalty = calculateWeatherLapTimePenalty(driver, weather);

    // CONTEXTUAL TIRE COMPOUND ADVANTAGE (reduced in traffic/early race)
    double compoundDelta = calculateContextualCompoundDelta(driver, currentLap, driverPosition, driversForContext);

    // MECHANICAL ISSUES
    double mechanicalPenalty = calculateMechanicalIssuePenalty(driver);

    // NEW: RACING CONTEXT EFFECTS (dirty air, early race caution, etc.)
    double contextEffects =
        calculateRacingContextEffects(driver, currentLap, totalLaps, driverPosition, driversForContext, currentTrack);

    // Update mechanical issue countdown
    if (driver.hasActiveMechanicalIssue) {
      driver.mechanicalIssueLapsRemaining--;
      if (driver.mechanicalIssueLapsRemaining <= 0) {
        driver.hasActiveMechanicalIssue = false;
        String resolvedIssue = driver.currentIssueDescription;
        driver.currentIssueDescription = "";
        driver.recordIncident("Lap ${driver.lapsCompleted + 1}: $resolvedIssue resolved");
      }
    }

    // FINAL LAP TIME CALCULATION
    return baseTime +
        skillsImpact +
        tyreDeg +
        weatherPenalty +
        compoundDelta +
        mechanicalPenalty +
        contextEffects +
        random;
  }

  /// DEBUGGING: Get detailed breakdown of lap time components
  static Map<String, double> getLapTimeBreakdown(Driver driver, WeatherCondition weather, Track currentTrack,
      {int currentLap = 1, List<Driver>? allDrivers}) {
    int driverPosition = driver.position;
    List<Driver> driversForContext = allDrivers ?? [driver];
    int totalLaps = currentTrack.totalLaps;

    return {
      'baseTime': calculateBaseLapTime(driver),
      'skillsImpact': calculateDriverSkillsImpact(driver),
      'tireDegradation': calculateTrackAdjustedTireDegradation(driver, currentTrack),
      'weatherPenalty': calculateWeatherLapTimePenalty(driver, weather),
      'compoundDelta': calculateContextualCompoundDelta(driver, currentLap, driverPosition, driversForContext),
      'mechanicalPenalty': calculateMechanicalIssuePenalty(driver),
      'contextEffects':
          calculateRacingContextEffects(driver, currentLap, totalLaps, driverPosition, driversForContext, currentTrack),
    };
  }

  /// Helper method to get tire degradation info for debugging/UI
  static Map<String, double> getTireDegradationBreakdown(Driver driver, Track currentTrack) {
    double baseDegradation = driver.calculateTyreDegradation();
    double trackMultiplier = currentTrack.tireDegradationMultiplier;
    double trackAdjusted = baseDegradation * trackMultiplier;

    return {
      'base': baseDegradation,
      'trackMultiplier': trackMultiplier,
      'trackAdjusted': trackAdjusted,
      'cliffPenalty': driver.getCompoundCliffPenalty(),
    };
  }

  /// Predict lap time for strategy decisions (without random elements)
  static double predictLapTimeInFuture(Driver driver, WeatherCondition weather, Track currentTrack, int lapsAhead) {
    double baseTime = calculateBaseLapTime(driver);
    double skillsImpact = calculateDriverSkillsImpact(driver);

    // Predict future tire degradation
    double futureTyreDeg = driver.predictDegradationInLaps(lapsAhead) * currentTrack.tireDegradationMultiplier;

    double weatherPenalty = calculateWeatherLapTimePenalty(driver, weather);
    double compoundDelta = driver.currentCompound.lapTimeDelta;

    // Don't include random variation, mechanical issues, or context effects in prediction
    return baseTime + skillsImpact + futureTyreDeg + weatherPenalty + compoundDelta;
  }
}
