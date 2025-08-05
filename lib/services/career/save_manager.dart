// lib/services/career/save_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:real_formula/services/career/championship_manager.dart';
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
  final String? careerId; // ADDED: Career ID for proper identification

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
    this.careerId, // ADDED: Career ID parameter
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
      careerId: null, // ADDED: No career ID for empty slots
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
        completedRaces =
            raceWeekends.where((race) => race['isCompleted'] == true).length;

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
        careerId:
            driverData['careerId'], // ADDED: Extract career ID from save data
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

// COMPLETELY REWRITTEN SaveManager - SLOTS ONLY, NO OLD SYSTEM

class SaveManager {
  // ONLY the slots key - old system completely removed
  static const String _careerSlotsKey = 'career_slots';
  static const int maxCareerSlots = 5;
  static const String _saveVersion =
      '2.1'; // Updated version for career ID support

  static Future<bool> autoLoadMostRecentCareer() async {
    try {
      // Don't auto-load if something is already loaded
      if (CareerManager.currentCareerDriver != null) {
        debugPrint("✅ Career already loaded, skipping auto-load");
        return true;
      }

      List<SaveSlot> slots = await getAllSaveSlots();
      List<SaveSlot> nonEmptySlots =
          slots.where((slot) => !slot.isEmpty).toList();

      if (nonEmptySlots.isEmpty) {
        debugPrint("ℹ️ No saves to auto-load");
        return false;
      }

      // Sort by last saved (most recent first)
      nonEmptySlots.sort((a, b) => b.lastSaved.compareTo(a.lastSaved));

      SaveSlot mostRecent = nonEmptySlots.first;
      debugPrint("🔄 Auto-loading most recent save: ${mostRecent.saveName}");

      // Load the most recent save
      bool loaded = await loadCareerFromSlot(mostRecent.slotIndex);

      if (loaded) {
        debugPrint(
            "✅ Auto-loaded ${mostRecent.driverName} from slot ${mostRecent.slotIndex + 1}");
        return true;
      } else {
        debugPrint("❌ Failed to auto-load career");
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error auto-loading career: $e');
      return false;
    }
  }

  /// Save current career to slot (FIXED: Now uses career ID for proper identification)
  static Future<bool> saveCurrentCareer() async {
    try {
      if (CareerManager.currentCareerDriver == null) {
        return false;
      }

      String currentCareerID = CareerManager.currentCareerDriver!.careerId;
      String driverName = CareerManager.currentCareerDriver!.name;

      // Check if this specific career (by ID) already has a slot
      List<SaveSlot> slots = await getAllSaveSlots();
      int existingSlot = -1;

      for (int i = 0; i < slots.length; i++) {
        if (!slots[i].isEmpty && slots[i].careerId == currentCareerID) {
          existingSlot = i;
          debugPrint(
              "🔄 Found existing slot $i for career ID: $currentCareerID");
          break;
        }
      }

      if (existingSlot >= 0) {
        // Update existing slot for this specific career
        debugPrint("💾 Updating existing career in slot $existingSlot");
        return await saveCareerToSlot(
            existingSlot, slots[existingSlot].saveName);
      } else {
        // Find first empty slot for new career
        for (int i = 0; i < maxCareerSlots; i++) {
          if (i >= slots.length || slots[i].isEmpty) {
            debugPrint("🆕 Saving new career to empty slot $i");
            return await saveCareerToSlot(i, '$driverName Career');
          }
        }

        // If no empty slots, overwrite slot 0 (with warning)
        debugPrint("⚠️ No empty slots! Overwriting slot 0");
        return await saveCareerToSlot(0, '$driverName Career');
      }
    } catch (e) {
      debugPrint('❌ Error saving career: $e');
      return false;
    }
  }

  /// Load career from any slot (finds current driver by ID)
  static Future<bool> loadCurrentCareer() async {
    try {
      if (CareerManager.currentCareerDriver == null) {
        return false;
      }

      String currentCareerID = CareerManager.currentCareerDriver!.careerId;
      List<SaveSlot> slots = await getAllSaveSlots();

      // Find slot with this specific career ID
      for (int i = 0; i < slots.length; i++) {
        if (!slots[i].isEmpty && slots[i].careerId == currentCareerID) {
          return await loadCareerFromSlot(i);
        }
      }

      debugPrint("📅 No saved career found for career ID: $currentCareerID");
      return false;
    } catch (e) {
      debugPrint('❌ Error loading career: $e');
      return false;
    }
  }

  /// Check if there's any saved career
  static Future<bool> hasSavedCareer() async {
    try {
      List<SaveSlot> slots = await getAllSaveSlots();
      return slots.any((slot) => !slot.isEmpty);
    } catch (e) {
      return false;
    }
  }

  /// Check if current career should show Continue button
  static Future<bool> shouldShowContinueCareer() async {
    try {
      // Simply check if we have a loaded career AND it exists in slots
      if (CareerManager.currentCareerDriver == null) {
        debugPrint("ℹ️ No career loaded - no continue button");
        return false;
      }

      String currentCareerID = CareerManager.currentCareerDriver!.careerId;
      List<SaveSlot> slots = await getAllSaveSlots();

      bool existsInSlots = slots
          .any((slot) => !slot.isEmpty && slot.careerId == currentCareerID);

      if (existsInSlots) {
        debugPrint(
            "✅ Continue career available for career ID: $currentCareerID");
      } else {
        debugPrint("⚠️ Loaded career $currentCareerID not found in slots");
      }

      return existsInSlots;
    } catch (e) {
      debugPrint('❌ Error checking continue career: $e');
      return false;
    }
  }

  /// Get all save slots
  static Future<List<SaveSlot>> getAllSaveSlots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_careerSlotsKey);

