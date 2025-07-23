// 📁 Create this NEW file: lib/models/career/race_weekend.dart

import '../track.dart';

class RaceWeekend {
  final String name;
  final Track track;
  final DateTime startDate;
  final DateTime endDate;
  final bool isRaceWeekend;
  final int round;

  bool isCompleted;
  bool hasQualifyingResults;
  bool hasRaceResults;

  RaceWeekend({
    required this.name,
    required this.track,
    required this.startDate,
    required this.endDate,
    required this.isRaceWeekend,
    required this.round,
    this.isCompleted = false,
    this.hasQualifyingResults = false,
    this.hasRaceResults = false,
  });

  // Weekend status
  bool get isActive => !isCompleted;

  String get nextSession {
    if (isCompleted) return "Completed";
    if (!hasQualifyingResults && isRaceWeekend) return "Qualifying";
    if (!hasRaceResults) return isRaceWeekend ? "Race" : "Testing";
    return "Completed";
  }

  // Date formatting
  String get dateRange {
    if (startDate.month == endDate.month) {
      return "${startDate.day}-${endDate.day} ${_monthName(startDate.month)}";
    } else {
      return "${startDate.day} ${_monthName(startDate.month)} - ${endDate.day} ${_monthName(endDate.month)}";
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // Mark progression
  void completeQualifying() {
    hasQualifyingResults = true;
  }

  void completeRace() {
    hasRaceResults = true;
    isCompleted = true;
  }
}
