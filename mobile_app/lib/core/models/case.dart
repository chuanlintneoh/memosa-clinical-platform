import 'dart:convert';
import 'dart:typed_data';

enum Habit { YES, OCCASIONALLY, NO }

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
  final String? additionalComments;

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
    this.additionalComments,
  });
}

enum IdType { NRIC, PPN }

enum Gender { MALE, FEMALE }

class PrivateCaseModel {
  final String address;
  final String age;
  final String attendingHospital;
  final String chiefComplaint;
  final Uint8List consentForm;
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
      "consent_form": base64Encode(consentForm),
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
  final String aiLesionType;
  final String biopsyAgreeWithCoe;
  final String biopsyClinicalDiagnosis;
  final String biopsyLesionType;
  final String biopsyReportUrl;
  final String coeClinicalDiagnosis;
  final String coeLesionType;

  Diagnosis({
    required this.aiLesionType,
    required this.biopsyAgreeWithCoe,
    required this.biopsyClinicalDiagnosis,
    required this.biopsyLesionType,
    required this.biopsyReportUrl,
    required this.coeClinicalDiagnosis,
    required this.coeLesionType,
  });

  factory Diagnosis.empty() => Diagnosis(
    aiLesionType: "NULL",
    biopsyAgreeWithCoe: "NULL",
    biopsyClinicalDiagnosis: "NULL",
    biopsyLesionType: "NULL",
    biopsyReportUrl: "NULL",
    coeClinicalDiagnosis: "NULL",
    coeLesionType: "NULL",
  );

  Map<String, dynamic> toJson() {
    return {
      "ai_lesion_type": aiLesionType,
      "biopsy_agree_with_coe": biopsyAgreeWithCoe,
      "biopsy_clinical_diagnosis": biopsyClinicalDiagnosis,
      "biopsy_lesion_type": biopsyLesionType,
      "biopsy_report_url": biopsyReportUrl,
      "coe_clinical_diagnosis": coeClinicalDiagnosis,
      "coe_lesion_type": coeLesionType,
    };
  }
}

class CaseDocumentModel {
  final PublicCaseModel publicData;
  final Map<String, String> encryptedAes;
  final Map<String, String> encryptedBlob;
  final Map<String, String> encryptedComments;

  CaseDocumentModel({
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
