import 'dart:math';
import 'package:real_formula/models/track.dart';

import '../models/driver.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

class PerformanceCalculator {
  static double calculateBaseLapTime(Driver driver) {
    // Base lap time: 90 seconds + car performance penalty
    double baseTime = F1Constants.baseLapTime;

    // CAR PERFORMANCE (60% of total performance difference)
    // Range: 0 to +0.375s penalty (Red Bull 98 -> Williams 75)
    double carTimePenalty = (100 - driver.carPerformance) * F1Constants.carPerformanceWeight;

    return baseTime + carTimePenalty;
  }

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

  static double calculateWeatherLapTimePenalty(Driver driver, WeatherCondition weather) {
    if (weather == WeatherCondition.clear) return 0.0;

    // WET WEATHER PENALTY SYSTEM:
    // Uses same 60% car / 40% skill split as dry weather
    // But with different skill weightings for wet conditions

    // PART 1: CAR PERFORMANCE FACTOR (60% of total wet weather difference)
    // Worse cars struggle more in wet conditions
    double carWetPenalty = (100 - driver.carPerformance) * F1Constants.carWetPenalty;

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

  static double calculateWeatherErrorMultiplier(Driver driver, WeatherCondition weather) {
    if (weather == WeatherCondition.clear) return 1.0;

    // Rain increases error probability significantly
    double baseMultiplier = F1Constants.weatherErrorMultiplier;

    // Less consistent drivers struggle even more in rain
    double consistencyFactor = (100 - driver.consistency) / 100.0;
    double additionalMultiplier = 1.0 + (consistencyFactor * 1.5);

    return baseMultiplier * additionalMultiplier;
  }

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

  // ENHANCED: Apply track-specific tire degradation multiplier
  static double calculateTrackAdjustedTireDegradation(Driver driver, Track currentTrack) {
    // Get base tire degradation from driver's enhanced calculation
    double baseTyreDeg = driver.calculateTyreDegradation();

    // Apply track-specific tire degradation multiplier
    double trackAdjustedTyreDeg = baseTyreDeg * currentTrack.tireDegradationMultiplier;

    return trackAdjustedTyreDeg;
  }

  static double calculateCurrentLapTime(Driver driver, WeatherCondition weather, Track currentTrack) {
    double baseTime = calculateBaseLapTime(driver);
    double skillsImpact = calculateDriverSkillsImpact(driver);

    // ENHANCED: Use track-adjusted tire degradation instead of base degradation
    double tyreDeg = calculateTrackAdjustedTireDegradation(driver, currentTrack);

    // Consistency affects random variation
    double consistencyFactor = driver.consistency / 100.0;
    double maxRandomVariation = 0.5 * (1.0 - consistencyFactor * 0.6);
    double random = (Random().nextDouble() * 2.0 * maxRandomVariation) - maxRandomVariation;

    // Weather penalty
    double weatherPenalty = calculateWeatherLapTimePenalty(driver, weather);

    // Compound performance impact
    double compoundDelta = driver.currentCompound.lapTimeDelta;

    // Mechanical issue penalty
    double mechanicalPenalty = calculateMechanicalIssuePenalty(driver);

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

    return baseTime + skillsImpact + tyreDeg + weatherPenalty + compoundDelta + mechanicalPenalty + random;
  }

  // NEW: Helper method to get tire degradation info for debugging/UI
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

  // NEW: Predict lap time for strategy decisions
  static double predictLapTimeInFuture(Driver driver, WeatherCondition weather, Track currentTrack, int lapsAhead) {
    double baseTime = calculateBaseLapTime(driver);
    double skillsImpact = calculateDriverSkillsImpact(driver);

    // Predict future tire degradation
    double futureTyreDeg = driver.predictDegradationInLaps(lapsAhead) * currentTrack.tireDegradationMultiplier;

    double weatherPenalty = calculateWeatherLapTimePenalty(driver, weather);
    double compoundDelta = driver.currentCompound.lapTimeDelta;

    // Don't include random variation or mechanical issues in prediction
    return baseTime + skillsImpact + futureTyreDeg + weatherPenalty + compoundDelta;
  }
}
