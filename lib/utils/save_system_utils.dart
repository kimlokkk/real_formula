// lib/utils/save_system_utils.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/career/save_manager.dart';
import '../services/career/career_manager.dart';

class SaveSystemUtils {
  /// Get save system statistics and information
  static Future<Map<String, dynamic>> getSaveSystemInfo() async {
    try {
      List<SaveSlot> slots = await SaveManager.getAllSaveSlots();

      int totalSaves = slots.where((slot) => !slot.isEmpty).length;
      int emptySaves = slots.where((slot) => slot.isEmpty).length;

      SaveSlot? mostRecentSave;
      SaveSlot? oldestSave;

      List<SaveSlot> nonEmptySlots = slots.where((slot) => !slot.isEmpty).toList();
      if (nonEmptySlots.isNotEmpty) {
        nonEmptySlots.sort((a, b) => b.lastSaved.compareTo(a.lastSaved));
        mostRecentSave = nonEmptySlots.first;
        oldestSave = nonEmptySlots.last;
      }

      return {
        'totalSlots': SaveManager.maxCareerSlots,
        'usedSlots': totalSaves,
        'emptySlots': emptySaves,
        'hasCurrentCareer': CareerManager.currentCareerDriver != null,
        'mostRecentSave': mostRecentSave != null
            ? {
                'slotIndex': mostRecentSave.slotIndex,
                'saveName': mostRecentSave.saveName,
                'driverName': mostRecentSave.driverName,
                'lastSaved': mostRecentSave.lastSaved.toIso8601String(),
              }
            : null,
        'oldestSave': oldestSave != null
            ? {
                'slotIndex': oldestSave.slotIndex,
                'saveName': oldestSave.saveName,
                'driverName': oldestSave.driverName,
                'lastSaved': oldestSave.lastSaved.toIso8601String(),
              }
            : null,
      };
    } catch (e) {
      debugPrint('Error getting save system info: $e');
      return {
        'error': e.toString(),
        'totalSlots': SaveManager.maxCareerSlots,
        'usedSlots': 0,
        'emptySlots': SaveManager.maxCareerSlots,
        'hasCurrentCareer': false,
      };
    }
  }

  /// Create a backup of all save data
  static Future<String?> createFullBackup() async {
    try {
      List<SaveSlot> slots = await SaveManager.getAllSaveSlots();
      Map<String, dynamic>? currentCareer = await SaveManager.getCareerSaveInfo();

      Map<String, dynamic> fullBackup = {
        'backupVersion': '1.0',
        'createdAt': DateTime.now().toIso8601String(),
        'appVersion': '1.0', // Could be dynamic
        'currentCareer': currentCareer,
        'saveSlots': [],
      };

      // Export each save slot
      for (int i = 0; i < slots.length; i++) {
        if (!slots[i].isEmpty) {
          String? slotData = await _exportSlotData(i);
          if (slotData != null) {
            fullBackup['saveSlots'].add({
              'slotIndex': i,
              'data': jsonDecode(slotData),
            });
          }
        }
      }

      String backupJson = jsonEncode(fullBackup);
      debugPrint('✅ Full backup created successfully');
      return backupJson;
    } catch (e) {
      debugPrint('❌ Error creating full backup: $e');
      return null;
    }
  }

  /// Restore from a full backup
  static Future<bool> restoreFromBackup(String backupJson) async {
    try {
      Map<String, dynamic> backup = jsonDecode(backupJson);

      // Validate backup structure
      if (!_isValidBackup(backup)) {
        debugPrint('❌ Invalid backup format');
        return false;
      }

      // Clear existing saves (with confirmation in UI)
      await SaveManager.clearAllSaveData();

      // Restore save slots
      if (backup.containsKey('saveSlots')) {
        List<dynamic> saveSlots = backup['saveSlots'];

        for (Map<String, dynamic> slotInfo in saveSlots) {
          int slotIndex = slotInfo['slotIndex'];
          Map<String, dynamic> slotData = slotInfo['data'];

          // Import the slot data
          String slotJson = jsonEncode(slotData);
          await SaveManager.importCareerData(slotJson);

          // Save to the correct slot
          if (slotData.containsKey('slotName')) {
            await SaveManager.saveCareerToSlot(slotIndex, slotData['slotName']);
          }
        }
      }

      debugPrint('✅ Backup restored successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error restoring backup: $e');
      return false;
    }
  }

