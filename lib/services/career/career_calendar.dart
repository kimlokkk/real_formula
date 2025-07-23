// 📁 Create this NEW file: lib/services/career/career_calendar.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/career/race_weekend.dart';
import '../../data/track_data.dart';

class CareerCalendar extends ChangeNotifier {
  static CareerCalendar? _instance;
  static CareerCalendar get instance => _instance ??= CareerCalendar._();

  CareerCalendar._();

  // Calendar state
  DateTime _currentDate = DateTime(2025, 3, 1);
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _progressTimer;

  // Race schedule
  List<RaceWeekend> _raceWeekends = [];
  RaceWeekend? _currentRaceWeekend;
  int _currentRaceIndex = 0;

  // Time progression settings
  Duration _timeStep = Duration(days: 1);
  Duration _tickInterval = Duration(milliseconds: 500);

  // Getters
  DateTime get currentDate => _currentDate;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  List<RaceWeekend> get raceWeekends => _raceWeekends;
  RaceWeekend? get currentRaceWeekend => _currentRaceWeekend;
  RaceWeekend? get nextRaceWeekend => _getNextRaceWeekend();
  int get currentRaceIndex => _currentRaceIndex;

  // Initialize calendar
  void initialize() {
    _generateF1Schedule();
    _checkForRaceWeekend();
  }

  // Calendar control
  void startCalendar() {
    if (_isPaused) {
      resumeCalendar();
      return;
    }

    _isRunning = true;
    _isPaused = false;
    _startProgressTimer();
    notifyListeners();
  }

  void pauseCalendar() {
    _isPaused = true;
    _stopProgressTimer();
    notifyListeners();
  }

  void resumeCalendar() {
    _isPaused = false;
    if (_isRunning) {
      _startProgressTimer();
    }
    notifyListeners();
  }

  void stopCalendar() {
    _isRunning = false;
    _isPaused = false;
    _stopProgressTimer();
    notifyListeners();
  }

