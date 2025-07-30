import 'package:flutter/material.dart';
import 'package:real_formula/models/driver.dart';

class TimingResult {
  final String quality;
  final double timeModifier;
  final String description;
  final Color color;

  TimingResult({
    required this.quality,
    required this.timeModifier,
    required this.description,
    required this.color,
  });
}

class GameSettings {
  final double perfectZoneSize;
  final double goodZoneSize;
  final double okayZoneSize;
  final double animationSpeed;
  final int attempts;

  GameSettings({
    required this.perfectZoneSize,
    required this.goodZoneSize,
    required this.okayZoneSize,
    required this.animationSpeed,
    required this.attempts,
  });
}

class QualifyingDifficulty {
  static GameSettings getSettings(Driver userDriver) {
    int overallSkill = (userDriver.speed + userDriver.consistency) ~/ 2;

    // HIGHER skill = SLOWER bar = EASIER timing
    // LOWER skill = FASTER bar = HARDER timing
    double animationSpeed = _calculateAnimationSpeed(overallSkill);

    return GameSettings(
      perfectZoneSize: 0.10,
      goodZoneSize: 0.18,
      okayZoneSize: 0.25,
      animationSpeed: animationSpeed,
      attempts: 1,
    );
  }

  static double _calculateAnimationSpeed(int skill) {
    // Inverse relationship: Higher skill = slower bar = easier
    if (skill >= 90) {
      return 1.0; // Very slow bar (easiest)
    } else if (skill >= 80) {
      return 1.3; // Slow bar
    } else if (skill >= 70) {
      return 1.7; // Medium bar
    } else if (skill >= 60) {
      return 2.2; // Fast bar
    } else {
      return 3.0; // Very fast bar (hardest) - This is YOU as Rookie!
    }
  }
}