  /// Share save file (for external backup/sharing)
  static Future<bool> shareSaveFile(int slotIndex) async {
    try {
      String? saveData = await _exportSlotData(slotIndex);
      if (saveData == null) return false;

      SaveSlot slot = (await SaveManager.getAllSaveSlots())[slotIndex];
      if (slot.isEmpty) return false;

      // Create temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/${slot.saveName}_${slot.driverName}.f1save');
      await file.writeAsString(saveData);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'F1 Career Save: ${slot.saveName}',
        subject: 'F1 Career Simulator Save File',
      );

      debugPrint('✅ Save file shared successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error sharing save file: $e');
      return false;
    }
  }

  /// Validate save file integrity
  static Future<Map<String, dynamic>> validateSaveFile(String jsonData) async {
    try {
      Map<String, dynamic> saveData = jsonDecode(jsonData);

      List<String> issues = [];
      List<String> warnings = [];

      // Check required fields
      if (!saveData.containsKey('version')) {
        issues.add('Missing version information');
      }

      if (!saveData.containsKey('careerDriver')) {
        issues.add('Missing career driver data');
      } else {
        Map<String, dynamic> driverData = saveData['careerDriver'];
        if (!driverData.containsKey('name') || driverData['name'] == null) {
          issues.add('Missing driver name');
        }
        if (!driverData.containsKey('teamName') || driverData['teamName'] == null) {
          issues.add('Missing team information');
        }
      }

      if (!saveData.containsKey('currentSeason')) {
        warnings.add('Missing season information');
      }

      if (!saveData.containsKey('calendarState')) {
        warnings.add('Missing calendar state - race progress may be lost');
      }

      // Check version compatibility
      String? version = saveData['version'];
      if (version != null) {
        List<String> versionParts = version.split('.');
        if (versionParts.isNotEmpty) {
          int majorVersion = int.tryParse(versionParts[0]) ?? 0;
          if (majorVersion > 1) {
            warnings.add('Save file from newer version - may have compatibility issues');
          }
        }
      }

      return {
        'isValid': issues.isEmpty,
        'hasWarnings': warnings.isNotEmpty,
        'issues': issues,
        'warnings': warnings,
        'driverName': saveData['careerDriver']?['name'] ?? 'Unknown',
        'teamName': saveData['careerDriver']?['teamName'] ?? 'Unknown',
        'season': saveData['currentSeason'] ?? 'Unknown',
        'savedAt': saveData['savedAt'] ?? 'Unknown',
      };
    } catch (e) {
      return {
        'isValid': false,
        'hasWarnings': false,
        'issues': ['Invalid JSON format: ${e.toString()}'],
        'warnings': [],
      };
    }
  }

  /// Get save file size and storage info
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      List<SaveSlot> slots = await SaveManager.getAllSaveSlots();

      int totalSaveCount = 0;
      double totalSizeKB = 0;

      for (int i = 0; i < slots.length; i++) {
        if (!slots[i].isEmpty) {
          totalSaveCount++;
          String? slotData = await _exportSlotData(i);
          if (slotData != null) {
            totalSizeKB += slotData.length / 1024;
          }
        }
      }

      // Get current career size
      Map<String, dynamic> saveInfo = await SaveManager.getSaveInfo();
      double currentCareerSizeKB = (saveInfo['size'] ?? 0) / 1024;

      return {
        'totalSaves': totalSaveCount,
        'totalSizeKB': totalSizeKB,
        'currentCareerSizeKB': currentCareerSizeKB,
        'averageSizeKB': totalSaveCount > 0 ? totalSizeKB / totalSaveCount : 0,
        'formattedTotalSize': _formatFileSize(totalSizeKB * 1024),
        'formattedCurrentSize': _formatFileSize(currentCareerSizeKB * 1024),
      };
    } catch (e) {
      debugPrint('Error getting storage info: $e');
      return {
        'error': e.toString(),
        'totalSaves': 0,
        'totalSizeKB': 0,
        'currentCareerSizeKB': 0,
      };
    }
  }

  /// Clean up old or corrupted saves
  static Future<Map<String, dynamic>> cleanupSaves() async {
    try {
      List<SaveSlot> slots = await SaveManager.getAllSaveSlots();

      int corruptedCount = 0;
      int cleanedCount = 0;
      List<String> cleanupLog = [];

      for (int i = 0; i < slots.length; i++) {
        SaveSlot slot = slots[i];
        if (!slot.isEmpty) {
          // Try to export slot data to validate it
          String? slotData = await _exportSlotData(i);
          if (slotData != null) {
            Map<String, dynamic> validation = await validateSaveFile(slotData);
            if (!validation['isValid']) {
              // Mark as corrupted and optionally remove
              corruptedCount++;
              cleanupLog.add('Slot ${i + 1}: ${validation['issues'].join(', ')}');

              // Uncomment to auto-remove corrupted saves:
              // await SaveManager.deleteCareerFromSlot(i);
              // cleanedCount++;
            }
          } else {
            corruptedCount++;
            cleanupLog.add('Slot ${i + 1}: Unable to export data');
          }
        }
      }

      return {
        'corruptedSaves': corruptedCount,
        'cleanedSaves': cleanedCount,
        'cleanupLog': cleanupLog,
        'recommendCleanup': corruptedCount > 0,
      };
    } catch (e) {
      debugPrint('Error during cleanup: $e');
      return {
        'error': e.toString(),
        'corruptedSaves': 0,
        'cleanedSaves': 0,
      };
    }
  }

  /// Debug: Print all save information
  static Future<void> debugPrintSaveInfo() async {
    if (!kDebugMode) return;

    try {
      debugPrint('\n=== SAVE SYSTEM DEBUG INFO ===');

      Map<String, dynamic> systemInfo = await getSaveSystemInfo();
      debugPrint('System Info: $systemInfo');

      Map<String, dynamic> storageInfo = await getStorageInfo();
      debugPrint('Storage Info: $storageInfo');

      List<SaveSlot> slots = await SaveManager.getAllSaveSlots();
      debugPrint('\nSave Slots:');
      for (int i = 0; i < slots.length; i++) {
        SaveSlot slot = slots[i];
        if (!slot.isEmpty) {
          debugPrint('  Slot ${i + 1}: ${slot.saveName} | ${slot.driverName} | ${slot.progressText}');
        } else {
          debugPrint('  Slot ${i + 1}: Empty');
        }
      }

      debugPrint('=== END SAVE DEBUG INFO ===\n');
    } catch (e) {
      debugPrint('Error in debug print: $e');
    }
  }

  // Private helper methods

  static Future<String?> _exportSlotData(int slotIndex) async {
    try {
      // Load the slot temporarily and export
      bool loaded = await SaveManager.loadCareerFromSlot(slotIndex);
      if (loaded) {
        return await SaveManager.exportCareerData();
      }
      return null;
    } catch (e) {
      debugPrint('Error exporting slot $slotIndex: $e');
      return null;
    }
  }

  static bool _isValidBackup(Map<String, dynamic> backup) {
    return backup.containsKey('backupVersion') && backup.containsKey('createdAt') && backup.containsKey('saveSlots');
  }

  static String _formatFileSize(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Extension methods for SaveSlot convenience
extension SaveSlotExtensions on SaveSlot {
  /// Get a user-friendly description of the save
  String get description {
    if (isEmpty) return 'Empty save slot';

    String desc = '$driverName driving for $teamName';
    if (careerWins > 0) {
      desc += ' • ${careerWins} win${careerWins == 1 ? '' : 's'}';
    }
    if (careerPoints > 0) {
      desc += ' • ${careerPoints} points';
    }
    desc += ' • $progressText';
    return desc;
  }

  /// Check if this save is recent (within last 24 hours)
  bool get isRecent {
    if (isEmpty) return false;
    return DateTime.now().difference(lastSaved).inHours < 24;
  }

  /// Get relative time string
  String get relativeTimeString {
    if (isEmpty) return '';

    final now = DateTime.now();
    final difference = now.difference(lastSaved);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).round()}w ago';
    return '${(difference.inDays / 30).round()}mo ago';
  }
}
