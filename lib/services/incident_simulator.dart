import 'dart:math';
import 'package:real_formula/models/track.dart';

import '../models/driver.dart';
import '../models/enums.dart';
import '../utils/constants.dart';

class IncidentSimulator {
  static double calculateDriverErrorProbability(
      Driver driver, int currentLap, int totalLaps, WeatherCondition weather) {
    double raceErrorProbability;

    // Base error probability based on consistency (1% to 18% per race)
    double consistencyRange = 100.0 - 50.0;
    double probabilityRange = F1Constants.maxErrorProbability - F1Constants.minErrorProbability;
    double normalizedConsistency = (100.0 - driver.consistency) / consistencyRange;
    normalizedConsistency = normalizedConsistency.clamp(0.0, 1.0);

    raceErrorProbability = F1Constants.minErrorProbability + (normalizedConsistency * probabilityRange);

    // Convert race probability to per-lap probability
    double baseLapProbability = 1.0 - pow(1.0 - raceErrorProbability, 1.0 / totalLaps);

    // Modifying factors
    double modifyingFactors = 1.0;

    // Tire degradation increases error chance
    double tireDegradation = driver.calculateTyreDegradation();
    double tireErrorFactor = min(tireDegradation * 0.15, 0.25);
    modifyingFactors *= (1.0 + tireErrorFactor);

    // Late race pressure
    if (currentLap > totalLaps * 0.8) {
      modifyingFactors *= 1.1;
    }

    // Fighting for points positions
    if (driver.position >= 8 && driver.position <= 12) {
      modifyingFactors *= 1.05;
    }

    // Rookie factor
    if (driver.speed < 70) {
      modifyingFactors *= 1.15;
    }

    // Weather factor
    double weatherMultiplier = _calculateWeatherErrorMultiplier(driver, weather);
    modifyingFactors *= weatherMultiplier;

    double finalProbability = baseLapProbability * modifyingFactors;

    // Cap at reasonable maximum per lap
    double maxLapProbability = 1.0 - pow(1.0 - 0.50, 1.0 / totalLaps);
    return min(finalProbability, maxLapProbability);
  }

  static double _calculateWeatherErrorMultiplier(Driver driver, WeatherCondition weather) {
    if (weather == WeatherCondition.clear) return 1.0;

    double baseMultiplier = F1Constants.weatherErrorMultiplier;
    double consistencyFactor = (100 - driver.consistency) / 100.0;
    double additionalMultiplier = 1.0 + (consistencyFactor * 1.5);

    return baseMultiplier * additionalMultiplier;
  }

  static double calculateMechanicalFailureProbability(Driver driver, int currentLap, int totalLaps) {
    double raceFailureProbability;

    // Base failure probability based on reliability
    if (driver.reliability <= F1Constants.reliabilityThreshold) {
      raceFailureProbability = F1Constants.lowReliabilityFailureRate;
    } else {
      double reliabilityRange = 100.0 - 71.0;
      double probabilityRange = F1Constants.maxReliabilityFailureRate - F1Constants.highReliabilityFailureRate;
      double normalizedReliability = (driver.reliability - 71.0) / reliabilityRange;
      raceFailureProbability = F1Constants.maxReliabilityFailureRate - (normalizedReliability * probabilityRange);
    }

    // Convert race probability to per-lap probability
    double baseLapProbability = 1.0 - pow(1.0 - raceFailureProbability, 1.0 / totalLaps);

    // Minor factors
    double minorFactors = 1.0;

    // Late race factor
    double lateRaceFactor = 1.0 + (currentLap / totalLaps) * 0.15;
    minorFactors *= lateRaceFactor;

    // Driver stress factor
    if (driver.speed > 90) {
      minorFactors *= 1.05;
    }

    // Already had issues factor
    if (driver.mechanicalIssuesCount > 0) {
      minorFactors *= 1.1;
    }

    double finalProbability = baseLapProbability * minorFactors;

    // Cap at reasonable maximum per lap
    double maxLapProbability = 1.0 - pow(1.0 - 0.25, 1.0 / totalLaps);
    return min(finalProbability, maxLapProbability);
  }

  static DriverErrorType? processDriverError(Driver driver, int currentLap, int totalLaps, WeatherCondition weather) {
    double errorProbability = calculateDriverErrorProbability(driver, currentLap, totalLaps, weather);

    if (Random().nextDouble() < errorProbability) {
      driver.errorCount++;

      double random = Random().nextDouble();

      // Weather affects error severity
      double crashChance = weather == WeatherCondition.rain ? F1Constants.crashChanceWet : F1Constants.crashChanceDry;
      double majorErrorChance =
          weather == WeatherCondition.rain ? F1Constants.majorErrorChanceWet : F1Constants.majorErrorChanceDry;

      if (random < crashChance && driver.consistency < 60) {
        return DriverErrorType.crash;
      } else if (random < majorErrorChance) {
        return DriverErrorType.majorSpin;
      } else if (random < F1Constants.lockupChance) {
        return DriverErrorType.lockup;
      } else {
        return DriverErrorType.minorMistake;
      }
    }

    return null;
  }

