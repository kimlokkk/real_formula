import 'dart:math';
import 'package:real_formula/ui/minigames/qualifying_timing_challenge.dart';

import '../models/driver.dart';
import '../models/track.dart';
import '../models/enums.dart';
import '../models/qualifying.dart';

class QualifyingEngine {
  /// Simple qualifying lap time calculation
  static double calculateQualifyingLapTime(
    Driver driver,
    WeatherCondition weather,
    Track track,
  ) {
    // Base qualifying time (3% faster than race pace)
    double baseTime = track.baseLapTime * 0.97;

    // Driver skills (speed more important in qualifying)
    double speedFactor = (100 - driver.speed) * 0.015;
    double consistencyFactor = (100 - driver.consistency) * 0.008;
    double carFactor = (100 - driver.team.carPerformance) * 0.018;

    // Weather penalty
    double weatherPenalty = 0.0;
    if (weather == WeatherCondition.rain) {
      weatherPenalty = 2.5 + ((100 - driver.consistency) / 100.0 * 1.5);
    }

    // Random variation (consistency affects this)
    double consistencyRange = (100 - driver.consistency) / 100.0;
    double maxVariation = 0.3 * (0.5 + consistencyRange * 0.5);
    double random = (Random().nextDouble() * 2.0 * maxVariation) - maxVariation;

    // Qualifying "magic" - chance for exceptional lap
    double magicChance = (driver.speed + driver.consistency) / 200.0 * 0.1;
    if (Random().nextDouble() < magicChance) {
      random -= 0.2; // Exceptional lap bonus
    }

    return baseTime + speedFactor + consistencyFactor + carFactor + weatherPenalty + random;
  }

  /// Calculate player qualifying time using mini-game result
  static double _calculatePlayerQualifyingTime(
    Driver driver,
    WeatherCondition weather,
    Track track,
    QualifyingTimingResult minigameResult,
  ) {
    // Use same calculation as mini-game
    double baseTime = track.baseLapTime * 0.97; // Qualifying pace

    // Apply driver skills
    double speedFactor = (100 - driver.speed) * 0.015;
    double consistencyFactor = (100 - driver.consistency) * 0.008;
    double carFactor = (100 - driver.team.carPerformance) * 0.018;

    double driverAdjustedTime = baseTime + speedFactor + consistencyFactor + carFactor;

    // Apply weather penalty if any
    if (weather == WeatherCondition.rain) {
      double weatherPenalty = 2.5 + ((100 - driver.consistency) / 100.0 * 1.5);
      driverAdjustedTime += weatherPenalty;
    }

    // Apply minigame result
    driverAdjustedTime += minigameResult.timeModifier;

    return driverAdjustedTime;
  }

  /// Simulate complete qualifying session instantly
  static List<QualifyingResult> simulateQualifying(
    List<Driver> drivers,
    WeatherCondition weather,
    Track track, {
    Driver? playerDriver,
    QualifyingTimingResult? playerMinigameResult,
  }) {
    List<QualifyingResult> results = [];

    // Calculate qualifying time for each driver
    for (Driver driver in drivers) {
      double bestTime = double.infinity;
      TireCompound bestTire = _selectBestTire(driver, weather);

      // Check if this is the player with a mini-game result
      if (playerDriver != null && driver.name == playerDriver.name && playerMinigameResult != null) {
        // Use mini-game calculation for player
        bestTime = _calculatePlayerQualifyingTime(driver, weather, track, playerMinigameResult);
      } else {
        // Normal AI simulation for other drivers
        for (int attempt = 1; attempt <= 3; attempt++) {
          double lapTime = calculateQualifyingLapTime(driver, weather, track);
          lapTime += bestTire.lapTimeDelta;

          if (lapTime < bestTime) {
            bestTime = lapTime;
          }
        }
      }

      results.add(QualifyingResult(
        driver: driver,
        bestLapTime: bestTime,
        position: 0,
        session: QualifyingSession.QUALIFYING,
        bestTire: bestTire,
      ));
    }

    // Sort by lap time and assign positions
    results.sort((a, b) => a.bestLapTime.compareTo(b.bestLapTime));

    // Calculate gaps and set positions
    double poleTime = results.isNotEmpty ? results.first.bestLapTime : 0.0;

    for (int i = 0; i < results.length; i++) {
      double gapToPole = i == 0 ? 0.0 : results[i].bestLapTime - poleTime;

      results[i] = results[i].copyWith(
        position: i + 1,
        gapToPole: gapToPole,
      );
    }

    return results;
  }

  /// Select best tire for qualifying
  static TireCompound _selectBestTire(Driver driver, WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      return Random().nextDouble() < 0.7 ? TireCompound.intermediate : TireCompound.wet;
    }

    // In dry conditions, everyone uses softs for qualifying
    return TireCompound.soft;
  }

  /// Apply qualifying results to set starting grid
  static void applyQualifyingResults(List<Driver> drivers, List<QualifyingResult> results) {
    // Set starting positions based on qualifying
    for (int i = 0; i < results.length; i++) {
      Driver driver = results[i].driver;
      driver.position = i + 1;
      driver.startingPosition = i + 1;
      driver.positionChangeFromStart = 0;

      // Set free tire choice for race
      _setRaceStartTire(driver);

      // Record qualifying result
      String qualifyingInfo = "Qualified P${i + 1} • Time: ${results[i].formattedLapTime}";
      qualifyingInfo += " • Starting tire: ${driver.currentCompound.name}";
      driver.recordIncident("QUALIFYING: $qualifyingInfo");
    }
  }

  /// Set tire choice for race start (strategic choice)
  static void _setRaceStartTire(Driver driver) {
    // Strategic tire choice based on grid position and car performance
    if (driver.startingPosition <= 3) {
      // Front runners: 50/50 soft vs medium
      driver.currentCompound = Random().nextDouble() < 0.5 ? TireCompound.soft : TireCompound.medium;
    } else if (driver.startingPosition <= 6) {
      // Midfield: mostly softs for early pace
      driver.currentCompound = Random().nextDouble() < 0.7 ? TireCompound.soft : TireCompound.medium;
    } else {
      // Back of grid: softs for overtaking opportunities
      driver.currentCompound = TireCompound.soft;
    }

    driver.hasFreeTireChoice = true;
  }

  /// Get qualifying summary for display
  static Map<String, dynamic> getQualifyingSummary(List<QualifyingResult> results) {
    if (results.isEmpty) return {};

    QualifyingResult polePosition = results.first;
    QualifyingResult lastPlace = results.last;
    double totalSpread = lastPlace.bestLapTime - polePosition.bestLapTime;

    return {
      'polePosition': polePosition,
      'totalSpread': totalSpread,
      'averageGap': totalSpread / (results.length - 1),
      'fastestSector': polePosition.bestLapTime,
    };
  }
}
