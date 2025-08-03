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
  static const String _currentCareerKey = 'current_career'; // Main save (dedicated)
  static const String _careerSlotsKey = 'career_slots'; // Additional slots
  static const int maxAdditionalSlots = 2; // Only 2 additional slots now

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
      debugPrint("💾 Saving calendar state with $completedRacesCount completed races");

      // Create save data (enhanced with calendar state)
      Map<String, dynamic> saveData = {
        'version': '1.0',
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        // Add calendar state
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      // Save to shared preferences
      String jsonString = jsonEncode(saveData);
      await prefs.setString(_currentCareerKey, jsonString);

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

  /// Get all additional career slots (not including main)
  static Future<List<Map<String, dynamic>>> getAdditionalSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_careerSlotsKey);

      if (jsonString == null) {
        return List.generate(maxAdditionalSlots, (index) => <String, dynamic>{});
      }

      List<dynamic> slotsData = jsonDecode(jsonString);
      List<Map<String, dynamic>> slots = slotsData.cast<Map<String, dynamic>>();

      // Ensure we always have exactly maxAdditionalSlots
      while (slots.length < maxAdditionalSlots) {
        slots.add(<String, dynamic>{});
      }

      return slots.take(maxAdditionalSlots).toList();
    } catch (e) {
      debugPrint('Error getting additional slots: $e');
      return List.generate(maxAdditionalSlots, (index) => <String, dynamic>{});
    }
  }

  /// Save career to additional slot (not main)
  static Future<bool> saveCareerToAdditionalSlot(int slotIndex, String slotName) async {
    if (slotIndex < 0 || slotIndex >= maxAdditionalSlots) {
      debugPrint('❌ Invalid slot index: $slotIndex');
      return false;
    }

    try {
      if (CareerManager.currentCareerDriver == null) {
        debugPrint('❌ No current career to save');
        return false;
      }

      // Create save data (same as main save structure)
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

      Map<String, dynamic> saveData = {
        'version': '1.0',
        'slotIndex': slotIndex,
        'slotName': slotName,
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
      };

      final prefs = await SharedPreferences.getInstance();

      // Get existing additional slots
      List<Map<String, dynamic>> slots = await getAdditionalSlots();

      // Update the specific slot
      slots[slotIndex] = saveData;

      // Save updated slots
      String jsonString = jsonEncode(slots);
      await prefs.setString(_careerSlotsKey, jsonString);

      debugPrint('✅ Career saved to additional slot ${slotIndex + 1}');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving career to additional slot: $e');
      return false;
    }
  }

  /// Load career from additional slot to main
  static Future<bool> loadCareerFromAdditionalSlot(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= maxAdditionalSlots) {
      return false;
    }

    try {
      List<Map<String, dynamic>> slots = await getAdditionalSlots();

      if (slots[slotIndex].isEmpty) {
        debugPrint('❌ Slot ${slotIndex + 1} is empty');
        return false;
      }

      Map<String, dynamic> saveData = slots[slotIndex];

      if (!_isValidSaveData(saveData)) {
        debugPrint('❌ Invalid save data in slot ${slotIndex + 1}');
        return false;
      }

      // Load career data
      await _loadCareerFromSaveData(saveData);

      // Save as main career
      await saveCurrentCareer();

      debugPrint('✅ Career loaded from additional slot ${slotIndex + 1} to main');
      return true;
    } catch (e) {
      debugPrint('❌ Error loading from additional slot: $e');
      return false;
    }
  }

  /// Delete specific additional slot
  static Future<bool> deleteAdditionalSlot(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= maxAdditionalSlots) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing slots
      List<Map<String, dynamic>> slots = await getAdditionalSlots();

      // Clear the specific slot
      slots[slotIndex] = <String, dynamic>{};

      // Save updated slots
      String jsonString = jsonEncode(slots);
      await prefs.setString(_careerSlotsKey, jsonString);

      debugPrint('✅ Additional slot ${slotIndex + 1} deleted successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting additional slot ${slotIndex + 1}: $e');
      return false;
    }
  }

  /// Delete main career save (no need to check slots since main is separate)
  static Future<void> clearMainSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentCareerKey); // Only remove main save

      CareerManager.resetCareer();
      debugPrint('✅ Main career save deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting main career save: $e');
      rethrow;
    }
  }

  /// Clear all save data (for debugging - clears main + all additional slots)
  static Future<void> clearAllSaveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentCareerKey); // Main save
      await prefs.remove(_careerSlotsKey); // Additional slots

      CareerManager.resetCareer();
      debugPrint('✅ All save data cleared (main + additional slots)');
    } catch (e) {
      debugPrint('❌ Error clearing all save data: $e');
      rethrow;
    }
  }

  /// Export career data as JSON string
  static Future<String?> exportCareerData() async {
    try {
      if (CareerManager.currentCareerDriver == null) {
        return null;
      }

      // Enhanced: Include calendar state in exports
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
        // Add calendar state to exports
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

  // PRIVATE HELPER METHODS

  /// Validate save data structure
  static bool _isValidSaveData(Map<String, dynamic> saveData) {
    try {
      return saveData.containsKey('version') &&
          saveData.containsKey('careerDriver') &&
          saveData.containsKey('currentSeason') &&
          saveData['careerDriver'] is Map<String, dynamic>;
    } catch (e) {
      return false;
    }
  }

  /// Load career from save data
  static Future<void> _loadCareerFromSaveData(Map<String, dynamic> saveData) async {
    try {
      // Load career manager data
      CareerManager.loadCareer(saveData);
      debugPrint("✅ Career data loaded successfully");
    } catch (e) {
      debugPrint("❌ Error loading career from save data: $e");
      rethrow;
    }
  }

  /// Load calendar state from save data
  static Future<void> _loadCalendarState(Map<String, dynamic> calendarData) async {
    try {
      // Parse current date
      DateTime currentDate = DateTime.parse(calendarData['currentDate']);
      int currentRaceIndex = calendarData['currentRaceIndex'] ?? 0;

      // Update calendar instance
      CareerCalendar.instance.setCurrentDate(currentDate);
      CareerCalendar.instance.setCurrentRaceIndex(currentRaceIndex);

      // Load race weekend states
      List<dynamic> raceWeekendData = calendarData['raceWeekends'] ?? [];

      for (var raceData in raceWeekendData) {
        String raceName = raceData['name'] ?? '';
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