  // Time progression
  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_tickInterval, (timer) {
      _progressTime();
    });
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
  }

  void _progressTime() {
    _currentDate = _currentDate.add(_timeStep);

    if (_checkForRaceWeekend()) {
      pauseCalendar();
    }

    notifyListeners();
  }

  // Race weekend detection
  bool _checkForRaceWeekend() {
    for (RaceWeekend weekend in _raceWeekends) {
      if (_isDateInRaceWeekend(_currentDate, weekend)) {
        if (_currentRaceWeekend != weekend) {
          _currentRaceWeekend = weekend;
          _currentRaceIndex = _raceWeekends.indexOf(weekend);
          return true;
        }
        return false;
      }
    }

    if (_currentRaceWeekend != null) {
      _currentRaceWeekend = null;
    }
    return false;
  }

  bool _isDateInRaceWeekend(DateTime date, RaceWeekend weekend) {
    return date.isAfter(weekend.startDate.subtract(Duration(days: 1))) &&
        date.isBefore(weekend.endDate.add(Duration(days: 1)));
  }

  // Complete current race weekend
  void completeCurrentRaceWeekend() {
    if (_currentRaceWeekend != null) {
      _currentRaceWeekend!.isCompleted = true;
      _currentRaceWeekend = null;

      if (_currentRaceIndex < _raceWeekends.length) {
        _currentDate = _raceWeekends[_currentRaceIndex].endDate.add(Duration(days: 1));
      }

      notifyListeners();
    }
  }

  RaceWeekend? _getNextRaceWeekend() {
    for (int i = _currentRaceIndex; i < _raceWeekends.length; i++) {
      if (!_raceWeekends[i].isCompleted) {
        return _raceWeekends[i];
      }
    }
    return null;
  }

  // Skip to next race
  void skipToNextRaceWeekend() {
    RaceWeekend? next = nextRaceWeekend;
    if (next != null) {
      _currentDate = next.startDate;
      _currentRaceWeekend = next;
      _currentRaceIndex = _raceWeekends.indexOf(next);
      pauseCalendar();
      notifyListeners();
    }
  }

  // Generate F1 Schedule
  void _generateF1Schedule() {
    _raceWeekends = [
      // Round 1: Bahrain Grand Prix (Season Opener)
      RaceWeekend(
        name: "Bahrain Grand Prix",
        track: TrackData.getTrackByName("Bahrain"),
        startDate: DateTime(2025, 3, 14),
        endDate: DateTime(2025, 3, 16),
        isRaceWeekend: true,
        round: 1,
      ),

      // Round 2: Saudi Arabian Grand Prix
      RaceWeekend(
        name: "Saudi Arabian Grand Prix",
        track: TrackData.getTrackByName("Saudi Arabia"),
        startDate: DateTime(2025, 3, 21),
        endDate: DateTime(2025, 3, 23),
        isRaceWeekend: true,
        round: 2,
      ),

      // Round 3: Australian Grand Prix
      RaceWeekend(
        name: "Australian Grand Prix",
        track: TrackData.getTrackByName("Australia"),
        startDate: DateTime(2025, 4, 4),
        endDate: DateTime(2025, 4, 6),
        isRaceWeekend: true,
        round: 3,
      ),

      // Round 4: Chinese Grand Prix
      RaceWeekend(
        name: "Chinese Grand Prix",
        track: TrackData.getTrackByName("China"),
        startDate: DateTime(2025, 4, 18),
        endDate: DateTime(2025, 4, 20),
        isRaceWeekend: true,
        round: 4,
      ),

      // Round 5: Miami Grand Prix
      RaceWeekend(
        name: "Miami Grand Prix",
        track: TrackData.getTrackByName("Miami"),
        startDate: DateTime(2025, 5, 2),
        endDate: DateTime(2025, 5, 4),
        isRaceWeekend: true,
        round: 5,
      ),

      // Round 6: Emilia Romagna Grand Prix
      RaceWeekend(
        name: "Emilia Romagna Grand Prix",
        track: TrackData.getTrackByName("Imola"),
        startDate: DateTime(2025, 5, 16),
        endDate: DateTime(2025, 5, 18),
        isRaceWeekend: true,
        round: 6,
      ),

      // Round 7: Monaco Grand Prix (Crown Jewel)
      RaceWeekend(
        name: "Monaco Grand Prix",
        track: TrackData.getTrackByName("Monaco"),
        startDate: DateTime(2025, 5, 23),
        endDate: DateTime(2025, 5, 25),
        isRaceWeekend: true,
        round: 7,
      ),

      // Round 8: Spanish Grand Prix
      RaceWeekend(
        name: "Spanish Grand Prix",
        track: TrackData.getTrackByName("Spain"),
        startDate: DateTime(2025, 6, 13),
        endDate: DateTime(2025, 6, 15),
        isRaceWeekend: true,
        round: 8,
      ),

      // Round 9: Canadian Grand Prix
      RaceWeekend(
        name: "Canadian Grand Prix",
        track: TrackData.getTrackByName("Canada"),
        startDate: DateTime(2025, 6, 27),
        endDate: DateTime(2025, 6, 29),
        isRaceWeekend: true,
        round: 9,
      ),

      // Round 10: Austrian Grand Prix
      RaceWeekend(
        name: "Austrian Grand Prix",
        track: TrackData.getTrackByName("Austria"),
        startDate: DateTime(2025, 7, 11),
        endDate: DateTime(2025, 7, 13),
        isRaceWeekend: true,
        round: 10,
      ),

      // Round 11: British Grand Prix (Home of F1)
      RaceWeekend(
        name: "British Grand Prix",
        track: TrackData.getTrackByName("Silverstone"),
        startDate: DateTime(2025, 7, 25),
        endDate: DateTime(2025, 7, 27),
        isRaceWeekend: true,
        round: 11,
      ),

      // Round 12: Hungarian Grand Prix
      RaceWeekend(
        name: "Hungarian Grand Prix",
        track: TrackData.getTrackByName("Hungaroring"),
        startDate: DateTime(2025, 8, 1),
        endDate: DateTime(2025, 8, 3),
        isRaceWeekend: true,
        round: 12,
      ),

      // Round 13: Belgian Grand Prix (Spa-Francorchamps)
      RaceWeekend(
        name: "Belgian Grand Prix",
        track: TrackData.getTrackByName("Spa-Francorchamps"),
        startDate: DateTime(2025, 8, 29),
        endDate: DateTime(2025, 8, 31),
        isRaceWeekend: true,
        round: 13,
      ),

      // Round 14: Dutch Grand Prix
      RaceWeekend(
        name: "Dutch Grand Prix",
        track: TrackData.getTrackByName("Netherlands"),
        startDate: DateTime(2025, 9, 5),
        endDate: DateTime(2025, 9, 7),
        isRaceWeekend: true,
        round: 14,
      ),

      // Round 15: Italian Grand Prix (Monza)
      RaceWeekend(
        name: "Italian Grand Prix",
        track: TrackData.getTrackByName("Monza"),
        startDate: DateTime(2025, 9, 19),
        endDate: DateTime(2025, 9, 21),
        isRaceWeekend: true,
        round: 15,
      ),

      // Round 16: Azerbaijan Grand Prix
      RaceWeekend(
        name: "Azerbaijan Grand Prix",
        track: TrackData.getTrackByName("Azerbaijan"),
        startDate: DateTime(2025, 10, 3),
        endDate: DateTime(2025, 10, 5),
        isRaceWeekend: true,
        round: 16,
      ),

      // Round 17: Singapore Grand Prix (Night Race)
      RaceWeekend(
        name: "Singapore Grand Prix",
        track: TrackData.getTrackByName("Singapore"),
        startDate: DateTime(2025, 10, 17),
        endDate: DateTime(2025, 10, 19),
        isRaceWeekend: true,
        round: 17,
      ),

      // Round 18: United States Grand Prix (COTA)
      RaceWeekend(
        name: "United States Grand Prix",
        track: TrackData.getTrackByName("United States"),
        startDate: DateTime(2025, 10, 24),
        endDate: DateTime(2025, 10, 26),
        isRaceWeekend: true,
        round: 18,
      ),

      // Round 19: Mexican Grand Prix
      RaceWeekend(
        name: "Mexican Grand Prix",
        track: TrackData.getTrackByName("Mexico"),
        startDate: DateTime(2025, 11, 7),
        endDate: DateTime(2025, 11, 9),
        isRaceWeekend: true,
        round: 19,
      ),

      // Round 20: Brazilian Grand Prix
      RaceWeekend(
        name: "Brazilian Grand Prix",
        track: TrackData.getTrackByName("Brazil"),
        startDate: DateTime(2025, 11, 14),
        endDate: DateTime(2025, 11, 16),
        isRaceWeekend: true,
        round: 20,
      ),

      // Round 21: Las Vegas Grand Prix
      RaceWeekend(
        name: "Las Vegas Grand Prix",
        track: TrackData.getTrackByName("Las Vegas"),
        startDate: DateTime(2025, 11, 21),
        endDate: DateTime(2025, 11, 23),
        isRaceWeekend: true,
        round: 21,
      ),

      // Round 22: Qatar Grand Prix
      RaceWeekend(
        name: "Qatar Grand Prix",
        track: TrackData.getTrackByName("Qatar"),
        startDate: DateTime(2025, 11, 28),
        endDate: DateTime(2025, 11, 30),
        isRaceWeekend: true,
        round: 22,
      ),

      // Round 23: Abu Dhabi Grand Prix (Season Finale)
      RaceWeekend(
        name: "Abu Dhabi Grand Prix",
        track: TrackData.getTrackByName("Abu Dhabi"),
        startDate: DateTime(2025, 12, 5),
        endDate: DateTime(2025, 12, 7),
        isRaceWeekend: true,
        round: 23,
      ),
      // Add more races as needed...
    ];
  }

  RaceWeekend? getRaceWeekendByName(String name) {
    try {
      return _raceWeekends.firstWhere((race) => race.name == name);
    } catch (e) {
      return null;
    }
  }

