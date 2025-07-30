enum TrackType {
  street, // Monaco, Singapore - High consistency emphasis
  power, // Monza, Spa - High speed/car performance emphasis
  technical, // Hungary, Monaco - Balanced skills, high tire management
  highSpeed, // Silverstone, Suzuka - Speed emphasis
  mixed, // Most tracks - Balanced approach
}

class Track {
  final String name;
  final String country;
  final double baseLapTime; // Base lap time in seconds
  final TrackType type;
  final int totalLaps;

  // Performance multipliers (how much each factor matters)
  final double speedEmphasis; // 0.5-1.5 multiplier on speed importance
  final double consistencyEmphasis; // 0.5-1.5 multiplier on consistency importance
  final double tireManagementEmphasis; // 0.5-1.5 multiplier on tire management importance
  final double carPerformanceEmphasis; // 0.5-1.5 multiplier on car performance importance

  // Track-specific factors
  final double tireDegradationMultiplier; // 0.7-1.4 (how hard on tires)
  final double errorProbabilityMultiplier; // 0.6-1.6 (how error-prone)
  final double mechanicalStressMultiplier; // 0.8-1.3 (how hard on machinery)
  final double weatherImpactMultiplier; // 0.7-1.4 (how much weather affects)
  final double overtakingDifficulty; // 0.3-1.0 (affects pit strategy aggression)

  // Strategy factors
  final double pitStopTimePenalty; // Additional pit stop time (narrow pit lanes, etc.)
  final bool favorsTwoStop; // Whether track naturally favors 2-stop strategies

  const Track({
    required this.name,
    required this.country,
    required this.baseLapTime,
    required this.type,
    required this.totalLaps,
    required this.speedEmphasis,
    required this.consistencyEmphasis,
    required this.tireManagementEmphasis,
    required this.carPerformanceEmphasis,
    required this.tireDegradationMultiplier,
    required this.errorProbabilityMultiplier,
    required this.mechanicalStressMultiplier,
    required this.weatherImpactMultiplier,
    required this.overtakingDifficulty,
    required this.pitStopTimePenalty,
    required this.favorsTwoStop,
  });

  String get typeDescription {
    switch (type) {
      case TrackType.street:
        return "Street Circuit";
      case TrackType.power:
        return "Power Track";
      case TrackType.technical:
        return "Technical Track";
      case TrackType.highSpeed:
        return "High-Speed Track";
      case TrackType.mixed:
        return "Mixed Track";
    }
  }

  String get characteristicsInfo {
    List<String> characteristics = [];

    if (speedEmphasis > 1.2) characteristics.add("Speed Critical");
    if (consistencyEmphasis > 1.2) characteristics.add("Consistency Critical");
    if (tireManagementEmphasis > 1.2) characteristics.add("Tire Management Critical");
    if (carPerformanceEmphasis > 1.2) characteristics.add("Car Performance Critical");

    if (tireDegradationMultiplier > 1.2) characteristics.add("Hard on Tires");
    if (errorProbabilityMultiplier > 1.2) characteristics.add("Error Prone");
    if (overtakingDifficulty < 0.4) characteristics.add("Hard to Overtake");
    if (weatherImpactMultiplier > 1.2) characteristics.add("Weather Sensitive");

    return characteristics.isEmpty ? "Balanced Track" : characteristics.join(", ");
  }
}
