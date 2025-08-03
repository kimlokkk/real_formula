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

class SaveManager {
  static const String _currentCareerKey = 'current_career';
  static const String _careerSlotsKey = 'career_slots';
  static const int maxCareerSlots = 3;

  /// Save current career progress (ENHANCED with calendar state)
  static Future<bool> saveCurrentCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (CareerManager.currentCareerDriver == null) {
        return false;
      }

      // 🔧 NEW: Include calendar state in save data
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
      debugPrint("💾 Saving calendar state with $completedRacesCount completed races");

      // Create save data (enhanced with calendar state)
      Map<String, dynamic> saveData = {
        'version': '1.0',
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        // 🔧 NEW: Add calendar state
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      // Save to shared preferences
      String jsonString = jsonEncode(saveData);
      await prefs.setString(_currentCareerKey, jsonString);

      // Also update career slots list
      await _updateCareerSlotsList(saveData);

      return true;
    } catch (e) {
      debugPrint('Error saving career: $e');
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

      // 🔧 FIX: Load calendar state FIRST to prevent it being overwritten
      if (saveData.containsKey('calendarState')) {
        debugPrint("📅 Loading calendar state from save data...");
        await _loadCalendarState(saveData['calendarState']);
      } else {
        debugPrint("⚠️ No calendar state in save data - will use fresh calendar");
        // Don't initialize here - let the career home page handle it if needed
      }

      // Then load career data
      await _loadCareerFromSaveData(saveData);

      return true;
    } catch (e) {
      debugPrint('Error loading career: $e');
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

  /// Get all career slots
  static Future<List<Map<String, dynamic>>> getCareerSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_careerSlotsKey);

      if (jsonString == null) {
        return [];
      }

      List<dynamic> slotsData = jsonDecode(jsonString);
      return slotsData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error getting career slots: $e');
      return [];
    }
  }

  /// Save career to specific slot
  static Future<bool> saveCareerToSlot(int slotIndex, String slotName) async {
    if (slotIndex < 0 || slotIndex >= maxCareerSlots) {
      return false;
    }

    try {
      if (CareerManager.currentCareerDriver == null) {
        return false;
      }

      // 🔧 Enhanced: Include calendar state in slot saves too
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

      // Create save data
      Map<String, dynamic> saveData = {
        'version': '1.0',
        'slotIndex': slotIndex,
        'slotName': slotName,
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        // 🔧 NEW: Add calendar state to slot saves
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      final prefs = await SharedPreferences.getInstance();

      // Get existing slots
      List<Map<String, dynamic>> slots = await getCareerSlots();

      // Ensure we have enough slots
      while (slots.length <= slotIndex) {
        slots.add({});
      }

      // Update the specific slot
      slots[slotIndex] = saveData;

      // Save updated slots
      String jsonString = jsonEncode(slots);
      await prefs.setString(_careerSlotsKey, jsonString);

      return true;
    } catch (e) {
      debugPrint('Error saving career to slot: $e');
      return false;
    }
  }

  /// Load career from specific slot
  static Future<bool> loadCareerFromSlot(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= maxCareerSlots) {
      return false;
    }

    try {
      List<Map<String, dynamic>> slots = await getCareerSlots();

      if (slotIndex >= slots.length || slots[slotIndex].isEmpty) {
        return false;
      }

      Map<String, dynamic> saveData = slots[slotIndex];

      if (!_isValidSaveData(saveData)) {
        return false;
      }

      // Load career data
      await _loadCareerFromSaveData(saveData);

      // Also save as current career
      await saveCurrentCareer();

      return true;
    } catch (e) {
      debugPrint('Error loading career from slot: $e');
      return false;
    }
  }

  /// Export career data as JSON string
  static Future<String?> exportCareerData() async {
    try {
      if (CareerManager.currentCareerDriver == null) {
        return null;
      }

      // 🔧 Enhanced: Include calendar state in exports
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
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        // 🔧 NEW: Add calendar state to exports
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      return jsonEncode(exportData);
    } catch (e) {
      debugPrint('Error exporting career: $e');
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

      // Load career data
      await _loadCareerFromSaveData(importData);

      // Save as current career
      await saveCurrentCareer();

      return true;
    } catch (e) {
      debugPrint('Error importing career: $e');
      return false;
    }
  }

  /// Clear all save data (for debugging)
  static Future<void> clearAllSaveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentCareerKey);
      await prefs.remove(_careerSlotsKey);

      CareerManager.resetCareer();
    } catch (e) {
      debugPrint('Error clearing save data: $e');
    }
  }

  // Private helper methods

  static bool _isValidSaveData(Map<String, dynamic> saveData) {
    return saveData.containsKey('version') &&
        saveData.containsKey('currentSeason') &&
        saveData.containsKey('careerDriver') &&
        saveData['careerDriver'] is Map;
  }

  // 🔧 UPDATE your existing _loadCareerFromSaveData() method:
  static Future<void> _loadCareerFromSaveData(Map<String, dynamic> saveData) async {
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
    // Note: Calendar state should already be loaded by now
  }

  // 🔧 NEW: Method to load calendar state
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

  static Future<void> _updateCareerSlotsList(Map<String, dynamic> saveData) async {
    try {
      // This is for quick access to career saves
      // Implementation would maintain a list of save summaries
      // For now, we'll keep it simple and just use the main save
    } catch (e) {
      debugPrint('Error updating career slots list: $e');
    }
  }

  /// Auto-save current career (call this after important events)
  static Future<void> autoSave() async {
    if (CareerManager.currentCareerDriver != null) {
      await saveCurrentCareer();
      debugPrint('Career auto-saved');
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

  // Delete specific career slot
  static Future<bool> deleteCareerSlot(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= maxCareerSlots) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing slots
      List<Map<String, dynamic>> slots = await getCareerSlots();

      // Ensure we have enough slots
      while (slots.length <= slotIndex) {
        slots.add({});
      }

      // Clear the specific slot
      slots[slotIndex] = {};

      // Save updated slots
      String jsonString = jsonEncode(slots);
      await prefs.setString(_careerSlotsKey, jsonString);

      debugPrint('✅ Career slot $slotIndex deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting career slot $slotIndex: $e');
      return false;
    }
  }
}
