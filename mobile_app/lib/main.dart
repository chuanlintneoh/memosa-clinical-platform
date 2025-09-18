// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
import 'package:mobile_app/features/auth/auth_gate.dart';
import 'package:mobile_app/features/auth/login_screen.dart';
import 'package:mobile_app/features/auth/register_screen.dart';
import 'package:mobile_app/firebase_options.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());

  // Register user
  // final result = await AuthService.registerUser(
  //   fullName: "Clinician 1",
  //   email: "clinician1@example.com",
  //   password: dotenv.env['PASSWORD'] ?? '',
  //   role: UserRole.clinician,
  // );
  // print(result);

  // Login user
  // try {
  //   final result = await AuthService.loginUser(
  //     user: LoginUser(
  //       email: "studycoordinator1@example.com",
  //       password: dotenv.env['PASSWORD'] ?? '',
  //     ),
  //   );
  //   print(result);
  // } catch (e) {
  //   print("Error: $e");
  // }

  // Get undiagnosed cases
  // final undiagnosedCases = await DbManagerService.getUndiagnosedCases(
  //   clinicianID: "A",
  // );
  // print(undiagnosedCases[0]);
  // print(undiagnosedCases[0]["case_data"].createdAt);
  // print(undiagnosedCases[0]["case_data"].address);
  // print(undiagnosedCases[0]["case_data"].additionalComments);
  // print(undiagnosedCases[1]);
  // print(undiagnosedCases[1]["case_data"].createdAt);
  // print(undiagnosedCases[1]["case_data"].address);
  // print(undiagnosedCases[1]["case_data"].additionalComments);

  // Diagnose a case
  // final List<ClinicianDiagnosis> clinicianDiagnoses = List.generate(
  //   9,
  //   (index) => ClinicianDiagnosis(
  //     clinicianID: "A",
  //     clinicalDiagnosis: ClinicalDiagnosis.A,
  //     lesionType: LesionType.CANCER,
  //     lowQuality: false,
  //   ),
  // );
  // final CaseDiagnosisModel diagnoseCase = CaseDiagnosisModel(
  //   clinicianDiagnoses: clinicianDiagnoses,
  // );
  // final diagnoseResult = await DbManagerService.diagnoseCase(
  //   caseId: "15082025test",
  //   diagnoses: diagnoseCase,
  // );
  // print(diagnoseResult);
}

// Uint8List generateDummyBytes(int sizeInKB) {
//   final random = Random();
//   return Uint8List.fromList(
//     List<int>.generate(sizeInKB * 1024, (_) => random.nextInt(256)),
//   );
// }

// Future<Uint8List> loadImageAsset(String path) async {
//   final byteData = await rootBundle.load(path);
//   return byteData.buffer.asUint8List();
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeMoSA Clinical Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 26, 191, 223),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