  static MechanicalFailureType? processMechanicalFailure(Driver driver, int currentLap, int totalLaps) {
    // Skip if already has active mechanical issue
    if (driver.hasActiveMechanicalIssue) return null;

    double failureProbability = calculateMechanicalFailureProbability(driver, currentLap, totalLaps);

    if (Random().nextDouble() < failureProbability) {
      driver.mechanicalIssuesCount++;

      double random = Random().nextDouble();

      if (random < F1Constants.terminalFailureChance && driver.team.reliability < F1Constants.reliabilityThreshold) {
        return MechanicalFailureType.terminalFailure;
      } else if (random < F1Constants.engineIssueChance) {
        return MechanicalFailureType.engineIssue;
      } else if (random < F1Constants.gearboxProblemChance) {
        return MechanicalFailureType.gearboxProblem;
      } else if (random < F1Constants.brakeIssueChance) {
        return MechanicalFailureType.brakeIssue;
      } else if (random < F1Constants.suspensionDamageChance) {
        return MechanicalFailureType.suspensionDamage;
      } else {
        return MechanicalFailureType.hydraulicLeak;
      }
    }

    return null;
  }

  static double applyDriverError(Driver driver, DriverErrorType errorType, int currentLap) {
    double timePenalty = 0.0;
    String description = "";

    switch (errorType) {
      case DriverErrorType.minorMistake:
        timePenalty = F1Constants.minorMistakeMin +
            Random().nextDouble() * (F1Constants.minorMistakeMax - F1Constants.minorMistakeMin);
        description = "Minor mistake";
        break;
      case DriverErrorType.majorSpin:
        timePenalty =
            F1Constants.majorSpinMin + Random().nextDouble() * (F1Constants.majorSpinMax - F1Constants.majorSpinMin);
        description = "SPIN - Major error";
        break;
      case DriverErrorType.lockup:
        timePenalty = F1Constants.lockupMin + Random().nextDouble() * (F1Constants.lockupMax - F1Constants.lockupMin);
        description = "Brake lockup";
        break;
      case DriverErrorType.crash:
        timePenalty = double.infinity;
        description = "CRASH - DNF";
        break;
    }

    String incident =
        "Lap $currentLap: $description (+${timePenalty.isFinite ? timePenalty.toStringAsFixed(1) + 's' : 'DNF'})";
    driver.recordIncident(incident);

    return timePenalty;
  }

  static double applyMechanicalFailure(Driver driver, MechanicalFailureType failureType, int currentLap) {
    double immediatePenalty = 0.0;

    switch (failureType) {
      case MechanicalFailureType.engineIssue:
        driver.hasActiveMechanicalIssue = true;
        driver.mechanicalIssueLapsRemaining =
            F1Constants.engineIssueMin + Random().nextInt(F1Constants.engineIssueMax - F1Constants.engineIssueMin + 1);
        driver.currentIssueDescription = "Engine power loss";
        immediatePenalty = 2.0;
        break;
      case MechanicalFailureType.gearboxProblem:
        driver.hasActiveMechanicalIssue = true;
        driver.mechanicalIssueLapsRemaining = F1Constants.gearboxProblemMin +
            Random().nextInt(F1Constants.gearboxProblemMax - F1Constants.gearboxProblemMin + 1);
        driver.currentIssueDescription = "Gearbox issues";
        immediatePenalty = 1.5;
        break;
      case MechanicalFailureType.brakeIssue:
        driver.hasActiveMechanicalIssue = true;
        driver.mechanicalIssueLapsRemaining =
            F1Constants.brakeIssueMin + Random().nextInt(F1Constants.brakeIssueMax - F1Constants.brakeIssueMin + 1);
        driver.currentIssueDescription = "Brake problems";
        immediatePenalty = 3.0;
        break;
      case MechanicalFailureType.suspensionDamage:
        driver.hasActiveMechanicalIssue = true;
        driver.mechanicalIssueLapsRemaining = F1Constants.suspensionDamageMin +
            Random().nextInt(F1Constants.suspensionDamageMax - F1Constants.suspensionDamageMin + 1);
        driver.currentIssueDescription = "Suspension damage";
        immediatePenalty = 2.5;
        break;
      case MechanicalFailureType.hydraulicLeak:
        driver.hasActiveMechanicalIssue = true;
        driver.mechanicalIssueLapsRemaining = F1Constants.hydraulicLeakMin +
            Random().nextInt(F1Constants.hydraulicLeakMax - F1Constants.hydraulicLeakMin + 1);
        driver.currentIssueDescription = "Hydraulic leak";
        immediatePenalty = 1.0;
        break;
      case MechanicalFailureType.terminalFailure:
        immediatePenalty = double.infinity;
        driver.currentIssueDescription = "Terminal failure - DNF";
        break;
    }

    String incident = "Lap $currentLap: ${driver.currentIssueDescription}";
    driver.recordIncident(incident);

    return immediatePenalty;
  }

  static void processLapIncidents(
      Driver driver, int currentLap, int totalLaps, WeatherCondition weather, Track currentTrack) {
    // Check for driver errors
    DriverErrorType? driverError = processDriverError(driver, currentLap, totalLaps, weather);
    if (driverError != null) {
      double errorPenalty = applyDriverError(driver, driverError, currentLap);
      if (errorPenalty.isInfinite) {
        driver.totalTime = double.infinity;
      } else {
        driver.totalTime += errorPenalty;
      }
    }

    // Check for mechanical failures
    MechanicalFailureType? mechanicalFailure = processMechanicalFailure(driver, currentLap, totalLaps);
    if (mechanicalFailure != null) {
      double failurePenalty = applyMechanicalFailure(driver, mechanicalFailure, currentLap);
      if (failurePenalty.isInfinite) {
        driver.totalTime = double.infinity;
      } else {
        driver.totalTime += failurePenalty;
      }
    }
  }
}
