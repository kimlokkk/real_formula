// lib/models/team.dart
import 'package:flutter/material.dart';

class Team {
  final String name;
  final String fullName;
  final Color primaryColor;
  final Color secondaryColor;
  final int carPerformance; // 70-100 (car speed/aerodynamics)
  final int reliability; // 70-100 (mechanical reliability)
  final String strategy; // "aggressive", "balanced", "conservative"
  final String engineSupplier;
  final double pitStopSpeed; // 0.8-1.2 multiplier for pit stop times
  final String headquarters;

  const Team({
    required this.name,
    required this.fullName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.carPerformance,
    required this.reliability,
    required this.strategy,
    required this.engineSupplier,
    required this.pitStopSpeed,
    required this.headquarters,
  });

  /// Get team performance tier for display
  String get performanceTier {
    if (carPerformance >= 96) return "Dominant";
    if (carPerformance >= 92) return "Championship Contender";
    if (carPerformance >= 86) return "Race Winner";
    if (carPerformance >= 80) return "Points Contender";
    if (carPerformance >= 75) return "Midfield Runner";
    return "Backmarker";
  }

  /// Get reliability tier for display
  String get reliabilityTier {
    if (reliability >= 94) return "Bulletproof";
    if (reliability >= 88) return "Very Reliable";
    if (reliability >= 82) return "Reliable";
    if (reliability >= 76) return "Moderate";
    return "Problematic";
  }

  /// Get strategy description
  String get strategyDescription {
    switch (strategy) {
      case "aggressive":
        return "Takes risks, early pit stops, bold moves";
      case "conservative":
        return "Safe approach, protects position";
      case "balanced":
        return "Flexible strategy based on situation";
      default:
        return "Adaptive strategy";
    }
  }

  /// Get team info summary for UI
  String get teamSummary {
    return "$performanceTier • $reliabilityTier • ${strategy.toUpperCase()} Strategy";
  }

  /// Get expected championship position range
  String get expectedPosition {
    if (carPerformance >= 96) return "P1-P2";
    if (carPerformance >= 92) return "P1-P3";
    if (carPerformance >= 86) return "P3-P5";
    if (carPerformance >= 80) return "P5-P7";
    if (carPerformance >= 75) return "P7-P9";
    return "P9-P10";
  }

  @override
  String toString() {
    return '$name ($carPerformance/$reliability)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Team && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
