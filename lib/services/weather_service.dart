import '../models/driver.dart';
import '../models/enums.dart';

class WeatherService {
  /// Gets weather-appropriate compound for current driver based on weather condition
  static TireCompound getWeatherAppropriateCompound(TireCompound currentCompound, WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      // Switch to wet weather compounds
      if (currentCompound == TireCompound.soft ||
          currentCompound == TireCompound.medium ||
          currentCompound == TireCompound.hard) {
        return TireCompound.intermediate; // Default to intermediate in rain
      }
      return currentCompound; // Already on wet compounds
    } else {
      // Switch to dry weather compounds
      if (currentCompound == TireCompound.intermediate || currentCompound == TireCompound.wet) {
        return TireCompound.medium; // Default to medium when dry
      }
      return currentCompound; // Already on dry compounds
    }
  }

  /// Handles weather change effects on all drivers
  static List<String> processWeatherChange(
      List<Driver> drivers, WeatherCondition oldWeather, WeatherCondition newWeather) {
    List<String> weatherChangeIncidents = [];

    for (Driver driver in drivers) {
      TireCompound oldCompound = driver.currentCompound;
      driver.currentCompound = getWeatherAppropriateCompound(driver.currentCompound, newWeather);

      // Log weather change and compound switches
      if (oldCompound != driver.currentCompound) {
        String weatherChange = "${oldWeather.name} → ${newWeather.name}";
        String compoundChange = "${oldCompound.name} → ${driver.currentCompound.name}";
        String incident = "Weather change: $weatherChange | Tire: $compoundChange";
        driver.recordIncident(incident);
        weatherChangeIncidents.add("${driver.name}: $incident");
      }
    }

    return weatherChangeIncidents;
  }

  /// Resets all drivers to appropriate starting compounds for current weather
  static void resetCompoundsForWeather(List<Driver> drivers, WeatherCondition weather) {
    for (Driver driver in drivers) {
      driver.currentCompound = driver.getWeatherAppropriateStartingCompound(weather);
      driver.lapsOnCurrentTires = 0; // Reset tire age
      driver.usedCompounds.clear();
    }
  }

  /// Gets tire compound distribution for UI display
  static Map<TireCompound, int> getCompoundDistribution(List<Driver> drivers) {
    Map<TireCompound, int> distribution = {};

    for (TireCompound compound in TireCompound.values) {
      distribution[compound] = 0;
    }

    for (Driver driver in drivers) {
      distribution[driver.currentCompound] = (distribution[driver.currentCompound] ?? 0) + 1;
    }

    return distribution;
  }

  /// Gets formatted string of tire compound distribution for UI
  static String getCompoundDistributionString(List<Driver> drivers) {
    Map<TireCompound, int> distribution = getCompoundDistribution(drivers);
    List<String> compoundStrings = [];

    for (TireCompound compound in TireCompound.values) {
      int count = distribution[compound] ?? 0;
      if (count > 0) {
        compoundStrings.add("${compound.icon}$count");
      }
    }

    return compoundStrings.join(" ");
  }

  /// Checks if weather condition is wet
  static bool isWetWeather(WeatherCondition weather) {
    return weather == WeatherCondition.rain;
  }

  /// Checks if a tire compound is appropriate for the weather
  static bool isCompoundAppropriateForWeather(TireCompound compound, WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      return compound == TireCompound.intermediate || compound == TireCompound.wet;
    } else {
      return compound == TireCompound.soft || compound == TireCompound.medium || compound == TireCompound.hard;
    }
  }

  /// Gets all available compounds for a weather condition
  static List<TireCompound> getAvailableCompounds(WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      return [TireCompound.intermediate, TireCompound.wet];
    } else {
      return [TireCompound.soft, TireCompound.medium, TireCompound.hard];
    }
  }

  /// Gets weather impact description for UI
  static String getWeatherImpactDescription(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return "Clear conditions - standard performance";
      case WeatherCondition.rain:
        return "Rain - 2.5x more errors, consistency more important, wet tires required";
    }
  }

  /// Gets weather-specific strategy advice
  static String getWeatherStrategyAdvice(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return "Focus on tire degradation and pit windows";
      case WeatherCondition.rain:
        return "Prioritize consistent drivers, expect more incidents";
    }
  }
}
