import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/auth.dart';
import 'package:mobile_app/core/services/storage.dart';
import 'package:mobile_app/core/utils/crypto.dart';
import 'package:mobile_app/firebase_options.dart';
// import 'package:http/http.dart' as http;

// void main() {
//   runApp(const MyApp());
// }

void main() async {
  await dotenv.load(fileName: ".env");

  // Register user
  // final result = await AuthService.registerUser(
  //   fullName: "Clinician 1",
  //   email: "clinician1@example.com",
  //   password: "MeMoSA2025",
  //   role: UserRole.clinician,
  // );
  // print(result);

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var publicRsa;
  var privateRsa;
  // Login user
  try {
    final result = await AuthService.loginUser(
      user: LoginUser(
        email: "studycoordinator1@example.com",
        password: dotenv.env['PRIVATE_KEY_PASSWORD'] ?? '',
      ),
    );
    if (result != null) {
      publicRsa = result['public_rsa'];
      privateRsa = result['private_rsa'];
    } else {
      print("Login failed or no user data returned.");
    }
    print(result);
  } catch (e) {
    print("Error: $e");
  }

  // Case creation
  final caseData = CaseModel(
    name: "test",
    idType: IdType.NRIC,
    idNum: "123",
    dob: DateTime(2000, 1, 1),
    gender: Gender.MALE,
    ethnicity: "Chinese",
    phoneNum: "0123",
    address: "test",
    attendingHos: "test",
  ).toJson();
  print("1. Case Data: $caseData");
  final newAesKey = CryptoUtils.generateAESKey();
  print("2. New AES Key: $newAesKey");
  final encryptedBlob = CryptoUtils.encryptCaseData(caseData, newAesKey);
  print("3. Encrypted Case Data: $encryptedBlob");
  final decodedPublicRsa = CryptoUtils.decodePublicKeyFromPem(publicRsa);
  print("4. Decoded Public RSA: $decodedPublicRsa");
  final encryptedAesKey = CryptoUtils.encryptAESKey(
    newAesKey,
    decodedPublicRsa,
  );
  print("5. Encrypted AES Key: $encryptedAesKey");
  final downloadUrl = await StorageService.uploadEncryptedBlob(
    encryptedBlob: encryptedBlob,
    fileName: "test",
  );
  print("6. Download URL: $downloadUrl");
  // Case retrieval
  final downloadedBlob = await StorageService.downloadEncryptedBlob(
    downloadUrl,
  );
  print("7. Downloaded Blob: $downloadedBlob");
  final decodedPrivateRsa = CryptoUtils.decodePrivateKeyFromPem(privateRsa);
  print("8. Decoded Private RSA: $decodedPrivateRsa");
  final decryptedAesKey = CryptoUtils.decryptAESKey(
    encryptedAesKey,
    decodedPrivateRsa,
  );
  print("9. Decrypted AES Key: $decryptedAesKey");
  final decryptedBlob = CryptoUtils.decryptCaseData(
    downloadedBlob,
    decryptedAesKey,
  );
  print("10. Decrypted Case Data: $decryptedBlob");

  // Generate shared RSA key pair
  // var rsakeypair = CryptoUtils.generateRSAKeyPair(bitLength: 2048);
  // var publicPem = CryptoUtils.encodePublicKeyToPem(rsakeypair.publicKey);
  // print("Public Key PEM: $publicPem");
  // var privatePem = CryptoUtils.encodePrivateKeyToPem(rsakeypair.privateKey);
  // print(privatePem.contains('-----END PRIVATE KEY-----'));
  // // print("Private Key PEM: $privatePem");
  // var encryptedPrivatePem = CryptoUtils.encryptPrivateKey(
  //   privatePem,
  //   "MeMoSA2025",
  // );
  // print("Encrypted Private Key PEM: $encryptedPrivatePem");
  // final response = await http.post(
  //   Uri.parse("http://10.0.2.2:8000/auth/store-key"),
  //   body: jsonEncode({
  //     "public_rsa": publicPem,
  //     "private_rsa": encryptedPrivatePem,
  //   }),
  // );
  // print(response.body);
}

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
