import '../models/driver.dart';
import '../models/enums.dart';

/// Represents a driver's qualifying result (simplified)
class QualifyingResult {
  final Driver driver;
  final double bestLapTime;
  final int position;
  final QualifyingSession session;
  final TireCompound bestTire;
  final double gapToPole;

  QualifyingResult({
    required this.driver,
    required this.bestLapTime,
    required this.position,
    required this.session,
    required this.bestTire,
    this.gapToPole = 0.0,
  });

  /// Create a copy with updated fields
  QualifyingResult copyWith({
    Driver? driver,
    double? bestLapTime,
    int? position,
    QualifyingSession? session,
    TireCompound? bestTire,
    double? gapToPole,
  }) {
    return QualifyingResult(
      driver: driver ?? this.driver,
      bestLapTime: bestLapTime ?? this.bestLapTime,
      position: position ?? this.position,
      session: session ?? this.session,
      bestTire: bestTire ?? this.bestTire,
      gapToPole: gapToPole ?? this.gapToPole,
    );
  }

  /// Format lap time for display
  String get formattedLapTime {
    if (bestLapTime == double.infinity) return "NO TIME";
    int minutes = bestLapTime ~/ 60;
    double seconds = bestLapTime % 60;
    return '${minutes}:${seconds.toStringAsFixed(3).padLeft(6, '0')}';
  }

  /// Format gap for display
  String get formattedGap {
    if (position == 1) return "POLE";
    if (gapToPole == 0.0) return "-";
    return "+${gapToPole.toStringAsFixed(3)}";
  }

  /// Get position suffix (1st, 2nd, 3rd, etc.)
  String get positionSuffix {
    switch (position) {
      case 1:
        return "1st";
      case 2:
        return "2nd";
      case 3:
        return "3rd";
      default:
        return "${position}th";
    }
  }

  /// Check if this is pole position
  bool get isPole => position == 1;

  /// Check if this is a podium position (top 3)
  bool get isPodiumPosition => position <= 3;

  /// Check if this is points position (top 10)
  bool get isPointsPosition => position <= 10;
}

/// Simple qualifying summary data
class QualifyingSummary {
  final List<QualifyingResult> results;
  final QualifyingResult polePosition;
  final double totalSpread;
  final double averageGap;
  final int totalDrivers;
  final DateTime completedAt;

  QualifyingSummary({
    required this.results,
    required this.polePosition,
    required this.totalSpread,
    required this.averageGap,
    required this.totalDrivers,
    required this.completedAt,
  });

  /// Get drivers in podium positions (top 3)
  List<QualifyingResult> get podiumResults => results.where((r) => r.isPodiumPosition).toList();

  /// Get drivers in points positions (top 10)
  List<QualifyingResult> get pointsResults => results.where((r) => r.isPointsPosition).toList();

  /// Get the closest gap in qualifying
  double get closestGap {
    if (results.length < 2) return 0.0;

    double smallest = double.infinity;
    for (int i = 1; i < results.length; i++) {
      double gap = results[i].bestLapTime - results[i - 1].bestLapTime;
      if (gap < smallest) smallest = gap;
    }
    return smallest;
  }

  /// Get summary statistics for display
  Map<String, dynamic> get statistics => {
        'poleTime': polePosition.formattedLapTime,
        'poleSitter': polePosition.driver.name,
        'totalSpread': '${totalSpread.toStringAsFixed(3)}s',
        'averageGap': '${averageGap.toStringAsFixed(3)}s',
        'closestGap': '${closestGap.toStringAsFixed(3)}s',
        'frontRow': '${results[0].driver.name} & ${results.length > 1 ? results[1].driver.name : 'N/A'}',
      };

  /// Export results as readable text
  String exportAsText() {
    StringBuffer sb = StringBuffer();
    sb.writeln('=== QUALIFYING RESULTS ===');
    sb.writeln('Pole Position: ${polePosition.driver.name} (${polePosition.formattedLapTime})');
    sb.writeln('Total Spread: ${totalSpread.toStringAsFixed(3)}s');
    sb.writeln('');
    sb.writeln('Grid:');

    for (QualifyingResult result in results) {
      sb.writeln('P${result.position}: ${result.driver.name} - ${result.formattedLapTime} (${result.formattedGap})');
    }

    return sb.toString();
  }
}

/// Optional: Individual lap attempt (if we want to track multiple attempts per driver)
class QualifyingAttempt {
  final Driver driver;
  final double lapTime;
  final TireCompound tireUsed;
  final int attemptNumber;
  final bool isPersonalBest;

  QualifyingAttempt({
    required this.driver,
    required this.lapTime,
    required this.tireUsed,
    required this.attemptNumber,
    this.isPersonalBest = false,
  });

  /// Format lap time for display
  String get formattedLapTime {
    if (lapTime == double.infinity) return "NO TIME";
    int minutes = lapTime ~/ 60;
    double seconds = lapTime % 60;
    return '${minutes}:${seconds.toStringAsFixed(3).padLeft(6, '0')}';
  }
}
