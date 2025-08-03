// lib/services/career/save_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/career/career_driver.dart';
import '../../models/career/race_weekend.dart';
import '../../data/team_data.dart';
import 'career_manager.dart';
import 'career_calendar.dart';

// Save slot metadata for preview purposes
class SaveSlot {
  final int slotIndex;
  final String saveName;
  final String driverName;
  final String teamName;
  final int currentSeason;
  final int completedRaces;
  final int careerWins;
  final int careerPoints;
  final DateTime lastSaved;
  final String? nextRaceName;
  final bool isEmpty;

  SaveSlot({
    required this.slotIndex,
    required this.saveName,
    required this.driverName,
    required this.teamName,
    required this.currentSeason,
    required this.completedRaces,
    required this.careerWins,
    required this.careerPoints,
    required this.lastSaved,
    this.nextRaceName,
    this.isEmpty = false,
  });

  static SaveSlot empty(int slotIndex) {
    return SaveSlot(
      slotIndex: slotIndex,
      saveName: 'Empty Slot',
      driverName: '',
      teamName: '',
      currentSeason: 0,
      completedRaces: 0,
      careerWins: 0,
      careerPoints: 0,
      lastSaved: DateTime.now(),
      isEmpty: true,
    );
  }

  factory SaveSlot.fromSaveData(int slotIndex, Map<String, dynamic> saveData) {
    try {
      Map<String, dynamic> driverData = saveData['careerDriver'];
      Map<String, dynamic>? calendarData = saveData['calendarState'];

      // Calculate completed races from calendar data
      int completedRaces = 0;
      String? nextRaceName;

      if (calendarData != null && calendarData.containsKey('raceWeekends')) {
        List<dynamic> raceWeekends = calendarData['raceWeekends'];
        completedRaces = raceWeekends.where((race) => race['isCompleted'] == true).length;

        // Find next race
        var nextRace = raceWeekends.firstWhere(
          (race) => race['isCompleted'] != true,
          orElse: () => null,
        );
        nextRaceName = nextRace?['name'];
      }

      return SaveSlot(
        slotIndex: slotIndex,
        saveName: saveData['slotName'] ?? '${driverData['name']} Career',
        driverName: driverData['name'] ?? 'Unknown Driver',
        teamName: driverData['teamName'] ?? 'Unknown Team',
        currentSeason: saveData['currentSeason'] ?? 2025,
        completedRaces: completedRaces,
        careerWins: driverData['careerWins'] ?? 0,
        careerPoints: driverData['careerPoints'] ?? 0,
        lastSaved: DateTime.parse(saveData['savedAt']),
        nextRaceName: nextRaceName,
        isEmpty: false,
      );
    } catch (e) {
      debugPrint('Error creating SaveSlot from data: $e');
      return SaveSlot.empty(slotIndex);
    }
  }

  String get progressText {
    if (isEmpty) return 'Empty';
    if (completedRaces == 0) return 'Season start';
    if (completedRaces >= 23) return 'Season complete';
    return 'Race ${completedRaces + 1}/23';
  }

  String get lastSavedText {
    final now = DateTime.now();
    final difference = now.difference(lastSaved);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class SaveManager {
  static const String _currentCareerKey = 'current_career';
  static const String _careerSlotsKey = 'career_slots';
  static const int maxCareerSlots = 5; // Increased from 3 to 5
  static const String _saveVersion = '1.1'; // Version for save compatibility

  /// Save current career progress (ENHANCED with calendar state)
  static Future<bool> saveCurrentCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (CareerManager.currentCareerDriver == null) {
        return false;
      }

      // Include calendar state in save data
      List<Map<String, dynamic>> raceWeekendData = [];
      for (RaceWeekend weekend in CareerCalendar.instance.raceWeekends) {
        raceWeekendData.add({
          'name': weekend.name,
          'isCompleted': weekend.isCompleted,
          'hasQualifyingResults': weekend.hasQualifyingResults,
          'hasRaceResults': weekend.hasRaceResults,
          'round': weekend.round,
        });
      }

      int completedRacesCount = raceWeekendData.where((r) => r['isCompleted'] == true).length;
      debugPrint("💾 Saving career with $completedRacesCount completed races");

      // Create comprehensive save data
      Map<String, dynamic> saveData = {
        'version': _saveVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      // Save to shared preferences
      String jsonString = jsonEncode(saveData);
      await prefs.setString(_currentCareerKey, jsonString);

      debugPrint("✅ Career saved successfully");
      return true;
    } catch (e) {
      debugPrint('❌ Error saving career: $e');
      return false;
    }
  }

  /// Load current career progress (ENHANCED with calendar state)
  static Future<bool> loadCurrentCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_currentCareerKey);

