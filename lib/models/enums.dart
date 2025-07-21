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

enum TireCompound {
  soft("Soft", "🔴", -0.8, 4.0, Colors.red), // Increased from 2.5 to 4.0 - much faster degradation
  medium("Medium", "🟡", 0.0, 1.0, Colors.yellow), // Baseline unchanged
  hard("Hard", "⚪", 0.6, 0.3, Colors.grey), // Decreased from 0.4 to 0.3 - even more durable
  intermediate("Inter", "🟢", 2.0, 1.5, Colors.green),
  wet("Wet", "🔵", 4.0, 1.0, Colors.blue);

  const TireCompound(this.name, this.icon, this.lapTimeDelta, this.degradationMultiplier, this.color);
  final String name;
  final String icon;
  final double lapTimeDelta; // Seconds faster/slower than medium
  final double degradationMultiplier; // Degradation rate vs medium - now much more extreme
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

// Simplified: Single qualifying session
enum QualifyingSession {
  QUALIFYING("QUALIFYING", "Single Session", Colors.red, 0); // No timer needed

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
