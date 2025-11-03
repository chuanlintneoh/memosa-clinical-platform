import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/utils/crypto.dart';
import 'package:mobile_app/core/models/lesion_data.dart';

enum IdType { NRIC, PPN }

enum Gender { MALE, FEMALE }

enum Ethnicity {
  MALAY,
  CHINESE,
  INDIAN,
  IBAN,
  BIDAYUH,
  MELANAU,
  KADAZAN_DUSUN,
  BAJAU,
  OTHERS,
}

enum Habit { YES, OCCASIONALLY, NO }

extension HabitMapper on Habit {
  static Habit fromString(String? value) {
    switch (value) {
      case "YES":
        return Habit.YES;
      case "OCCASIONALLY":
        return Habit.OCCASIONALLY;
      case "NO":
        return Habit.NO;
      default:
        return Habit.NO;
    }
  }

  String get toShortString {
    return toString().split('.').last;
  }
}

enum DurationUnit { WEEKS, MONTHS, YEARS }

enum BiopsyAgreeWithCOE { NULL, YES, NO } // not stored in database

enum PoorQualityReason {
  AREA_OF_INTEREST_NOT_IN_FRAME,
  ARTEFACT,
  BLURRY,
  DARK,
  EXTRAORAL,
  OUT_OF_FOCUS,
  OVEREXPOSED,
}

class PublicCaseModel {
  final DateTime createdAt;
  final String createdBy;
  final Habit alcohol;
  final String alcoholDuration;
  final Habit betelQuid;
  final String betelQuidDuration;
  final Habit smoking;
  final String smokingDuration;
  final bool oralHygieneProductsUsed;
  final String oralHygieneProductTypeUsed;
  final bool slsContainingToothpaste;
  final String slsContainingToothpasteUsed;
  final String additionalComments;

  PublicCaseModel({
    required this.createdAt,
    required this.createdBy,
    required this.alcohol,
    required this.alcoholDuration,
    required this.betelQuid,
    required this.betelQuidDuration,
    required this.smoking,
    required this.smokingDuration,
    this.oralHygieneProductsUsed = false,
    this.oralHygieneProductTypeUsed = "NULL",
    this.slsContainingToothpaste = false,
    this.slsContainingToothpasteUsed = "NULL",
    this.additionalComments = "NULL",
  });
}

class PrivateCaseModel {
  final String address;
  final String age;
  final String attendingHospital;
  final String chiefComplaint;
  final Map<String, dynamic> consentForm;
  final DateTime dob;
  final String ethnicity;
  final Gender gender;
  final String idNum;
  final IdType idType;
  final String lesionClinicalPresentation;
  final String medicalHistory;
  final String medicationHistory;
  final String name;
  final String phoneNum;
  final String presentingComplaintHistory;
  final List<Uint8List> images;

  PrivateCaseModel({
    required this.address,
    required this.age,
    required this.attendingHospital,
    required this.chiefComplaint,
    required this.consentForm,
    required this.dob,
    required this.ethnicity,
    required this.gender,
    required this.idNum,
    required this.idType,
    required this.lesionClinicalPresentation,
    required this.medicalHistory,
    required this.medicationHistory,
    required this.name,
    required this.phoneNum,
    required this.presentingComplaintHistory,
    required this.images,
  }) : assert(images.length == 9, 'Exactly 9 images are required.');

  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "age": age,
      "attending_hospital": attendingHospital,
      "chief_complaint": chiefComplaint,
      "consent_form": consentForm,
      "dob": dob.toIso8601String(),
      "ethnicity": ethnicity,
      "gender": gender.name,
      "idnum": idNum,
      "idtype": idType.name,
      "lesion_clinical_presentation": lesionClinicalPresentation,
      "medical_history": medicalHistory,
      "medication_history": medicationHistory,
      "name": name,
      "phonenum": phoneNum,
      "presenting_complaint_history": presentingComplaintHistory,
      "images": images.map((imgBytes) => base64Encode(imgBytes)).toList(),
    };
  }
}

