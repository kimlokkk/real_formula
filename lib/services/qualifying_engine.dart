import 'dart:math';
import 'package:real_formula/services/weather_generator.dart';
import 'package:real_formula/ui/minigames/qualifying_timing_challenge.dart';

import '../models/driver.dart';
import '../models/track.dart';
import '../models/enums.dart';
import '../models/qualifying.dart';

class QualifyingEngine {
  static RainIntensity? _currentSessionRainIntensity;

  /// Simple qualifying lap time calculation
  // Replace the calculateQualifyingLapTime function in qualifying_engine.dart with this debug version:

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

    double finalTime = baseTime + speedFactor + consistencyFactor + carFactor + weatherPenalty + random;

    // 🐛 DEBUG: Detailed breakdown for Max
    if (driver.name.contains("Max")) {
      print("🔍 MAX PENALTY BREAKDOWN:");
      print("   Track base lap time: ${track.baseLapTime}s");
      print("   Qualifying base (97%): ${baseTime.toStringAsFixed(3)}s");
      print("   Speed (${driver.speed}): +${speedFactor.toStringAsFixed(3)}s");
      print("   Consistency (${driver.consistency}): +${consistencyFactor.toStringAsFixed(3)}s");
      print("   Car (${driver.team.carPerformance}): +${carFactor.toStringAsFixed(3)}s");
      print("   Weather penalty: +${weatherPenalty.toStringAsFixed(3)}s");
      print("   Random variation: ${random >= 0 ? '+' : ''}${random.toStringAsFixed(3)}s");
      print("   Magic bonus applied: ${Random().nextDouble() < magicChance ? 'YES' : 'NO'}");
      print("   TOTAL FINAL TIME: ${finalTime.toStringAsFixed(3)}s");
      print("   TOTAL PENALTIES: ${(finalTime - baseTime).toStringAsFixed(3)}s");
    }

    return finalTime;
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
  /// Simulate complete qualifying session instantly
  static List<QualifyingResult> simulateQualifying(
    List<Driver> drivers,
    WeatherCondition weather,
    Track track, {
    Driver? playerDriver,
    QualifyingTimingResult? playerMinigameResult,
  }) {
    List<QualifyingResult> results = [];

    // 🔧 FIX: Generate and store rain intensity ONCE for the entire session
    if (weather == WeatherCondition.rain) {
      _currentSessionRainIntensity = WeatherGenerator.generateRainIntensity(track.name);
      print('🌧️ QUALIFYING SESSION: ${_currentSessionRainIntensity!.name} rain at ${track.name}');
    } else {
      _currentSessionRainIntensity = null;
    }

    // Calculate qualifying time for each driver
    for (Driver driver in drivers) {
      double bestTime = double.infinity;
      TireCompound bestTire = _selectBestTire(driver, weather, track.name, _currentSessionRainIntensity);

      // Check if this is the player with a mini-game result
      if (playerDriver != null && driver.name == playerDriver.name && playerMinigameResult != null) {
        // Use mini-game calculation for player
        bestTime = _calculatePlayerQualifyingTime(driver, weather, track, playerMinigameResult);

        // 🔧 FIX: Add contextual tire penalty to player
        double tirePenalty = getContextualTirePenalty(bestTire, weather);
        bestTime += tirePenalty;
      } else {
        // Normal AI simulation for other drivers
        for (int attempt = 1; attempt <= 3; attempt++) {
          double lapTime = calculateQualifyingLapTime(driver, weather, track);

          // 🔧 FIX: Add contextual tire penalty to AI
          double tirePenalty = getContextualTirePenalty(bestTire, weather);
          lapTime += tirePenalty;

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

  /// Get context-aware tire penalty (different for rain vs dry)
  static double getContextualTirePenalty(TireCompound tire, WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      // Rain conditions - different penalty structure
      switch (tire) {
        case TireCompound.intermediate:
          return 0.0; // Optimal choice in rain
        case TireCompound.wet:
          return 0.5; // Slightly slower but safer in light/moderate rain
        case TireCompound.soft:
        case TireCompound.medium:
        case TireCompound.hard:
          return 8.0; // Terrible choice in rain (no grip)
      }
    } else {
      // Dry conditions - use original tire penalties
      return tire.lapTimeDelta;
    }
  }

  /// Select best tire for qualifying based on rain intensity and driver/team factors
  static TireCompound _selectBestTire(
      Driver driver, WeatherCondition weather, String trackName, RainIntensity? sessionRainIntensity) {
    if (weather != WeatherCondition.rain) {
      return TireCompound.soft; // Dry conditions
    }

    return sessionRainIntensity!.optimalTire; // Rain conditions - everyone picks optimal
  }

  static TireCompound _selectRainTyre(Driver driver, RainIntensity intensity) {
    return intensity.optimalTire;
  }

  /// Apply qualifying results to set starting grid
  static void applyQualifyingResults(List<Driver> drivers, List<QualifyingResult> results, String trackName,
      {WeatherCondition? raceWeather}) {
    // Set starting positions based on qualifying
    for (int i = 0; i < results.length; i++) {
      Driver driver = results[i].driver;
      driver.position = i + 1;
      driver.startingPosition = i + 1;
      driver.positionChangeFromStart = 0;

      // 🔧 FIX: Set weather-appropriate starting tires with track name
      _setRaceStartTire(driver, trackName, raceWeather: raceWeather);

      // Record qualifying result
      String qualifyingInfo = "Qualified P${i + 1} • Time: ${results[i].formattedLapTime}";
      qualifyingInfo += " • Starting tire: ${driver.currentCompound.name}";
      driver.recordIncident("QUALIFYING: $qualifyingInfo");
    }
  }

  /// Set tire choice for race start (strategic choice)
  /// Set tire choice for race start (strategic choice)
  /// Set tire choice for race start (strategic choice)
  static void _setRaceStartTire(Driver driver, String trackName, {WeatherCondition? raceWeather}) {
    print('🔧 DEBUG: _setRaceStartTire called for ${driver.name} with weather ${raceWeather?.name ?? "null"}');

    // 🔧 FIX: In wet conditions, use the same session intensity as qualifying
    if (raceWeather == WeatherCondition.rain) {
      RainIntensity intensity = _currentSessionRainIntensity ?? WeatherGenerator.generateRainIntensity(trackName);
      driver.currentCompound = _selectRainTyre(driver, intensity);
      driver.hasFreeTireChoice = true;
      print('🔧 DEBUG: ${driver.name} assigned ${driver.currentCompound.name} for ${intensity.name} race');
      return;
    }

    // DRY WEATHER: Strategic tire choice based on grid position (unchanged)
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
    print('🔧 DEBUG: ${driver.name} assigned ${driver.currentCompound.name} for dry race');
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