      List<SaveSlot> slots = [];

      if (jsonString != null) {
        List<dynamic> slotsData = jsonDecode(jsonString);

        for (int i = 0; i < maxCareerSlots; i++) {
          if (i < slotsData.length &&
              slotsData[i] != null &&
              slotsData[i].isNotEmpty) {
            try {
              Map<String, dynamic> slotData =
                  Map<String, dynamic>.from(slotsData[i]);
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

  /// Save career to specific slot
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

      // Create save data
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

      // 🔧 FIX: Include championship standings in save data
      Map<String, dynamic> saveData = {
        'version': _saveVersion,
        'slotIndex': slotIndex,
        'slotName': slotName.isNotEmpty
            ? slotName
            : '${CareerManager.currentCareerDriver!.name} Career',
        'savedAt': DateTime.now().toIso8601String(),
        'currentSeason': CareerManager.currentSeason,
        'careerDriver': CareerManager.currentCareerDriver!.toJson(),
        'calendarState': {
          'currentDate': CareerCalendar.instance.currentDate.toIso8601String(),
          'currentRaceIndex': CareerCalendar.instance.currentRaceIndex,
          'raceWeekends': raceWeekendData,
        },
        // 🔧 FIX: Add championship standings to save data
        'championshipStandings': ChampionshipManager.toJson(),
        // 🔧 FIX: Include current season drivers for proper championship loading
        'currentSeasonDrivers':
            CareerManager.currentSeasonDrivers.map((d) => d.name).toList(),
      };

      // Get existing slots
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> slots = [];

      String? existingData = prefs.getString(_careerSlotsKey);
      if (existingData != null) {
        List<dynamic> existingSlots = jsonDecode(existingData);
        slots = existingSlots
            .map((slot) => Map<String, dynamic>.from(slot ?? {}))
            .toList();
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

      debugPrint(
          "✅ Career saved to slot $slotIndex with championship standings (ID: ${CareerManager.currentCareerDriver!.careerId})");
      return true;
    } catch (e) {
      debugPrint('❌ Error saving career to slot: $e');
      return false;
    }
  }

  /// Load career from specific slot
  static Future<bool> loadCareerFromSlot(int slotIndex) async {
    if (slotIndex < 0 || slotIndex >= maxCareerSlots) {
      debugPrint('❌ Invalid slot index: $slotIndex');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonString = prefs.getString(_careerSlotsKey);

      if (jsonString == null) {
        debugPrint('❌ No save data found');
        return false;
      }

      List<dynamic> slotsData = jsonDecode(jsonString);

      if (slotIndex >= slotsData.length) {
        debugPrint('❌ Slot index out of range');
        return false;
      }

      Map<String, dynamic> saveData =
          Map<String, dynamic>.from(slotsData[slotIndex] ?? {});

      if (saveData.isEmpty || !_isValidSaveData(saveData)) {
        debugPrint('❌ Invalid save data in slot $slotIndex');
        return false;
      }

      // 🔧 FIX: Load career data without resetting calendar
      await _loadCareerFromSaveData(saveData);

      // 🔧 FIX: Explicitly load calendar state if it exists
      if (saveData.containsKey('calendarState')) {
        debugPrint("🔧 Loading calendar state from slot $slotIndex...");
        await _loadCalendarState(saveData['calendarState']);

        // 🔧 FIX: Verify calendar was loaded correctly
        int completedRaces = CareerCalendar.instance.getCompletedRaces().length;
        debugPrint("✅ Calendar loaded: $completedRaces races completed");
        debugPrint(
            "   Next race: ${CareerCalendar.instance.nextRaceWeekend?.name ?? 'Season Complete'}");
      }

      debugPrint('✅ Career loaded successfully from slot $slotIndex');
      return true;
    } catch (e) {
      debugPrint('❌ Error loading career from slot $slotIndex: $e');
      return false;
    }
  }

  /// Delete career from specific slot
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
        // Get deleted career info
        Map<String, dynamic>? slotData = slotsData[slotIndex];
        String? deletedCareerID;

        if (slotData != null && slotData.isNotEmpty) {
          try {
            deletedCareerID = slotData['careerDriver']?['careerId'];
          } catch (e) {
            debugPrint('Could not get career info from deleted slot');
          }
        }

        // Delete from slot
        slotsData[slotIndex] = {};

        String updatedJsonString = jsonEncode(slotsData);
        await prefs.setString(_careerSlotsKey, updatedJsonString);

        debugPrint("✅ Deleted career from slot $slotIndex");

        // 🔧 FIX: Clear both championship and calendar when deleting ANY career
        debugPrint(
            "🔧 Clearing championship and calendar data after career deletion");
        ChampionshipManager.resetChampionship();
        CareerCalendar.instance.forceReset();

        // If deleted career is currently loaded, reset career manager
        if (CareerManager.currentCareerDriver != null &&
            deletedCareerID != null &&
            CareerManager.currentCareerDriver!.careerId == deletedCareerID) {
          debugPrint("🔧 Resetting career manager (deleted current career)");
          CareerManager.resetCareer();
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting career from slot: $e');
      return false;
    }
  }

  /// Auto-save after important events
  static Future<void> autoSave() async {
    if (CareerManager.currentCareerDriver != null) {
      await saveCurrentCareer();
      debugPrint('💾 Career auto-saved');
    }
  }

  /// Clear all save data
  static Future<void> clearAllSaveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_careerSlotsKey);
      CareerManager.resetCareer();
      debugPrint("🗑️ All save data cleared");
    } catch (e) {
      debugPrint('❌ Error clearing save data: $e');
    }
  }

  /// Initialize save system (no migration needed)
  static Future<void> initializeSaveSystem() async {
    try {
      // Initialize slots
      List<SaveSlot> slots = await getAllSaveSlots();
      debugPrint(
          "✅ Save system initialized - ${slots.where((s) => !s.isEmpty).length} saves found");

      // Auto-load most recent career if none is loaded
      await autoLoadMostRecentCareer();
    } catch (e) {
      debugPrint('❌ Error initializing save system: $e');
    }
  }

  // Private helper methods (unchanged)
  static bool _isValidSaveData(Map<String, dynamic> saveData) {
    return saveData.containsKey('version') &&
        saveData.containsKey('currentSeason') &&
        saveData.containsKey('careerDriver') &&
        saveData['careerDriver'] is Map &&
        saveData['careerDriver']['name'] != null;
  }

  static Future<void> _loadCareerFromSaveData(
      Map<String, dynamic> saveData) async {
    try {
      int currentSeason = saveData['currentSeason'];
      Map<String, dynamic> driverData = saveData['careerDriver'];

      String teamName = driverData['teamName'];
      var team = TeamData.getTeamByName(teamName);

      CareerDriver careerDriver = CareerDriver.fromJson(driverData, team);

      // 🔧 FIX: Reset career but DON'T reset calendar yet
      CareerManager.resetCareerButKeepCalendar();
      CareerManager.loadCareerDriver(careerDriver, currentSeason);

      // 🔧 FIX: Load calendar state BEFORE initializing anything else
      if (saveData.containsKey('calendarState')) {
        await _loadCalendarState(saveData['calendarState']);
        debugPrint("✅ Calendar state loaded from save data");
      }

      // Now load championship standings
      CareerManager.loadCareerWithChampionshipFix(saveData);

      debugPrint(
          "✅ Career driver data loaded successfully (Career ID: ${careerDriver.careerId})");
      debugPrint(
          "✅ Championship standings loaded and synchronized with current season drivers");
    } catch (e) {
      debugPrint("❌ Error loading career from save data: $e");
      rethrow;
    }
  }

  static Future<void> _loadCalendarState(
      Map<String, dynamic> calendarData) async {
    try {
      // 🔧 FIX: Initialize calendar first, then load state
      CareerCalendar.instance.initialize();

      if (calendarData.containsKey('currentDate')) {
        String currentDateStr = calendarData['currentDate'];
        CareerCalendar.instance.setCurrentDate(DateTime.parse(currentDateStr));
      }

      if (calendarData.containsKey('currentRaceIndex')) {
        int currentRaceIndex = calendarData['currentRaceIndex'] ?? 0;
        CareerCalendar.instance.setCurrentRaceIndex(currentRaceIndex);
      }

      if (calendarData.containsKey('raceWeekends')) {
        List<dynamic> raceWeekendData = calendarData['raceWeekends'];

        for (Map<String, dynamic> raceData in raceWeekendData) {
          String raceName = raceData['name'];
          bool isCompleted = raceData['isCompleted'] ?? false;
          bool hasQualifyingResults = raceData['hasQualifyingResults'] ?? false;
          bool hasRaceResults = raceData['hasRaceResults'] ?? false;

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
      debugPrint(
          "   Next race: ${CareerCalendar.instance.nextRaceWeekend?.name ?? 'None'}");
    } catch (e) {
      debugPrint("❌ Error loading calendar state: $e");
      // Fallback: initialize fresh calendar
      CareerCalendar.instance.initialize();
    }
  }
}