class Diagnosis {
  final LesionTypeEnum aiLesionType;
  final ClinicalDiagnosisEnum biopsyClinicalDiagnosis;
  final LesionTypeEnum biopsyLesionType;
  final Map<String, dynamic> biopsyReport;
  final ClinicalDiagnosisEnum coeClinicalDiagnosis;
  final LesionTypeEnum coeLesionType;
  BiopsyAgreeWithCOE biopsyAgreeWithCoe = BiopsyAgreeWithCOE.NULL;

  Diagnosis({
    required this.aiLesionType,
    required this.biopsyClinicalDiagnosis,
    required this.biopsyLesionType,
    required this.biopsyReport,
    required this.coeClinicalDiagnosis,
    required this.coeLesionType,
  }) {
    // Compare using sanitized keys - NULL key is always "NULL"
    const nullLesionKey = 'NULL';
    const nullDiagnosisKey = 'NULL';

    if (biopsyLesionType.key != nullLesionKey &&
        coeLesionType.key != nullLesionKey) {
      biopsyAgreeWithCoe = (biopsyLesionType.key == coeLesionType.key)
          ? BiopsyAgreeWithCOE.YES
          : BiopsyAgreeWithCOE.NO;
      if (biopsyClinicalDiagnosis.key != nullDiagnosisKey &&
          coeClinicalDiagnosis.key != nullDiagnosisKey) {
        biopsyAgreeWithCoe =
            (biopsyLesionType.key == coeLesionType.key &&
                biopsyClinicalDiagnosis.key == coeClinicalDiagnosis.key)
            ? BiopsyAgreeWithCOE.YES
            : BiopsyAgreeWithCOE.NO;
      }
    }
  }

  factory Diagnosis.empty() {
    final manager = LesionDataManager();
    return Diagnosis(
      aiLesionType: manager.nullLesionType,
      biopsyClinicalDiagnosis: manager.nullClinicalDiagnosis,
      biopsyLesionType: manager.nullLesionType,
      biopsyReport: {"url": "NULL", "iv": "NULL", "fileType": "NULL"},
      coeClinicalDiagnosis: manager.nullClinicalDiagnosis,
      coeLesionType: manager.nullLesionType,
    );
  }

  factory Diagnosis.fromRaw(Map<String, dynamic> rawDiagnosis) {
    final manager = LesionDataManager();
    return Diagnosis(
      aiLesionType: manager.getLesionTypeByStorageValue(
        rawDiagnosis["ai_lesion_type"] ?? "NULL",
      ),
      biopsyClinicalDiagnosis: manager.getClinicalDiagnosisByStorageValue(
        rawDiagnosis["biopsy_clinical_diagnosis"] ?? "NULL",
      ),
      biopsyLesionType: manager.getLesionTypeByStorageValue(
        rawDiagnosis["biopsy_lesion_type"] ?? "NULL",
      ),
      biopsyReport:
          rawDiagnosis["biopsy_report"] ??
          {"url": "NULL", "iv": "NULL", "fileType": "NULL"},
      coeClinicalDiagnosis: manager.getClinicalDiagnosisByStorageValue(
        rawDiagnosis["coe_clinical_diagnosis"] ?? "NULL",
      ),
      coeLesionType: manager.getLesionTypeByStorageValue(
        rawDiagnosis["coe_lesion_type"] ?? "NULL",
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "ai_lesion_type": aiLesionType.storageValue,
      "biopsy_clinical_diagnosis": biopsyClinicalDiagnosis.storageValue,
      "biopsy_lesion_type": biopsyLesionType.storageValue,
      "biopsy_report": biopsyReport,
      "coe_clinical_diagnosis": coeClinicalDiagnosis.storageValue,
      "coe_lesion_type": coeLesionType.storageValue,
    };
  }

  Map<String, dynamic> toEditJson() {
    // disable editing of ai_lesion_type
    return {
      "biopsy_clinical_diagnosis": biopsyClinicalDiagnosis.storageValue,
      "biopsy_lesion_type": biopsyLesionType.storageValue,
      "biopsy_report": biopsyReport,
      "coe_clinical_diagnosis": coeClinicalDiagnosis.storageValue,
      "coe_lesion_type": coeLesionType.storageValue,
    };
  }
}

class ClinicianDiagnosis {
  final String clinicianID;
  final ClinicalDiagnosisEnum clinicalDiagnosis;
  final LesionTypeEnum lesionType;
  final bool lowQuality;
  final PoorQualityReason? lowQualityReason;

