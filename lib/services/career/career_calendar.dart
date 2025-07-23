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
      RaceWeekend(
        name: "Bahrain Grand Prix",
        track: TrackData.tracks.firstWhere((t) => t.name == "Bahrain"),
        startDate: DateTime(2025, 3, 14),
        endDate: DateTime(2025, 3, 16),
        isRaceWeekend: true,
        round: 1,
      ),
      RaceWeekend(
        name: "Saudi Arabian Grand Prix",
        track: TrackData.tracks.firstWhere((t) => t.name == "Saudi Arabia"),
        startDate: DateTime(2025, 3, 21),
        endDate: DateTime(2025, 3, 23),
        isRaceWeekend: true,
        round: 2,
      ),
      RaceWeekend(
        name: "Australian Grand Prix",
        track: TrackData.tracks.firstWhere((t) => t.name == "Australia"),
        startDate: DateTime(2025, 4, 4),
        endDate: DateTime(2025, 4, 6),
        isRaceWeekend: true,
        round: 3,
      ),
      // Add more races as needed...
    ];
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
