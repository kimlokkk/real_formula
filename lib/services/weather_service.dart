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

  /// Handles weather change effects on all drivers with compound rule consideration
  static List<String> processWeatherChange(
      List<Driver> drivers, WeatherCondition oldWeather, WeatherCondition newWeather) {
    List<String> weatherChangeIncidents = [];

    for (Driver driver in drivers) {
      TireCompound oldCompound = driver.currentCompound;
      TireCompound newCompound = getWeatherAppropriateCompound(driver.currentCompound, newWeather);

      // Special handling for compound rule when changing from wet to dry
      if (oldWeather == WeatherCondition.rain && newWeather == WeatherCondition.clear) {
        // When switching from wet to dry, consider compound rule
        List<TireCompound> availableDryCompounds = driver.availableDryCompounds;
        if (availableDryCompounds.isNotEmpty) {
          // Prefer a compound that satisfies the rule
          if (availableDryCompounds.contains(TireCompound.medium)) {
            newCompound = TireCompound.medium;
          } else {
            newCompound = availableDryCompounds.first;
          }
        }
      }

      driver.currentCompound = newCompound;

      // Track compound usage
      if (oldCompound != newCompound) {
        driver.recordCompoundUsage(oldCompound);
      }

      // Log weather change and compound switches
      if (oldCompound != driver.currentCompound) {
        String weatherChange = "${oldWeather.name} → ${newWeather.name}";
        String compoundChange = "${oldCompound.name} → ${driver.currentCompound.name}";

        // Add compound rule info
        String ruleInfo = "";
        if (newWeather == WeatherCondition.clear) {
          ruleInfo = driver.hasUsedTwoCompounds ? " [Rule satisfied]" : " [Rule pending]";
        }

        String incident = "Weather change: $weatherChange | Tire: $compoundChange$ruleInfo";
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
      driver.usedCompounds.clear(); // Reset compound usage tracking
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

  /// Gets compound rule compliance summary
  static Map<String, int> getCompoundRuleCompliance(List<Driver> drivers) {
    int compliant = 0;
    int pending = 0;
    int atRisk = 0;

    for (Driver driver in drivers) {
      if (driver.isDNF()) continue;

      if (driver.hasUsedTwoCompounds) {
        compliant++;
      } else {
        pending++;
        // Check if driver is at risk (late in race with only one compound used)
        // This would need access to current lap info, so we'll leave it simple for now
      }
    }

    return {
      'compliant': compliant,
      'pending': pending,
      'atRisk': atRisk,
    };
  }

  /// Gets detailed compound rule analysis for UI
  static String getCompoundRuleAnalysis(List<Driver> drivers) {
    Map<String, int> compliance = getCompoundRuleCompliance(drivers);
    int total = drivers.where((d) => !d.isDNF()).length;

    if (compliance['compliant']! == total) {
      return "✅ All drivers have satisfied the compound rule";
    } else if (compliance['pending']! > 0) {
      return "⚠️ ${compliance['pending']} driver${compliance['pending']! > 1 ? 's' : ''} still need to use a second compound";
    } else {
      return "🔄 Compound rule tracking in progress";
    }
  }

  /// Validates compound selection against weather and rule
  static bool isCompoundSelectionValid(Driver driver, TireCompound compound, WeatherCondition weather) {
    // Check weather appropriateness
    if (!isCompoundAppropriateForWeather(compound, weather)) {
      return false;
    }

    // Check compound rule compliance
    if (weather == WeatherCondition.clear) {
      List<TireCompound> availableCompounds = driver.availableDryCompounds;
      return availableCompounds.contains(compound);
    }

    return true;
  }

  /// Gets compound selection advice for a driver
  static String getCompoundSelectionAdvice(Driver driver, WeatherCondition weather) {
    if (weather == WeatherCondition.rain) {
      return "Use wet weather compounds (Intermediate or Wet)";
    }

    List<TireCompound> available = driver.availableDryCompounds;
    if (available.length == 3) {
      return "Any dry compound can be used";
    } else if (available.length == 2) {
      return "Must use: ${available.map((c) => c.name).join(' or ')} (compound rule)";
    } else if (available.length == 1) {
      return "Must use: ${available.first.name} (compound rule)";
    } else {
      return "No valid compounds available";
    }
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
        return "Clear conditions - standard performance, compound rule applies";
      case WeatherCondition.rain:
        return "Rain - 2.5x more errors, consistency critical, wet tires mandatory, compound rule suspended";
    }
  }

  /// Gets weather-specific strategy advice
  static String getWeatherStrategyAdvice(WeatherCondition weather) {
    switch (weather) {
      case WeatherCondition.clear:
        return "Focus on tire degradation, pit windows, and satisfying compound rule";
      case WeatherCondition.rain:
        return "Prioritize consistent drivers, expect incidents, compound rule doesn't apply";
    }
  }

  /// Gets compound rule warning for drivers at risk
  static List<String> getCompoundRuleWarnings(List<Driver> drivers, int currentLap, int totalLaps) {
    List<String> warnings = [];

    for (Driver driver in drivers) {
      if (driver.isDNF()) continue;

      // Check if driver is at risk of not satisfying compound rule
      if (!driver.hasUsedTwoCompounds && currentLap >= totalLaps - 15) {
        String remainingLaps = "${totalLaps - currentLap}";
        warnings.add("${driver.name}: Must pit soon to satisfy compound rule ($remainingLaps laps remaining)");
      }
    }

    return warnings;
  }

  /// Gets compound statistics for race analysis
  static Map<String, dynamic> getCompoundStatistics(List<Driver> drivers) {
    Map<TireCompound, int> currentDistribution = getCompoundDistribution(drivers);
    Map<TireCompound, int> usageHistory = {};

    // Count total compound usage throughout race
    for (TireCompound compound in TireCompound.values) {
      usageHistory[compound] = 0;
    }

    for (Driver driver in drivers) {
      for (TireCompound compound in driver.usedCompounds) {
        usageHistory[compound] = (usageHistory[compound] ?? 0) + 1;
      }
      // Add current compound if not already counted
      if (!driver.usedCompounds.contains(driver.currentCompound)) {
        usageHistory[driver.currentCompound] = (usageHistory[driver.currentCompound] ?? 0) + 1;
      }
    }

    return {
      'currentDistribution': currentDistribution,
      'usageHistory': usageHistory,
      'compliance': getCompoundRuleCompliance(drivers),
    };
  }
}