  ClinicianDiagnosis({
    required this.clinicianID,
    required this.clinicalDiagnosis,
    required this.lesionType,
    required this.lowQuality,
    this.lowQualityReason,
  });

  Map<String, dynamic> toJson() {
    String formatReason(PoorQualityReason reason) {
      return reason.name
          .replaceAll('_', ' ')
          .toLowerCase()
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }

    return {
      clinicianID: {
        "clinical_diagnosis": clinicalDiagnosis.storageValue,
        "lesion_type": lesionType.storageValue,
        "low_quality": lowQuality,
        "low_quality_reason": lowQuality && lowQualityReason != null
            ? formatReason(lowQualityReason!)
            : "NULL",
      },
    };
  }
}

class CaseCreateModel {
  // For case creation
  final PublicCaseModel publicData;
  final Map<String, String> encryptedAes;
  final Map<String, String> encryptedBlob;
  final Map<String, String> encryptedComments;

  CaseCreateModel({
    required this.publicData,
    required this.encryptedAes,
    required this.encryptedBlob,
    required this.encryptedComments,
  });

  Map<String, dynamic> toJson() {
    return {
      "created_at": publicData.createdAt.toIso8601String(),
      "created_by": publicData.createdBy,
      // "submitted_at": "",
      "alcohol": publicData.alcohol.name,
      "alcohol_duration": publicData.alcoholDuration,
      "betel_quid": publicData.betelQuid.name,
      "betel_quid_duration": publicData.betelQuidDuration,
      "smoking": publicData.smoking.name,
      "smoking_duration": publicData.smokingDuration,
      "oral_hygiene_products_used": publicData.oralHygieneProductsUsed,
      "oral_hygiene_product_type_used": publicData.oralHygieneProductTypeUsed,
      "sls_containing_toothpaste": publicData.slsContainingToothpaste,
      "sls_containing_toothpaste_used": publicData.slsContainingToothpasteUsed,
      "encrypted_aes": encryptedAes,
      "encrypted_blob": encryptedBlob,
      "additional_comments": encryptedComments,
      "diagnoses": List.generate(9, (_) => Diagnosis.empty().toJson()),
    };
  }
}

class CaseRetrieveModel {
  // for case retrieval
  final String createdAt;
  final String createdBy;
  final String submittedAt;
  final Habit alcohol;
  final String alcoholDuration;
  final Habit betelQuid;
  final String betelQuidDuration;
  final Habit smoking;
  final String smokingDuration;
  final bool oralHygieneProductsUsed;
  final String oralHygieneProductTypeUsed;
  final bool slsContainingToothpaste;
  final String slsContainingToothpasteUsed;
  final List<Diagnosis> diagnoses;
  final String address;
  final String age;
  final String attendingHospital;
  final String chiefComplaint;
  final Map<String, dynamic> consentForm;
  final String dob;
  final String ethnicity;
  final String gender;
  final String idnum;
  final String idtype;
  final String lesionClinicalPresentation;
  final String medicalHistory;
  final String medicationHistory;
  final String name;
  final String phonenum;
  final String presentingComplaintHistory;
  final List<Uint8List> images;
  final String additionalComments;

