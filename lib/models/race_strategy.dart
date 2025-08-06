// lib/models/race_strategy.dart
import 'package:real_formula/models/enums.dart';

enum StrategyType {
  oneStop,
  twoStop,
  threeStop,
  flexible, // Can adapt during race
}

class RaceStrategy {
  final StrategyType type;
  final List<int> plannedPitLaps; // e.g., [28] for 1-stop, [22, 45] for 2-stop
  final List<TireCompound>
      plannedCompounds; // e.g., [TireCompound.soft, TireCompound.hard]
  final double expectedRaceTime; // Estimated total race time with this strategy
  final String reasoning; // Why this strategy was chosen
  final double viabilityScore; // 0.0-1.0 how good this strategy is

  // Execution tracking
  int currentPitStop; // Which pit stop we're on (0 = no stops yet)
  bool isAbandoned; // If strategy was abandoned due to circumstances
  String? abandonReason; // Why strategy was abandoned

  RaceStrategy({
    required this.type,
    required this.plannedPitLaps,
    required this.plannedCompounds,
    required this.expectedRaceTime,
    required this.reasoning,
    required this.viabilityScore,
    this.currentPitStop = 0,
    this.isAbandoned = false,
    this.abandonReason,
  });

  // Helper methods
  bool get isOneStop => type == StrategyType.oneStop;
  bool get isTwoStop => type == StrategyType.twoStop;
  bool get isCompleted => currentPitStop >= plannedPitLaps.length;

  int? get nextPlannedPitLap {
    if (isCompleted || isAbandoned) return null;
    return plannedPitLaps[currentPitStop];
  }

  TireCompound? get nextPlannedCompound {
    if (isCompleted || isAbandoned) return null;
    return plannedCompounds[
        currentPitStop + 1]; // +1 because compounds include starting compound
  }

  // Create a copy with updated pit stop progress
  RaceStrategy copyWith({
    int? currentPitStop,
    bool? isAbandoned,
    String? abandonReason,
  }) {
    return RaceStrategy(
      type: type,
      plannedPitLaps: plannedPitLaps,
      plannedCompounds: plannedCompounds,
      expectedRaceTime: expectedRaceTime,
      reasoning: reasoning,
      viabilityScore: viabilityScore,
      currentPitStop: currentPitStop ?? this.currentPitStop,
      isAbandoned: isAbandoned ?? this.isAbandoned,
      abandonReason: abandonReason ?? this.abandonReason,
    );
  }

  @override
  String toString() {
    String pits = plannedPitLaps.map((lap) => 'L$lap').join(', ');
    String compounds =
        plannedCompounds.map((c) => c.name.toUpperCase()).join(' → ');
    return '${type.name.toUpperCase()}: $compounds (Pits: $pits) - $reasoning';
  }
}
