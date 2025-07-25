enum IdType { NRIC, PASSPORT }

enum Gender { MALE, FEMALE }

// enum Ethnicity { ASIAN, BLACK, WHITE, HISPANIC, OTHER }

class CaseModel {
  final String name;
  final IdType idType;
  final String idNum;
  final DateTime dob;
  final Gender gender;
  final String ethnicity;
  final String phoneNum;
  final String address;
  final String attendingHos;

  CaseModel({
    required this.name,
    required this.idType,
    required this.idNum,
    required this.dob,
    required this.gender,
    required this.ethnicity,
    required this.phoneNum,
    required this.address,
    required this.attendingHos,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id_type': idType.toString().split('.').last,
      'id_num': idNum,
      'dob': dob.toIso8601String(),
      'gender': gender.toString().split('.').last,
      'ethnicity': ethnicity,
      'phone_num': phoneNum,
      'address': address,
      'attending_hos': attendingHos,
    };
  }
}