  CaseRetrieveModel({
    required this.createdAt,
    required this.createdBy,
    required this.submittedAt,
    required this.alcohol,
    required this.alcoholDuration,
    required this.betelQuid,
    required this.betelQuidDuration,
    required this.smoking,
    required this.smokingDuration,
    required this.oralHygieneProductsUsed,
    required this.oralHygieneProductTypeUsed,
    required this.slsContainingToothpaste,
    required this.slsContainingToothpasteUsed,
    required this.diagnoses,
    required this.address,
    required this.age,
    required this.attendingHospital,
    required this.chiefComplaint,
    required this.consentForm,
    required this.dob,
    required this.ethnicity,
    required this.gender,
    required this.idnum,
    required this.idtype,
    required this.lesionClinicalPresentation,
    required this.medicalHistory,
    required this.medicationHistory,
    required this.name,
    required this.phonenum,
    required this.presentingComplaintHistory,
    required this.images,
    required this.additionalComments,
  });

  factory CaseRetrieveModel.fromRaw({
    required Map<String, dynamic> rawCase,
    required String blob,
    required String comments,
  }) {
    final decryptedData = blob.isNotEmpty && blob != "NULL"
        ? jsonDecode(blob)
        : <String, dynamic>{};

    List<Diagnosis> parsedDiagnoses = [];
    if (rawCase['diagnoses'] != null && rawCase['diagnoses'] is List) {
      parsedDiagnoses = (rawCase['diagnoses'] as List)
          .map((e) => Diagnosis.fromRaw(e as Map<String, dynamic>))
          .toList();
    }

    String consentFormType = "NULL";
    Uint8List consentFormBytes = Uint8List(0);
    if (decryptedData["consent_form"] != null &&
        decryptedData["consent_form"] is Map<String, dynamic>) {
      try {
        final consentForm = decryptedData["consent_form"];
        consentFormType = consentForm["fileType"];
        consentFormBytes = base64Decode(consentForm["fileBytes"]);
      } catch (_) {}
    }

    List<Uint8List> imagesList = [];
    if (decryptedData['images'] != null && decryptedData['images'] is List) {
      imagesList = (decryptedData['images'] as List).whereType<String>().map((
        imgStr,
      ) {
        try {
          return base64Decode(imgStr);
        } catch (_) {
          return Uint8List(0);
        }
      }).toList();
    }

    return CaseRetrieveModel(
      createdAt: rawCase["created_at"] ?? "NULL",
      createdBy: rawCase["created_by"] ?? "NULL",
      submittedAt: rawCase["submitted_at"] ?? "NULL",
      alcohol: HabitMapper.fromString(rawCase["alcohol"]),
      alcoholDuration: rawCase["alcohol_duration"] ?? "NULL",
      betelQuid: HabitMapper.fromString(rawCase["betel_quid"]),
      betelQuidDuration: rawCase["betel_quid_duration"] ?? "NULL",
      smoking: HabitMapper.fromString(rawCase["smoking"]),
      smokingDuration: rawCase["smoking_duration"] ?? "NULL",
      oralHygieneProductsUsed: rawCase["oral_hygiene_products_used"] ?? false,
      oralHygieneProductTypeUsed:
          rawCase["oral_hygiene_product_type_used"] ?? "NULL",
      slsContainingToothpaste: rawCase["sls_containing_toothpaste"] ?? false,
      slsContainingToothpasteUsed:
          rawCase["sls_containing_toothpaste_used"] ?? "NULL",
      diagnoses: parsedDiagnoses,
      address: decryptedData["address"] ?? "NULL",
      age: decryptedData["age"] ?? "NULL",
      attendingHospital: decryptedData["attending_hospital"] ?? "NULL",
      chiefComplaint: decryptedData["chief_complaint"] ?? "NULL",
      consentForm: {"fileType": consentFormType, "fileBytes": consentFormBytes},
      dob: decryptedData["dob"] ?? "NULL",
      ethnicity: decryptedData["ethnicity"] ?? "NULL",
      gender: decryptedData["gender"] ?? "NULL",
      idnum: decryptedData["idnum"] ?? "NULL",
      idtype: decryptedData["idtype"] ?? "NULL",
      lesionClinicalPresentation:
          decryptedData["lesion_clinical_presentation"] ?? "NULL",
      medicalHistory: decryptedData["medical_history"] ?? "NULL",
      medicationHistory: decryptedData["medication_history"] ?? "NULL",
      name: decryptedData["name"] ?? "NULL",
      phonenum: decryptedData["phonenum"] ?? "NULL",
      presentingComplaintHistory:
          decryptedData["presenting_complaint_history"] ?? "NULL",
      images: imagesList,
      additionalComments: comments,
    );
  }

