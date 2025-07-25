enum UserRole {
  studyCoordinator,
  clinician,
  admin;

  String toApiValue() {
    switch (this) {
      case UserRole.studyCoordinator:
        return 'study_coordinator';
      case UserRole.clinician:
        return 'clinician';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromApiValue(String value) {
    switch (value) {
      case 'study_coordinator':
        return UserRole.studyCoordinator;
      case 'clinician':
        return UserRole.clinician;
      case 'admin':
        return UserRole.admin;
      default:
        throw ArgumentError('Unknown user role: $value');
    }
  }
}

class RegisterUser {
  final String fullName;
  final String email;
  final String password;
  final String role;
  final String? publicRsa;
  final String? privateRsa;

  RegisterUser({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.publicRsa,
    this.privateRsa,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'full_name': fullName,
      'email': email,
      'password': password,
      'role': role,
    };

    if (role == "clinician") {
      data['public_rsa'] = publicRsa!;
      data['private_rsa'] = privateRsa!;
    }

    return data;
  }
}

class LoginUser {
  final String email;
  final String password;

  LoginUser({required this.email, required this.password});
}
