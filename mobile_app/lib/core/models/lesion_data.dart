import 'dart:convert';
import 'package:flutter/services.dart';

/// Represents a lesion type with sanitized key for comparison and original values for storage/display
class LesionTypeEnum {
  final String key; // Sanitized key for comparison (e.g., "CANCER", "NO_LESION")
  final String displayName; // What user sees in dropdown (e.g., "Cancer", "No Lesion")
  final String storageValue; // What gets stored in database (e.g., "CANCER", "NO_LESION")

  const LesionTypeEnum({
    required this.key,
    required this.displayName,
    required this.storageValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LesionTypeEnum &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => displayName;
}

/// Represents a clinical diagnosis with sanitized key for comparison and original text for storage/display
class ClinicalDiagnosisEnum {
  final String key; // Sanitized key for comparison (e.g., "MELANOMA", "ORAL_CANCER")
  final String displayText; // Original text shown to user (e.g., "MELANOMA", "ORAL CANCER")
  final String storageValue; // Original text stored in database (same as displayText)

  const ClinicalDiagnosisEnum({
    required this.key,
    required this.displayText,
    required this.storageValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClinicalDiagnosisEnum &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => displayText;
}

/// Represents a single entry from the JSON file (one lesion type with its clinical diagnoses)
class LesionTypeEntry {
  final LesionTypeEnum lesionType;
  final List<ClinicalDiagnosisEnum> clinicalDiagnoses;

  const LesionTypeEntry({
    required this.lesionType,
    required this.clinicalDiagnoses,
  });
}

/// Singleton manager to load and manage lesion type and clinical diagnosis data
class LesionDataManager {
  static final LesionDataManager _instance = LesionDataManager._internal();
  factory LesionDataManager() => _instance;
  LesionDataManager._internal();

  final List<LesionTypeEntry> _entries = [];
  final Map<String, LesionTypeEnum> _lesionTypeByKey = {};
  final Map<String, LesionTypeEnum> _lesionTypeByStorageValue = {};
  final Map<String, ClinicalDiagnosisEnum> _clinicalDiagnosisByKey = {};
  final Map<String, ClinicalDiagnosisEnum> _clinicalDiagnosisByStorageValue = {};
  bool _isLoaded = false;

  /// Sanitizes a string to be used as an enum key (replace spaces and special chars with underscores)
  String _sanitize(String text) {
    // Replace all non-alphanumeric characters with underscores
    return text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '_');
  }

  /// Load data from JSON file
  Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      // Load JSON file
      final String jsonString =
          await rootBundle.loadString('assets/data/lesion_types.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      // Track if NULL exists
      bool hasNullLesionType = false;
      bool hasNullClinicalDiagnosis = false;

      // Parse each entry
      for (final item in jsonList) {
        final String enumValue = item['enum'] as String;
        final String lesionTypeName = item['lesion_type'] as String;
        final List<dynamic> diagnosesJson = item['clinical_diagnoses'] as List<dynamic>;

        // Create lesion type enum
        final lesionType = LesionTypeEnum(
          key: enumValue, // Already sanitized in JSON
          displayName: lesionTypeName,
          storageValue: enumValue,
        );

        // Check if this is NULL
        if (enumValue == 'NULL') {
          hasNullLesionType = true;
        }

        // Store in maps
        if (_lesionTypeByKey.containsKey(lesionType.key)) {
          throw Exception(
              'Duplicate lesion type key: ${lesionType.key}. Check JSON file.');
        }
        _lesionTypeByKey[lesionType.key] = lesionType;
        _lesionTypeByStorageValue[lesionType.storageValue] = lesionType;

        // Create clinical diagnosis enums
        final List<ClinicalDiagnosisEnum> diagnoses = [];
        for (final diagnosisText in diagnosesJson) {
          final String diagnosisStr = diagnosisText as String;
          final sanitizedKey = _sanitize(diagnosisStr);

          final diagnosis = ClinicalDiagnosisEnum(
            key: sanitizedKey,
            displayText: diagnosisStr,
            storageValue: diagnosisStr,
          );

          // Check if this is NULL
          if (diagnosisStr == 'NULL') {
            hasNullClinicalDiagnosis = true;
          }

          // Store in maps (only if not already present - allows same diagnosis in multiple lesion types)
          if (!_clinicalDiagnosisByKey.containsKey(diagnosis.key)) {
            _clinicalDiagnosisByKey[diagnosis.key] = diagnosis;
            _clinicalDiagnosisByStorageValue[diagnosis.storageValue] = diagnosis;
          } else {
            // Verify it's the same diagnosis text (no collisions)
            final existing = _clinicalDiagnosisByKey[diagnosis.key]!;
            if (existing.storageValue != diagnosis.storageValue) {
              throw Exception(
                  'Collision detected: Different diagnoses "${existing.storageValue}" and "${diagnosis.storageValue}" '
                  'produce the same sanitized key "$sanitizedKey".');
            }
          }

          diagnoses.add(_clinicalDiagnosisByKey[diagnosis.key]!);
        }

        // Create entry
        _entries.add(LesionTypeEntry(
          lesionType: lesionType,
          clinicalDiagnoses: diagnoses,
        ));
      }

      // Ensure NULL exists - create default if missing
      if (!hasNullLesionType) {
        print('Warning: NULL lesion type missing from JSON. Creating default.');
        final nullLesionType = LesionTypeEnum(
          key: 'NULL',
          displayName: 'Not Specified',
          storageValue: 'NULL',
        );
        _lesionTypeByKey['NULL'] = nullLesionType;
        _lesionTypeByStorageValue['NULL'] = nullLesionType;
      }

      if (!hasNullClinicalDiagnosis) {
        print('Warning: NULL clinical diagnosis missing from JSON. Creating default.');
        final nullDiagnosis = ClinicalDiagnosisEnum(
          key: 'NULL',
          displayText: 'NULL',
          storageValue: 'NULL',
        );
        _clinicalDiagnosisByKey['NULL'] = nullDiagnosis;
        _clinicalDiagnosisByStorageValue['NULL'] = nullDiagnosis;

        // If NULL lesion type exists but doesn't have NULL diagnosis, add it
        final nullLesionType = _lesionTypeByKey['NULL'];
        if (nullLesionType != null) {
          final nullEntry = _entries.firstWhere(
            (e) => e.lesionType.key == 'NULL',
            orElse: () {
              // Create new NULL entry
              final newEntry = LesionTypeEntry(
                lesionType: nullLesionType,
                clinicalDiagnoses: [nullDiagnosis],
              );
              _entries.add(newEntry);
              return newEntry;
            },
          );

          // Add NULL diagnosis if not present
          if (!nullEntry.clinicalDiagnoses.contains(nullDiagnosis)) {
            nullEntry.clinicalDiagnoses.add(nullDiagnosis);
          }
        }
      }

      _isLoaded = true;
      print('Loaded ${_lesionTypeByKey.length} lesion types and '
          '${_clinicalDiagnosisByKey.length} clinical diagnoses.');
    } catch (e) {
      print('Error loading lesion data: $e');
      rethrow;
    }
  }

  /// Get all lesion types
  List<LesionTypeEnum> get allLesionTypes {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    return _entries.map((e) => e.lesionType).toList();
  }

  /// Get all clinical diagnoses (across all lesion types)
  List<ClinicalDiagnosisEnum> get allClinicalDiagnoses {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    return _clinicalDiagnosisByKey.values.toList();
  }

  /// Get clinical diagnoses for a specific lesion type
  List<ClinicalDiagnosisEnum> getClinicalDiagnosesForLesionType(
      LesionTypeEnum lesionType) {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    final entry = _entries.firstWhere(
      (e) => e.lesionType.key == lesionType.key,
      orElse: () => throw Exception('Lesion type not found: ${lesionType.key}'),
    );
    return entry.clinicalDiagnoses;
  }

  /// Find which lesion type contains a specific clinical diagnosis
  LesionTypeEnum? findLesionTypeForDiagnosis(ClinicalDiagnosisEnum diagnosis) {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    for (final entry in _entries) {
      if (entry.clinicalDiagnoses.any((d) => d.key == diagnosis.key)) {
        return entry.lesionType;
      }
    }
    return null;
  }

  /// Check if a clinical diagnosis belongs to a lesion type
  bool diagnosisBelongsToLesionType(
      ClinicalDiagnosisEnum diagnosis, LesionTypeEnum lesionType) {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    final entry = _entries.firstWhere(
      (e) => e.lesionType.key == lesionType.key,
      orElse: () => throw Exception('Lesion type not found: ${lesionType.key}'),
    );
    return entry.clinicalDiagnoses.any((d) => d.key == diagnosis.key);
  }

  /// Get lesion type by storage value (for database retrieval)
  LesionTypeEnum getLesionTypeByStorageValue(String value) {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    return _lesionTypeByStorageValue[value] ?? _lesionTypeByKey['NULL']!;
  }

  /// Get clinical diagnosis by storage value (for database retrieval)
  ClinicalDiagnosisEnum getClinicalDiagnosisByStorageValue(String value) {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    return _clinicalDiagnosisByStorageValue[value] ?? _clinicalDiagnosisByKey['NULL']!;
  }

  /// Get NULL lesion type
  LesionTypeEnum get nullLesionType {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    return _lesionTypeByKey['NULL']!;
  }

  /// Get NULL clinical diagnosis
  ClinicalDiagnosisEnum get nullClinicalDiagnosis {
    if (!_isLoaded) {
      throw Exception('Data not loaded. Call loadData() first.');
    }
    return _clinicalDiagnosisByKey['NULL']!;
  }
}