  /// Create CaseRetrieveModel from raw data (async to ensure lesion data is loaded)
  static Future<CaseRetrieveModel> fromRawAsync({
    required Map<String, dynamic> rawCase,
    required String blob,
    required String comments,
  }) async {
    // Ensure lesion data is loaded before parsing
    // Note: Crypto operations (PBKDF2, AES) are already async in isolates,
    // JSON parsing is fast, no need for another isolate
    final lesionDataManager = LesionDataManager();
    await lesionDataManager.loadData();

    // Parse synchronously - it's fast and avoids expensive serialization overhead
    return CaseRetrieveModel.fromRaw(
      rawCase: rawCase,
      blob: blob,
      comments: comments,
    );
  }
}

class CaseEditModel {
  // for study coordinators' case editing
  final Habit alcohol;
  final String alcoholDuration;
  final Habit betelQuid;
  final String betelQuidDuration;
  final Habit smoking;
  final String smokingDuration;
  final bool oralHygieneProductsUsed;
  final String oralHygieneProductTypeUsed;
  final bool slsContainingToothpaste;
  final String slsContainingToothpasteUsed;
  final String additionalComments;
  late final Map<String, String> encryptedComments;
  final List<Diagnosis> diagnoses;

  CaseEditModel({
    required this.alcohol,
    required this.alcoholDuration,
    required this.betelQuid,
    required this.betelQuidDuration,
    required this.smoking,
    required this.smokingDuration,
    this.oralHygieneProductsUsed = false,
    this.oralHygieneProductTypeUsed = "NULL",
    this.slsContainingToothpaste = false,
    this.slsContainingToothpasteUsed = "NULL",
    this.additionalComments = "NULL",
    required this.diagnoses,
    required aesKey,
  }) {
    assert(diagnoses.length == 9, 'Exactly 9 diagnoses are required.');
    encryptedComments = (additionalComments != "NULL")
        ? CryptoUtils.encryptString(additionalComments.trim(), aesKey)
        : {'ciphertext': "NULL", 'iv': "NULL"};
  }

  Map<String, dynamic> toJson() {
    return {
      "alcohol": alcohol.name,
      "alcohol_duration": alcoholDuration,
      "betel_quid": betelQuid.name,
      "betel_quid_duration": betelQuidDuration,
      "smoking": smoking.name,
      "smoking_duration": smokingDuration,
      "oral_hygiene_products_used": oralHygieneProductsUsed,
      "oral_hygiene_product_type_used": oralHygieneProductTypeUsed,
      "sls_containing_toothpaste": slsContainingToothpaste,
      "sls_containing_toothpaste_used": slsContainingToothpasteUsed,
      "additional_comments": encryptedComments,
      "diagnoses": diagnoses.map((d) => d.toEditJson()).toList(),
    };
  }
}

class CaseDiagnosisModel {
  final List<ClinicianDiagnosis> clinicianDiagnoses;

  CaseDiagnosisModel({required this.clinicianDiagnoses})
    : assert(
        clinicianDiagnoses.length == 9,
        'Exactly 9 diagnoses are required.',
      );

  Map<String, dynamic> toJson() {
    return {
      "diagnoses": [
        for (var diagnosis in clinicianDiagnoses) diagnosis.toJson(),
      ],
    };
  }
}
