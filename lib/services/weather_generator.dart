// lib/services/weather_generator.dart
import 'dart:math';
import '../models/enums.dart';

class WeatherGenerator {
  static final Random _random = Random();

  /// Generate weather for a specific track based on realistic probabilities
  static WeatherCondition generateWeatherForTrack(String trackName) {
    double rainProbability = getTrackWeatherProbability(trackName);
    double randomValue = _random.nextDouble();

    if (randomValue < rainProbability) {
      return WeatherCondition.rain;
    } else {
      return WeatherCondition.clear;
    }
  }

  static RainIntensity generateRainIntensity(String trackName) {
    double random = _random.nextDouble();

    // Track-specific intensity tendencies
    double heavyRainChance = _getHeavyRainChance(trackName);
    double extremeRainChance = _getExtremeRainChance(trackName);

    // Determine intensity based on weighted probabilities
    if (random < extremeRainChance) {
      return RainIntensity.extreme;
    } else if (random < extremeRainChance + heavyRainChance) {
      return RainIntensity.heavy;
    } else if (random < 0.60) {
      // 60% chance for moderate when it rains
      return RainIntensity.moderate;
    } else {
      return RainIntensity.light;
    }
  }

  static double _getHeavyRainChance(String trackName) {
    switch (trackName.toLowerCase()) {
      // Tracks famous for heavy downpours
      case 'silverstone':
        return 0.25; // British weather can be extreme
      case 'spa-francorchamps':
        return 0.30; // Famous for sudden heavy rain
      case 'brazil':
        return 0.35; // Tropical storms
      case 'singapore':
        return 0.40; // Monsoon conditions
      case 'japan':
      case 'suzuka':
        return 0.25; // Typhoon season

      // Moderate rain tendency
      case 'netherlands':
      case 'austria':
      case 'canada':
        return 0.15;

      // Usually light rain when it happens
      default:
        return 0.10;
    }
  }

  /// Get extreme rain probability for track (0.0 to 1.0)
  static double _getExtremeRainChance(String trackName) {
    switch (trackName.toLowerCase()) {
      // Tracks that can get monsoon-like conditions
      case 'singapore':
        return 0.15; // Tropical storms
      case 'brazil':
        return 0.12; // Interlagos legends
      case 'spa-francorchamps':
        return 0.10; // Spa magic
      case 'japan':
      case 'suzuka':
        return 0.08; // Typhoons

      // Very rare extreme conditions
      case 'silverstone':
        return 0.05;

      // Almost never extreme
      default:
        return 0.02;
    }
  }

  /// Get rain probability for each track (0.0 to 1.0)
  static double getTrackWeatherProbability(String trackName) {
    switch (trackName.toLowerCase()) {
      // Desert/Hot Climate (0-5% Rain)
      case 'bahrain':
        return 0.00; // Pure desert, never rains during race season
      case 'saudi arabia':
        return 0.00; // Pure desert
      case 'qatar':
        return 0.00; // Pure desert
      case 'abu dhabi':
        return 0.00; // Pure desert
      case 'las vegas':
        return 0.05; // Rare desert storms

      // European Climate (10-30% Rain)
      case 'silverstone':
        return 0.30; // Famous British weather!
      case 'spa-francorchamps':
        return 0.25; // Legendary for weather changes
      case 'netherlands':
        return 0.20; // Maritime climate
      case 'austria':
        return 0.20; // Mountain weather
      case 'hungaroring':
        return 0.15; // Continental climate
      case 'monza':
        return 0.15; // Northern Italy
      case 'spain':
        return 0.10; // Mediterranean, usually dry
      case 'monaco':
        return 0.10; // Mediterranean coast
      case 'imola':
        return 0.15; // Northern Italy

      // Tropical/High Humidity (25-40% Rain)
      case 'singapore':
        return 0.40; // Tropical night race, frequent storms
      case 'brazil':
        return 0.35; // Famous for epic rain races
      case 'miami':
        return 0.25; // Tropical storms
      case 'suzuka':
        return 0.25; // Typhoon season
      case 'japan':
        return 0.25; // Alternative name for Suzuka

      // Continental/Moderate (10-20% Rain)
      case 'canada':
        return 0.20; // Variable Montreal weather
      case 'china':
        return 0.20; // Continental monsoon climate
      case 'united states':
        return 0.15; // Austin, Texas weather
      case 'australia':
        return 0.15; // March weather in Melbourne
      case 'mexico':
        return 0.10; // High altitude, generally dry
      case 'azerbaijan':
        return 0.05; // Semi-arid climate

      // Default for any unrecognized tracks
      default:
        return 0.15; // 15% default probability
    }
  }

