import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/auth.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
import 'package:mobile_app/core/services/storage.dart';
import 'package:mobile_app/core/utils/crypto.dart';
import 'package:mobile_app/firebase_options.dart';
import 'package:open_filex/open_filex.dart';

// void main() {
//   runApp(const MyApp());
// }

void main() async {
  await dotenv.load(fileName: ".env");

  // Register user
  // final result = await AuthService.registerUser(
  //   fullName: "Clinician 1",
  //   email: "clinician1@example.com",
  //   password: dotenv.env['PASSWORD'] ?? '',
  //   role: UserRole.clinician,
  // );
  // print(result);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Login user
  try {
    final result = await AuthService.loginUser(
      user: LoginUser(
        email: "studycoordinator1@example.com",
        password: dotenv.env['PASSWORD'] ?? '',
      ),
    );
    print(result);
  } catch (e) {
    print("Error: $e");
  }

  // Case creation
  // final imageBytes = await loadImageAsset("assets/tongue-cancer.jpg");
  // DbManagerService.createCase(
  //   caseId: "16082025test",
  //   publicData: PublicCaseModel(
  //     createdAt: DateTime.now(),
  //     createdBy: "test_user",
  //     alcohol: Habit.YES,
  //     alcoholDuration: "2 years",
  //     betelQuid: Habit.OCCASIONALLY,
  //     betelQuidDuration: "1 year",
  //     smoking: Habit.NO,
  //     smokingDuration: "3 years",
  //     oralHygieneProductsUsed: true,
  //     oralHygieneProductTypeUsed: "Toothpaste",
  //     slsContainingToothpaste: true,
  //     slsContainingToothpasteUsed: "Darlie",
  //     additionalComments: "Test case for clinician",
  //   ),
  //   privateData: PrivateCaseModel(
  //     address:
  //         "123 Example Street, Apartment 4B, Springfield, 11900, Example Country.",
  //     age: "30",
  //     attendingHospital: "Tan Tock Seng Hospital",
  //     chiefComplaint: "Persistent headache and dizziness",
  //     consentForm: generateDummyBytes(100),
  //     dob: DateTime(1993, 1, 1),
  //     ethnicity: "Chinese",
  //     gender: Gender.MALE,
  //     idNum: "701204072039",
  //     idType: IdType.NRIC,
  //     lesionClinicalPresentation:
  //         "Small round lesion on the left forearm, approx. 2cm in diameter.",
  //     medicalHistory: "No known chronic illnesses.",
  //     medicationHistory: "Occasional use of paracetamol.",
  //     name: "John Doe",
  //     phoneNum: "60123456789",
  //     presentingComplaintHistory:
  //         "Symptoms started two weeks ago, worsening over the past three days.",
  //     images: List.generate(9, (_) => imageBytes),
  //   ),
  // );

  // Search a case
  // final searchResult = await DbManagerService.searchCase(
  //   caseId: "15082025test",
  // );
  // print(searchResult["case_data"].createdAt);
  // print(searchResult["case_data"].address);
  // print(searchResult["case_data"].additionalComments);

  // Edit a case
  // var encryptedData = CryptoUtils.encryptString(
  //   base64Encode(generateDummyBytes(5)),
  //   searchResult['aes'],
  // );
  // final biopsyReports = await Future.wait(
  //   List.generate(9, (index) async {
  //     final url = await StorageService.upload(
  //       encrypted: encryptedData['ciphertext'],
  //       fileName: "15082025test_$index.enc",
  //       path: "biopsy_reports",
  //     );
  //     return {'url': url, 'iv': encryptedData['iv'] ?? "NULL"};
  //   }),
  // );
  // final List<Diagnosis> diagnoses = List.generate(
  //   9,
  //   (index) => Diagnosis(
  //     aiLesionType: LesionType.NULL,
  //     biopsyClinicalDiagnosis: ClinicalDiagnosis.A,
  //     biopsyLesionType: LesionType.BENIGN,
  //     biopsyReport: biopsyReports[index],
  //     coeClinicalDiagnosis: ClinicalDiagnosis.B,
  //     coeLesionType: LesionType.BENIGN,
  //   ),
  // );
  // final CaseEditModel editCase = CaseEditModel(
  //   alcohol: Habit.NO,
  //   alcoholDuration: "Nope",
  //   betelQuid: Habit.YES,
  //   betelQuidDuration: "2 years",
  //   smoking: Habit.OCCASIONALLY,
  //   smokingDuration: "10 years",
  //   oralHygieneProductsUsed: true,
  //   oralHygieneProductTypeUsed: "Toothpaste",
  //   slsContainingToothpaste: true,
  //   slsContainingToothpasteUsed: searchResult["case_data"]
  //       .slsContainingToothpasteUsed, // default: always reuse original value during editing
  //   additionalComments: searchResult["case_data"].additionalComments,
  //   diagnoses: diagnoses,
  //   aesKey: searchResult['aes'],
  // );
  // final editResult = await DbManagerService.editCase(
  //   caseId: "15082025test",
  //   caseData: editCase,
  // );
  // print(editResult);

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

  // Export mastersheet csv
  // final mastersheet = await DbManagerService.exportMastersheet();
  // print("Mastersheet saved to: ${mastersheet.path}");
  // final result = await OpenFilex.open(mastersheet.path);
  // print("Open file result: ${result.message}");
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