      if (jsonString == null) {
        debugPrint("📅 No saved career found");
        return false;
      }

      Map<String, dynamic> saveData = jsonDecode(jsonString);

      // Validate save data
      if (!_isValidSaveData(saveData)) {
        debugPrint("❌ Invalid save data");
        return false;
      }

      debugPrint("📅 Loading saved career...");

      // Load calendar state FIRST to prevent it being overwritten
      if (saveData.containsKey('calendarState')) {
        debugPrint("📅 Loading calendar state from save data...");
        await _loadCalendarState(saveData['calendarState']);
      } else {
        debugPrint("⚠️ No calendar state in save data - will use fresh calendar");
      }

      // Then load career data
      await _loadCareerFromSaveData(saveData);

      return true;
    } catch (e) {
      debugPrint('❌ Error loading career: $e');
      return false;
    }
  }

  /// Check if there's a saved career
  static Future<bool> hasSavedCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_currentCareerKey);
    } catch (e) {
      return false;
    }
  }

  /// Get career save info without loading
  static Future<Map<String, dynamic>?> getCareerSaveInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_currentCareerKey);

      if (jsonString == null) {
        return null;
      }

      Map<String, dynamic> saveData = jsonDecode(jsonString);

      if (!_isValidSaveData(saveData)) {
        return null;
      }

      Map<String, dynamic> driverData = saveData['careerDriver'];

      return {
        'driverName': driverData['name'],
        'teamName': driverData['teamName'],
        'currentSeason': saveData['currentSeason'],
        'careerWins': driverData['careerWins'] ?? 0,
        'careerPoints': driverData['careerPoints'] ?? 0,
        'savedAt': saveData['savedAt'],
      };
    } catch (e) {
      return null;
    }
  }

  /// ENHANCED: Get all career save slots with metadata
  static Future<List<SaveSlot>> getAllSaveSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_careerSlotsKey);

      List<SaveSlot> slots = [];

      if (jsonString != null) {
        List<dynamic> slotsData = jsonDecode(jsonString);

        for (int i = 0; i < maxCareerSlots; i++) {
          if (i < slotsData.length && slotsData[i] != null && slotsData[i].isNotEmpty) {
            try {
              Map<String, dynamic> slotData = Map<String, dynamic>.from(slotsData[i]);
              if (_isValidSaveData(slotData)) {
                slots.add(SaveSlot.fromSaveData(i, slotData));
              } else {
                slots.add(SaveSlot.empty(i));
              }
            } catch (e) {
              debugPrint('Error parsing slot $i: $e');
              slots.add(SaveSlot.empty(i));
            }
          } else {
            slots.add(SaveSlot.empty(i));
          }
        }
      } else {
        // Create empty slots if no saves exist
        for (int i = 0; i < maxCareerSlots; i++) {
          slots.add(SaveSlot.empty(i));
        }
      }

      return slots;
    } catch (e) {
      debugPrint('❌ Error getting save slots: $e');

      // Return empty slots on error
      List<SaveSlot> emptySlots = [];
      for (int i = 0; i < maxCareerSlots; i++) {
        emptySlots.add(SaveSlot.empty(i));
      }
      return emptySlots;
    }
  }

  /// ENHANCED: Save career to specific slot with custom name
  static Future<bool> saveCareerToSlot(int slotIndex, String slotName) async {
    if (slotIndex < 0 || slotIndex >= maxCareerSlots) {
      debugPrint('❌ Invalid slot index: $slotIndex');
      return false;
    }

    try {
      if (CareerManager.currentCareerDriver == null) {
        debugPrint('❌ No career driver to save');
        return false;
      }

      // Include calendar state in slot saves
      List<Map<String, dynamic>> raceWeekendData = [];
      for (RaceWeekend weekend in CareerCalendar.instance.raceWeekends) {
        raceWeekendData.add({
          'name': weekend.name,
          'isCompleted': weekend.isCompleted,
          'hasQualifyingResults': weekend.hasQualifyingResults,
          'hasRaceResults': weekend.hasRaceResults,
          'round': weekend.round,
        });
      }

      // Create save data with slot-specific info
      Map<String, dynamic> saveData = {
        'version': _saveVersion,
        'slotIndex': slotIndex,
        'slotName': slotName.isNotEmpty ? slotName : '${CareerManager.currentCareerDriver!.name} Career',
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      // Get existing slots
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> slots = [];

      String? existingData = prefs.getString(_careerSlotsKey);
      if (existingData != null) {
        List<dynamic> existingSlots = jsonDecode(existingData);
        slots = existingSlots.map((slot) => Map<String, dynamic>.from(slot ?? {})).toList();
      }

      // Ensure we have enough slots
      while (slots.length <= slotIndex) {
        slots.add({});
      }

      // Update the specific slot
      slots[slotIndex] = saveData;

      // Save updated slots
      String jsonString = jsonEncode(slots);
      await prefs.setString(_careerSlotsKey, jsonString);

      debugPrint("✅ Career saved to slot $slotIndex as '$slotName'");
      return true;
    } catch (e) {
      debugPrint('❌ Error saving career to slot: $e');
      return false;
    }
  }

  /// ENHANCED: Load career from specific slot
  static Future<bool> loadCareerFromSlot(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= maxCareerSlots) {
      debugPrint('❌ Invalid slot index: $slotIndex');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_careerSlotsKey);

      if (jsonString == null) {
        debugPrint('❌ No save slots found');
        return false;
      }

      List<dynamic> slotsData = jsonDecode(jsonString);

      if (slotIndex >= slotsData.length || slotsData[slotIndex] == null || slotsData[slotIndex].isEmpty) {
        debugPrint('❌ Slot $slotIndex is empty');
        return false;
      }

      Map<String, dynamic> saveData = Map<String, dynamic>.from(slotsData[slotIndex]);

      if (!_isValidSaveData(saveData)) {
        debugPrint('❌ Invalid save data in slot $slotIndex');
        return false;
      }

      debugPrint("📥 Loading career from slot $slotIndex...");

      // Load calendar state first
      if (saveData.containsKey('calendarState')) {
        await _loadCalendarState(saveData['calendarState']);
      }

      // Load career data
      await _loadCareerFromSaveData(saveData);

      // Also save as current career for backward compatibility
      await saveCurrentCareer();

      debugPrint("✅ Career loaded successfully from slot $slotIndex");
      return true;
    } catch (e) {
      debugPrint('❌ Error loading career from slot: $e');
      return false;
    }
  }

  /// ENHANCED: Delete career from specific slot
  static Future<bool> deleteCareerFromSlot(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= maxCareerSlots) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_careerSlotsKey);

      if (jsonString == null) {
        return true; // Already empty
      }

      List<dynamic> slotsData = jsonDecode(jsonString);

      if (slotIndex < slotsData.length) {
        slotsData[slotIndex] = {};

        String updatedJsonString = jsonEncode(slotsData);
        await prefs.setString(_careerSlotsKey, updatedJsonString);

        debugPrint("✅ Deleted career from slot $slotIndex");
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting career from slot: $e');
      return false;
    }
  }

  /// Export career data as JSON string
  static Future<String?> exportCareerData() async {
    try {
      if (CareerManager.currentCareerDriver == null) {
        return null;
      }

      // Include calendar state in exports
      List<Map<String, dynamic>> raceWeekendData = [];
      for (RaceWeekend weekend in CareerCalendar.instance.raceWeekends) {
        raceWeekendData.add({
          'name': weekend.name,
          'isCompleted': weekend.isCompleted,
          'hasQualifyingResults': weekend.hasQualifyingResults,
          'hasRaceResults': weekend.hasRaceResults,
          'round': weekend.round,
        });
      }

      Map<String, dynamic> exportData = {
        'version': _saveVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('❌ Error exporting career: $e');
      return null;
    }
  }

  /// Import career data from JSON string
  static Future<bool> importCareerData(String jsonData) async {
    try {
      Map<String, dynamic> importData = jsonDecode(jsonData);

      if (!_isValidSaveData(importData)) {
        return false;
      }

      // Load calendar state first
      if (importData.containsKey('calendarState')) {
        await _loadCalendarState(importData['calendarState']);
      }

      // Load career data
      await _loadCareerFromSaveData(importData);

      // Save as current career
      await saveCurrentCareer();

      debugPrint("✅ Career imported successfully");
      return true;
    } catch (e) {
      debugPrint('❌ Error importing career: $e');
      return false;
    }
  }

  /// Auto-save current career (call this after important events)
  static Future<void> autoSave() async {
    if (CareerManager.currentCareerDriver != null) {
      await saveCurrentCareer();
      debugPrint('💾 Career auto-saved');
    }
  }

  /// Clear all save data (for debugging)
  static Future<void> clearAllSaveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentCareerKey);
      await prefs.remove(_careerSlotsKey);

      CareerManager.resetCareer();
      debugPrint("🗑️ All save data cleared");
    } catch (e) {
      debugPrint('❌ Error clearing save data: $e');
    }
  }

  /// Get save file size info
  static Future<Map<String, dynamic>> getSaveInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_currentCareerKey);

      if (jsonString == null) {
        return {
          'exists': false,
          'size': 0,
          'lastSaved': null,
        };
      }

      Map<String, dynamic> saveData = jsonDecode(jsonString);

      return {
        'exists': true,
        'size': jsonString.length,
        'lastSaved': saveData['savedAt'],
        'version': saveData['version'],
      };
    } catch (e) {
      return {
        'exists': false,
        'size': 0,
        'lastSaved': null,
        'error': e.toString(),
      };
    }
  }

  // Private helper methods

  static bool _isValidSaveData(Map<String, dynamic> saveData) {
    return saveData.containsKey('version') &&
        saveData.containsKey('currentSeason') &&
        saveData.containsKey('careerDriver') &&
        saveData['careerDriver'] is Map &&
        saveData['careerDriver']['name'] != null;
  }

  static Future<void> _loadCareerFromSaveData(Map<String, dynamic> saveData) async {
    try {
      // Extract data
      int currentSeason = saveData['currentSeason'];
      Map<String, dynamic> driverData = saveData['careerDriver'];

      // Get team by name
      String teamName = driverData['teamName'];
      var team = TeamData.getTeamByName(teamName);

      // Create career driver from save data
      CareerDriver careerDriver = CareerDriver.fromJson(driverData, team);

      // Update career manager
      CareerManager.resetCareer();
      CareerManager.loadCareerDriver(careerDriver, currentSeason);

      debugPrint("✅ Career driver data loaded successfully");
    } catch (e) {
      debugPrint("❌ Error loading career from save data: $e");
      throw e;
    }
  }

  static Future<void> _loadCalendarState(Map<String, dynamic> calendarData) async {
    try {
      // Initialize calendar first
      CareerCalendar.instance.initialize();

      // Load basic calendar data
      if (calendarData.containsKey('currentDate')) {
        String currentDateStr = calendarData['currentDate'];
        CareerCalendar.instance.setCurrentDate(DateTime.parse(currentDateStr));
      }

      if (calendarData.containsKey('currentRaceIndex')) {
        int currentRaceIndex = calendarData['currentRaceIndex'] ?? 0;
        CareerCalendar.instance.setCurrentRaceIndex(currentRaceIndex);
      }

      // Load race completion states
      if (calendarData.containsKey('raceWeekends')) {
        List<dynamic> raceWeekendData = calendarData['raceWeekends'];

        for (Map<String, dynamic> raceData in raceWeekendData) {
          String raceName = raceData['name'];
          bool isCompleted = raceData['isCompleted'] ?? false;
          bool hasQualifyingResults = raceData['hasQualifyingResults'] ?? false;
          bool hasRaceResults = raceData['hasRaceResults'] ?? false;

          // Update the race weekend state
          CareerCalendar.instance.updateRaceWeekendState(
            raceName,
            isCompleted: isCompleted,
            hasQualifyingResults: hasQualifyingResults,
            hasRaceResults: hasRaceResults,
          );
        }
      }

      int completedCount = CareerCalendar.instance.getCompletedRaces().length;
      debugPrint("✅ Calendar state loaded successfully");
      debugPrint("   Completed races: $completedCount");
      debugPrint("   Next race: ${CareerCalendar.instance.nextRaceWeekend?.name ?? 'None'}");
    } catch (e) {
      debugPrint("❌ Error loading calendar state: $e");
      // Fall back to fresh calendar
      CareerCalendar.instance.initialize();
    }
  }
}
