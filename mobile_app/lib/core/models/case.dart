import 'dart:convert';
import 'dart:typed_data';

import 'package:mobile_app/core/utils/crypto.dart';

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

enum IdType { NRIC, PPN }

enum Gender { MALE, FEMALE }

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

enum LesionType { NULL, CANCER, OPMD, DA, NAV, BENIGN, NO_LESION, OTHER }

extension LesionTypeMapper on LesionType {
  static LesionType fromString(String? value) {
    if (value == null) return LesionType.NULL;
    return LesionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LesionType.NULL,
    );
  }
}

enum ClinicalDiagnosis { NULL, A, B }

extension ClinicalDiagnosisMapper on ClinicalDiagnosis {
  static ClinicalDiagnosis fromString(String? value) {
    if (value == null) return ClinicalDiagnosis.NULL;
    return ClinicalDiagnosis.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ClinicalDiagnosis.NULL,
    );
  }
}

enum BiopsyAgreeWithCOE { NULL, YES, NO } // not stored in database

class Diagnosis {
  final LesionType aiLesionType;
  final ClinicalDiagnosis biopsyClinicalDiagnosis;
  final LesionType biopsyLesionType;
  final Map<String, dynamic> biopsyReport;
  final ClinicalDiagnosis coeClinicalDiagnosis;
  final LesionType coeLesionType;
  BiopsyAgreeWithCOE biopsyAgreeWithCoe = BiopsyAgreeWithCOE.NULL;

  Diagnosis({
    required this.aiLesionType,
    required this.biopsyClinicalDiagnosis,
    required this.biopsyLesionType,
    required this.biopsyReport,
    required this.coeClinicalDiagnosis,
    required this.coeLesionType,
  }) {
    if (biopsyLesionType != LesionType.NULL &&
        coeLesionType != LesionType.NULL) {
      biopsyAgreeWithCoe = (biopsyLesionType == coeLesionType)
          ? BiopsyAgreeWithCOE.YES
          : BiopsyAgreeWithCOE.NO;
      if (biopsyClinicalDiagnosis != ClinicalDiagnosis.NULL &&
          coeClinicalDiagnosis != ClinicalDiagnosis.NULL) {
        biopsyAgreeWithCoe =
            (biopsyLesionType == coeLesionType &&
                biopsyClinicalDiagnosis == coeClinicalDiagnosis)
            ? BiopsyAgreeWithCOE.YES
            : BiopsyAgreeWithCOE.NO;
      }
    }
  }

  factory Diagnosis.empty() => Diagnosis(
    aiLesionType: LesionType.NULL,
    biopsyClinicalDiagnosis: ClinicalDiagnosis.NULL,
    biopsyLesionType: LesionType.NULL,
    biopsyReport: {"url": "NULL", "iv": "NULL", "fileType": "NULL"},
    coeClinicalDiagnosis: ClinicalDiagnosis.NULL,
    coeLesionType: LesionType.NULL,
  );

  factory Diagnosis.fromRaw(Map<String, dynamic> rawDiagnosis) {
    return Diagnosis(
      aiLesionType: LesionTypeMapper.fromString(rawDiagnosis["ai_lesion_type"]),
      biopsyClinicalDiagnosis: ClinicalDiagnosisMapper.fromString(
        rawDiagnosis["biopsy_clinical_diagnosis"],
      ),
      biopsyLesionType: LesionTypeMapper.fromString(
        rawDiagnosis["biopsy_lesion_type"],
      ),
      biopsyReport:
          rawDiagnosis["biopsy_report"] ??
          {"url": "NULL", "iv": "NULL", "fileType": "NULL"},
      coeClinicalDiagnosis: ClinicalDiagnosisMapper.fromString(
        rawDiagnosis["coe_clinical_diagnosis"],
      ),
      coeLesionType: LesionTypeMapper.fromString(
        rawDiagnosis["coe_lesion_type"],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "ai_lesion_type": aiLesionType.name,
      "biopsy_clinical_diagnosis": biopsyClinicalDiagnosis.name,
      "biopsy_lesion_type": biopsyLesionType.name,
      "biopsy_report": biopsyReport,
      "coe_clinical_diagnosis": coeClinicalDiagnosis.name,
      "coe_lesion_type": coeLesionType.name,
    };
  }

  Map<String, dynamic> toEditJson() {
    // disable editing of ai_lesion_type
    return {
      "biopsy_clinical_diagnosis": biopsyClinicalDiagnosis.name,
      "biopsy_lesion_type": biopsyLesionType.name,
      "biopsy_report": biopsyReport,
      "coe_clinical_diagnosis": coeClinicalDiagnosis.name,
      "coe_lesion_type": coeLesionType.name,
    };
  }
}

class ClinicianDiagnosis {
  final String clinicianID;
  final ClinicalDiagnosis clinicalDiagnosis;
  final LesionType lesionType;
  final bool lowQuality;

  ClinicianDiagnosis({
    required this.clinicianID,
    required this.clinicalDiagnosis,
    required this.lesionType,
    required this.lowQuality,
  });

  Map<String, dynamic> toJson() {
    return {
      clinicianID: {
        "clinical_diagnosis": clinicalDiagnosis.name,
        "lesion_type": lesionType.name,
        "low_quality": lowQuality,
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