  /// Get weather description for UI display
  static String getWeatherDescription(
      String trackName, WeatherCondition weather) {
    String location = _getTrackLocation(trackName);

    switch (weather) {
      case WeatherCondition.clear:
        return _getClearWeatherDescription(trackName, location);
      case WeatherCondition.rain:
        return _getRainWeatherDescription(trackName, location);
    }
  }

  /// Get clear weather description based on track characteristics
  static String _getClearWeatherDescription(String trackName, String location) {
    switch (trackName.toLowerCase()) {
      case 'bahrain':
      case 'saudi arabia':
      case 'qatar':
      case 'abu dhabi':
        return 'Hot and dry desert conditions in $location';

      case 'singapore':
        return 'Humid tropical evening in $location';

      case 'monaco':
        return 'Perfect Mediterranean weather on the French Riviera';

      case 'silverstone':
        return 'Dry conditions at the home of British motorsport';

      case 'spa-francorchamps':
        return 'Clear skies over the Ardennes forest';

      case 'brazil':
        return 'Dry but humid conditions at Interlagos';

      case 'las vegas':
        return 'Clear desert night under the Vegas lights';

      default:
        return 'Clear and dry conditions in $location';
    }
  }

  /// Get rain weather description based on track characteristics
  static String _getRainWeatherDescription(String trackName, String location) {
    switch (trackName.toLowerCase()) {
      case 'silverstone':
        return 'Typical British weather - rain at Silverstone!';

      case 'spa-francorchamps':
        return 'Classic Spa conditions - rain in the Ardennes';

      case 'brazil':
        return 'Legendary Interlagos rain conditions!';

      case 'singapore':
        return 'Tropical thunderstorm hits the Marina Bay circuit';

      case 'suzuka':
      case 'japan':
        return 'Challenging wet conditions at the legendary Suzuka';

      case 'canada':
        return 'Montreal rain creates tricky conditions';

      default:
        return 'Wet weather conditions challenge drivers in $location';
    }
  }

  /// Get track location for weather descriptions
  static String _getTrackLocation(String trackName) {
    switch (trackName.toLowerCase()) {
      case 'bahrain':
        return 'Sakhir';
      case 'saudi arabia':
        return 'Jeddah';
      case 'australia':
        return 'Melbourne';
      case 'china':
        return 'Shanghai';
      case 'miami':
        return 'Miami';
      case 'imola':
        return 'Imola';
      case 'monaco':
        return 'Monte Carlo';
      case 'spain':
        return 'Barcelona';
      case 'canada':
        return 'Montreal';
      case 'austria':
        return 'Spielberg';
      case 'silverstone':
        return 'Silverstone';
      case 'hungaroring':
        return 'Budapest';
      case 'spa-francorchamps':
        return 'Spa';
      case 'netherlands':
        return 'Zandvoort';
      case 'monza':
        return 'Monza';
      case 'azerbaijan':
        return 'Baku';
      case 'singapore':
        return 'Marina Bay';
      case 'united states':
        return 'Austin';
      case 'mexico':
        return 'Mexico City';
      case 'brazil':
        return 'São Paulo';
      case 'las vegas':
        return 'Las Vegas';
      case 'qatar':
        return 'Lusail';
      case 'abu dhabi':
        return 'Yas Island';
      case 'suzuka':
      case 'japan':
        return 'Suzuka';
      default:
        return trackName;
    }
  }

  /// Get weather probability as percentage string for UI
  static String getWeatherProbabilityText(String trackName) {
    double probability = getTrackWeatherProbability(trackName);
    int percentage = (probability * 100).round();

    if (percentage == 0) {
      return 'Always dry';
    } else if (percentage <= 5) {
      return 'Rarely wet ($percentage% chance)';
    } else if (percentage <= 15) {
      return 'Occasionally wet ($percentage% chance)';
    } else if (percentage <= 25) {
      return 'Sometimes wet ($percentage% chance)';
    } else {
      return 'Often wet ($percentage% chance)';
    }
  }

  /// Simulate weather generation process (for loading screen animation)
  static Future<WeatherCondition> generateWeatherWithDelay(String trackName,
      {Duration delay = const Duration(milliseconds: 2000)}) async {
    await Future.delayed(delay);
    return generateWeatherForTrack(trackName);
  }
}
