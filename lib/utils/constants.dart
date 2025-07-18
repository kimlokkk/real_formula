class F1Constants {
  // Base lap time constants
  static const double baseLapTime = 90.0;
  static const double carPerformanceWeight = 0.015;

  // Driver skill weights
  static const double speedWeight = 0.0087;
  static const double consistencyWeight = 0.0035;
  static const double tireManagementWeight = 0.0017;

  // Pit stop constants
  static const double maxPitTime = 26.0;
  static const double minPitTime = 23.0;
  static const int minLapsBeforePit = 15;
  static const int maxPitStops = 2;
  static const int minLapsForPit = 10;
  static const int lastLapsToPit = 8;
  static const double exceptionalPitChance = 0.25;
  static const double normalPitVariation = 0.5;
  static const double exceptionalPitVariation = 3.0;

  // Error probability constants
  static const double minErrorProbability = 0.01;
  static const double maxErrorProbability = 0.18;
  static const double weatherErrorMultiplier = 2.5;
  static const double consistencyErrorRange = 50.0;

  // Mechanical failure constants
  static const double highReliabilityFailureRate = 0.02;
  static const double lowReliabilityFailureRate = 0.15;
  static const double reliabilityThreshold = 70.0;
  static const double maxReliabilityFailureRate = 0.14;

  // Tire degradation constants
  static const double baseTireDegradation = 0.01;
  static const double midTireDegradation = 0.03;
  static const double lateTireDegradation = 0.06;
  static const double extremeTireDegradation = 0.08;

  // Weather constants
  static const double baseWetPenalty = 1.5;
  static const double carWetPenalty = 0.02;
  static const double consistencyWetFactor = 0.025;
  static const double speedWetFactor = 0.006;
  static const double tireWetFactor = 0.0025;
  static const double wetRandomVariation = 0.5;

  // Strategy constants
  static const double underCutGap = 30.0;
  static const double safeGap = 25.0;
  static const int basePitLapMin = 25;
  static const int basePitLapMax = 50;
  static const int pitVariation = 8;
  static const int lastMandatoryPitLaps = 12;

  // Error type probabilities
  static const double crashChanceDry = 0.01;
  static const double crashChanceWet = 0.03;
  static const double majorErrorChanceDry = 0.20;
  static const double majorErrorChanceWet = 0.35;
  static const double lockupChance = 0.60;

  // Failure type probabilities
  static const double terminalFailureChance = 0.05;
  static const double engineIssueChance = 0.20;
  static const double gearboxProblemChance = 0.35;
  static const double brakeIssueChance = 0.50;
  static const double suspensionDamageChance = 0.70;

  // Time penalties
  static const double minorMistakeMin = 1.0;
  static const double minorMistakeMax = 3.0;
  static const double majorSpinMin = 5.0;
  static const double majorSpinMax = 15.0;
  static const double lockupMin = 3.0;
  static const double lockupMax = 8.0;

  // Mechanical issue durations (laps)
  static const int engineIssueMin = 10;
  static const int engineIssueMax = 25;
  static const int gearboxProblemMin = 5;
  static const int gearboxProblemMax = 15;
  static const int brakeIssueMin = 8;
  static const int brakeIssueMax = 20;
  static const int suspensionDamageMin = 15;
  static const int suspensionDamageMax = 35;
  static const int hydraulicLeakMin = 12;
  static const int hydraulicLeakMax = 30;

  // Mechanical issue penalties per lap
  static const double enginePenaltyMin = 0.8;
  static const double enginePenaltyMax = 1.2;
  static const double gearboxPenaltyChance = 0.3;
  static const double gearboxPenalty = 1.5;
  static const double brakePenaltyMin = 0.6;
  static const double brakePenaltyMax = 1.4;
  static const double suspensionPenaltyMin = 0.5;
  static const double suspensionPenaltyMax = 1.1;
  static const double hydraulicPenaltyMin = 0.2;
  static const double hydraulicPenaltyMax = 0.6;

  // Race settings
  static const int defaultTotalLaps = 50;
  static const int positionHistoryLimit = 10;
  static const int incidentLogLimit = 15;

  // UI constants
  static const double cardElevation = 4.0;
  static const double cardElevationNormal = 1.0;
  static const double headerPadding = 12.0;
  static const double containerHeight = 100.0;
}
