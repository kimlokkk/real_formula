import '../models/track.dart';

class TrackData {
  static const List<Track> tracks = [
    // Monaco - Ultimate driver track
    Track(
      name: "Monaco",
      country: "Monaco",
      baseLapTime: 71.0,
      type: TrackType.street,
      totalLaps: 78,
      speedEmphasis: 0.6, // Speed less important
      consistencyEmphasis: 1.4, // Consistency critical
      tireManagementEmphasis: 0.8, // Less tire management needed
      carPerformanceEmphasis: 0.7, // Car performance less important
      tireDegradationMultiplier: 0.7, // Easy on tires
      errorProbabilityMultiplier: 1.8, // High error probability
      mechanicalStressMultiplier: 0.9, // Lower mechanical stress
      weatherImpactMultiplier: 1.5, // Rain is devastating
      overtakingDifficulty: 0.1, // Almost impossible to overtake
      pitStopTimePenalty: 2.0, // Narrow pit lane
      favorsTwoStop: false, // Usually one-stop
    ),

    // Monza - Power track
    Track(
      name: "Monza",
      country: "Italy",
      baseLapTime: 80.0,
      type: TrackType.power,
      totalLaps: 53,
      speedEmphasis: 1.3, // Speed very important
      consistencyEmphasis: 0.8, // Consistency less critical
      tireManagementEmphasis: 1.1, // Some tire management
      carPerformanceEmphasis: 1.4, // Car performance critical
      tireDegradationMultiplier: 1.1, // Moderate tire wear
      errorProbabilityMultiplier: 0.9, // Lower error probability
      mechanicalStressMultiplier: 1.3, // High mechanical stress
      weatherImpactMultiplier: 1.0, // Standard weather impact
      overtakingDifficulty: 0.8, // Good overtaking opportunities
      pitStopTimePenalty: 0.0, // Standard pit lane
      favorsTwoStop: false, // Usually one-stop
    ),

    // Silverstone - High-speed technical
    Track(
      name: "Silverstone",
      country: "United Kingdom",
      baseLapTime: 87.0,
      type: TrackType.highSpeed,
      totalLaps: 52,
      speedEmphasis: 1.1, // Speed important
      consistencyEmphasis: 1.0, // Standard consistency needs
      tireManagementEmphasis: 1.2, // Tire management important
      carPerformanceEmphasis: 1.1, // Car performance important
      tireDegradationMultiplier: 1.3, // Hard on tires
      errorProbabilityMultiplier: 1.0, // Standard error rate
      mechanicalStressMultiplier: 1.1, // Moderate mechanical stress
      weatherImpactMultiplier: 1.2, // British weather!
      overtakingDifficulty: 0.6, // Some overtaking opportunities
      pitStopTimePenalty: 0.0, // Standard pit lane
      favorsTwoStop: true, // Often favors two-stop
    ),

    // Hungary - Technical/tire management
    Track(
      name: "Hungaroring",
      country: "Hungary",
      baseLapTime: 76.0,
      type: TrackType.technical,
      totalLaps: 70,
      speedEmphasis: 0.8, // Speed less important
      consistencyEmphasis: 1.2, // Consistency important
      tireManagementEmphasis: 1.4, // Tire management critical
      carPerformanceEmphasis: 0.9, // Car performance less important
      tireDegradationMultiplier: 1.2, // Moderate-high tire wear
      errorProbabilityMultiplier: 1.1, // Slightly higher error rate
      mechanicalStressMultiplier: 0.9, // Lower mechanical stress
      weatherImpactMultiplier: 1.1, // Moderate weather impact
      overtakingDifficulty: 0.2, // Very difficult to overtake
      pitStopTimePenalty: 0.0, // Standard pit lane
      favorsTwoStop: false, // Usually one-stop due to difficulty overtaking
    ),

    // Spa - Mixed high-speed
    Track(
      name: "Spa-Francorchamps",
      country: "Belgium",
      baseLapTime: 104.0,
      type: TrackType.mixed,
      totalLaps: 44,
      speedEmphasis: 1.2, // Speed very important
      consistencyEmphasis: 1.0, // Standard consistency
      tireManagementEmphasis: 1.0, // Standard tire management
      carPerformanceEmphasis: 1.2, // Car performance very important
      tireDegradationMultiplier: 0.9, // Easier on tires
      errorProbabilityMultiplier: 1.2, // Higher error probability
      mechanicalStressMultiplier: 1.2, // Higher mechanical stress
      weatherImpactMultiplier: 1.4, // Famous for weather changes
      overtakingDifficulty: 0.7, // Good overtaking opportunities
      pitStopTimePenalty: 0.0, // Standard pit lane
      favorsTwoStop: false, // Usually one-stop
    ),

    // Suzuka - Technical high-speed
    Track(
      name: "Suzuka",
      country: "Japan",
      baseLapTime: 91.0,
      type: TrackType.technical,
      totalLaps: 53,
      speedEmphasis: 1.1, // Speed important
      consistencyEmphasis: 1.3, // Consistency very important
      tireManagementEmphasis: 1.1, // Tire management important
      carPerformanceEmphasis: 1.0, // Standard car performance
      tireDegradationMultiplier: 1.1, // Moderate tire wear
      errorProbabilityMultiplier: 1.3, // High error probability (technical)
      mechanicalStressMultiplier: 1.0, // Standard mechanical stress
      weatherImpactMultiplier: 1.3, // Rain makes it very challenging
      overtakingDifficulty: 0.4, // Moderately difficult to overtake
      pitStopTimePenalty: 0.0, // Standard pit lane
      favorsTwoStop: true, // Often two-stop
    ),

    // Generic/Default track (your original)
    Track(
      name: "Generic Circuit",
      country: "International",
      baseLapTime: 90.0,
      type: TrackType.mixed,
      totalLaps: 50,
      speedEmphasis: 1.0, // Balanced
      consistencyEmphasis: 1.0, // Balanced
      tireManagementEmphasis: 1.0, // Balanced
      carPerformanceEmphasis: 1.0, // Balanced
      tireDegradationMultiplier: 1.0, // Standard tire wear
      errorProbabilityMultiplier: 1.0, // Standard error rate
      mechanicalStressMultiplier: 1.0, // Standard mechanical stress
      weatherImpactMultiplier: 1.0, // Standard weather impact
      overtakingDifficulty: 0.5, // Moderate overtaking
      pitStopTimePenalty: 0.0, // Standard pit lane
      favorsTwoStop: false, // Balanced strategy
    ),
  ];

  static Track getTrackByName(String name) {
    return tracks.firstWhere((track) => track.name == name,
        orElse: () => tracks.last); // Default to generic if not found
  }

  static List<String> getTrackNames() {
    return tracks.map((track) => track.name).toList();
  }

  static Track getDefaultTrack() {
    return tracks.last; // Generic Circuit
  }
}
