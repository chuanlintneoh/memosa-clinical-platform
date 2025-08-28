import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider; // Add this import
import 'package:firebase_ui_auth/firebase_ui_auth.dart';                  // And this import
import 'package:flutter/material.dart';

import '../home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    // listen to FirebaseAuth's authStateChanges to determine whether the user
    // is authenticated (go to home screen) or not (display a sign-in screen).
    return StreamBuilder<User?>(                                       // Modify from here...
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [EmailAuthProvider()],
            headerBuilder: (context, constraints, shrinkOffset) {
              return AspectRatio(
                aspectRatio: 1,
                child: Image.asset('assets/images/logo_crmy.webp'),
              );
            },
            subtitleBuilder: (context, action) {
              return action == AuthAction.signIn
                  ? Text("Mouth cancer screening - anywhere and anytime")
                  : Text("Join us in protecting your oral health");
            },
            footerBuilder: (context, action) {
              return Text(
                'By signing in, you agree to our terms and conditions.',
                textAlign: TextAlign.center,
              );
            },
          );
        }

        return const HomeScreen();
      },
    );                                                                 // To here.
  }
}