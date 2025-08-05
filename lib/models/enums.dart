// Updated enums.dart with REALISTIC tire compound differences

import 'package:flutter/material.dart';

enum DriverErrorType {
  minorMistake, // 1-3 second loss
  majorSpin, // 5-15 second loss + potential position drop
  lockup, // 3-8 second loss
  crash // DNF (very rare)
}

enum MechanicalFailureType {
  engineIssue, // Gradual power loss over multiple laps
  gearboxProblem, // Intermittent performance drops
  brakeIssue, // Reduced braking efficiency
  suspensionDamage, // Handling problems
  hydraulicLeak, // Gradual performance degradation
  terminalFailure // Immediate DNF
}

enum WeatherCondition {
  clear("☀️", "Clear", Colors.yellow),
  rain("🌧️", "Rain", Colors.blue);

  const WeatherCondition(this.icon, this.name, this.color);
  final String icon;
  final String name;
  final Color color;
}

// FIXED: Much more realistic tire compound differences
enum TireCompound {
  // REALISTIC F1 compound differences (0.1-0.3s per step, not 0.8s!)
  soft("Soft", "🔴", -0.25, 4.0, Colors.red), // Was -0.8s, now -0.25s (still fastest)
  medium("Medium", "🟡", 0.0, 1.0, Colors.amber), // Baseline unchanged
  hard("Hard", "⚪", 0.15, 0.3, Colors.white), // Was +0.6s, now +0.15s (more realistic)
  intermediate("Inter", "🟢", 2.0, 1.5, Colors.green), // Wet conditions only
  wet("Wet", "🔵", 4.0, 1.0, Colors.blue); // Heavy wet only

  // Now total gap between soft and hard is 0.4s instead of 1.4s - much more realistic!

  const TireCompound(this.name, this.icon, this.lapTimeDelta, this.degradationMultiplier, this.color);
  final String name;
  final String icon;
  final double lapTimeDelta; // FIXED: Realistic differences (0.25s max advantage)
  final double degradationMultiplier; // Degradation rate vs medium - still extreme for strategy
  final Color color;
}

enum SimulationSpeed {
  normal(1, 1500, "1x"),
  fast(2, 750, "2x"),
  ultraFast(3, 500, "3x");

  const SimulationSpeed(this.multiplier, this.intervalMs, this.label);
  final int multiplier;
  final int intervalMs;
  final String label;
}

enum QualifyingSession {
  QUALIFYING("QUALIFYING", "Single Session", Colors.red, 0);

  const QualifyingSession(this.name, this.duration, this.color, this.seconds);
  final String name;
  final String duration;
  final Color color;
  final int seconds;
}

enum QualifyingStatus {
  waiting("READY", Colors.grey),
  running("SIMULATING", Colors.orange),
  finished("COMPLETED", Colors.green);

  const QualifyingStatus(this.label, this.color);
  final String label;
  final Color color;
}

enum RainIntensity {
  light("Light Rain", "🌦️", "Drizzle with some dry patches"),
  moderate("Moderate Rain", "🌧️", "Steady rain, fully wet track"),
  heavy("Heavy Rain", "⛈️", "Downpour with standing water"),
  extreme("Extreme Rain", "🌊", "Monsoon conditions, very dangerous");

  const RainIntensity(this.name, this.icon, this.description);

  final String name;
  final String icon;
  final String description;

  // Helper method to get optimal tire choice
  TireCompound get optimalTire {
    switch (this) {
      case RainIntensity.light:
      case RainIntensity.moderate:
        return TireCompound.intermediate;
      case RainIntensity.heavy:
      case RainIntensity.extreme:
        return TireCompound.wet;
    }
  }
}
