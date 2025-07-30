// lib/services/career/save_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/career/career_driver.dart';
import '../../data/team_data.dart';
import 'career_manager.dart';

class SaveManager {
  static const String _currentCareerKey = 'current_career';
  static const String _careerSlotsKey = 'career_slots';
  static const int maxCareerSlots = 3;

  /// Save current career progress
  static Future<bool> saveCurrentCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (CareerManager.currentCareerDriver == null) {
        return false;
      }

      // Create save data
      Map<String, dynamic> saveData = {
        'version': '1.0',
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
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

  /// Load current career progress
  static Future<bool> loadCurrentCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_currentCareerKey);

      if (jsonString == null) {
        return false;
      }

      Map<String, dynamic> saveData = jsonDecode(jsonString);

      // Validate save data
      if (!_isValidSaveData(saveData)) {
        return false;
      }

      // Load career data
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
        'seasonsCompleted': driverData['seasonsCompleted'] ?? 0,
        'savedAt': saveData['savedAt'],
      };
    } catch (e) {
      debugPrint('Error getting career save info: $e');
      return null;
    }
  }

  /// Delete current career save
  static Future<bool> deleteCurrentCareer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentCareerKey);

      // Reset career manager
      CareerManager.resetCareer();

      return true;
    } catch (e) {
      debugPrint('Error deleting career: $e');
      return false;
    }
  }

  /// Get all career save slots
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

      // Create save data
      Map<String, dynamic> saveData = {
        'version': '1.0',
        'slotIndex': slotIndex,
        'slotName': slotName,
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
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

      Map<String, dynamic> exportData = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
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

  // In save_manager.dart, in the _loadCareerFromSaveData method:
  static Future<void> _loadCareerFromSaveData(Map<String, dynamic> saveData) async {
    // Extract data
    int currentSeason = saveData['currentSeason'];
    Map<String, dynamic> driverData = saveData['careerDriver'];

    // Get team by name
    String teamName = driverData['teamName'];
    var team = TeamData.getTeamByName(teamName);

    // Create career driver from save data - FIX: Add the team parameter
    CareerDriver careerDriver = CareerDriver.fromJson(driverData, team);

    // Update career manager - Use the proper method to set the data
    CareerManager.resetCareer();
    CareerManager.loadCareerDriver(careerDriver, currentSeason);
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
}
