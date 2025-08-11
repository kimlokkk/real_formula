// lib/models/interactive_race.dart
import 'package:flutter/material.dart';
import '../models/driver.dart';

class InteractiveRaceState {
  final List<Driver> drivers;
  final int currentLap;
  final int totalLaps;
  final List<MiniGameResult> completedMiniGames;
  final bool raceFinished;

  InteractiveRaceState({
    required this.drivers,
    required this.currentLap,
    required this.totalLaps,
    required this.completedMiniGames,
    required this.raceFinished,
  });

  InteractiveRaceState copyWith({
    List<Driver>? drivers,
    int? currentLap,
    int? totalLaps,
    List<MiniGameResult>? completedMiniGames,
    bool? raceFinished,
  }) {
    return InteractiveRaceState(
      drivers: drivers ?? this.drivers,
      currentLap: currentLap ?? this.currentLap,
      totalLaps: totalLaps ?? this.totalLaps,
      completedMiniGames: completedMiniGames ?? this.completedMiniGames,
      raceFinished: raceFinished ?? this.raceFinished,
    );
  }
}

class MiniGameResult {
  final MiniGameType type;
  final int lap;
  final MiniGamePerformance performance;
  final int positionChange;
  final String description;

  MiniGameResult({
    required this.type,
    required this.lap,
    required this.performance,
    required this.positionChange,
    required this.description,
  });
}

enum MiniGameType {
  launchControl,
  drsAttack,
  pitStrategy,
  weatherRadar,
  tireManagement,
  defensePosition,
}

enum MiniGamePerformance {
  perfect, // 95-100%
  excellent, // 85-94%
  good, // 70-84%
  average, // 50-69%
  poor, // 30-49%
  terrible, // 0-29%
}

class LaunchControlResult {
  final double reactionTime; // in milliseconds
  final double rpmAccuracy; // 0.0 to 1.0
  final bool perfectLaunch;
  final MiniGamePerformance performance;
  final int positionChange;

  LaunchControlResult({
    required this.reactionTime,
    required this.rpmAccuracy,
    required this.perfectLaunch,
    required this.performance,
    required this.positionChange,
  });

  double get overallScore {
    double reactionScore = (500 - reactionTime.clamp(0, 500)) / 500; // 0-1
    double rpmScore = rpmAccuracy; // Already 0-1
    return (reactionScore * 0.4 + rpmScore * 0.6); // RPM more important
  }
}

extension MiniGamePerformanceExtension on MiniGamePerformance {
  String get displayName {
    switch (this) {
      case MiniGamePerformance.perfect:
        return 'PERFECT';
      case MiniGamePerformance.excellent:
        return 'EXCELLENT';
      case MiniGamePerformance.good:
        return 'GOOD';
      case MiniGamePerformance.average:
        return 'AVERAGE';
      case MiniGamePerformance.poor:
        return 'POOR';
      case MiniGamePerformance.terrible:
        return 'TERRIBLE';
    }
  }

  Color get color {
    switch (this) {
      case MiniGamePerformance.perfect:
        return const Color(0xFF00FF00); // Bright green
      case MiniGamePerformance.excellent:
        return const Color(0xFF32CD32); // Lime green
      case MiniGamePerformance.good:
        return const Color(0xFF90EE90); // Light green
      case MiniGamePerformance.average:
        return const Color(0xFFFFD700); // Gold
      case MiniGamePerformance.poor:
        return const Color(0xFFFF8C00); // Dark orange
      case MiniGamePerformance.terrible:
        return const Color(0xFFFF4500); // Red orange
    }
  }
}