// Helper method to get upcoming races (add to CareerCalendar class if needed)
  List<RaceWeekend> getUpcomingRaces({int limit = 5}) {
    final now = DateTime.now();
    return _raceWeekends.where((race) => race.startDate.isAfter(now) && !race.isCompleted).take(limit).toList();
  }

// Helper method to get completed races (add to CareerCalendar class if needed)
  List<RaceWeekend> getCompletedRaces() {
    return _raceWeekends.where((race) => race.isCompleted).toList();
  }

// Helper method to get current championship standings position
  int getCurrentRound() {
    final completedRaces = getCompletedRaces();
    return completedRaces.length + 1;
  }

  // Date formatting
  String get currentDateFormatted {
    return "${_currentDate.day}/${_currentDate.month}/${_currentDate.year}";
  }

  String get currentMonthYear {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return "${months[_currentDate.month - 1]} ${_currentDate.year}";
  }

  int get daysUntilNextRace {
    RaceWeekend? next = nextRaceWeekend;
    if (next == null) return -1;
    return next.startDate.difference(_currentDate).inDays;
  }

  // Speed control
  void setSpeedNormal() => setCalendarSpeed(Duration(days: 1), Duration(milliseconds: 500));
  void setSpeedFast() => setCalendarSpeed(Duration(days: 3), Duration(milliseconds: 300));

  void setCalendarSpeed(Duration timeStep, Duration tickInterval) {
    _timeStep = timeStep;
    _tickInterval = tickInterval;

    if (_isRunning && !_isPaused) {
      _startProgressTimer();
    }
  }

  @override
  void dispose() {
    _stopProgressTimer();
    super.dispose();
  }
}
