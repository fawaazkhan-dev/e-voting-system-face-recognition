import 'login_screen.dart';
import 'registration_screen.dart';
import 'voting_screen.dart';
// import 'otp_screen.dart';
import 'user_panel.dart';
import 'admin_panel.dart';
import 'user_management_screen.dart';
import 'candidate_management_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HttpOverridesCustom extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = HttpOverridesCustom();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/registration': (context) => RegistrationScreen(),
        '/voting': (context) => VotingScreen(userId: '',),
        // '/otp': (context) => OtpScreen(phone: '', userId: '',),
        '/user_panel': (context) => UserPanel(userId: '',),
        '/admin_panel': (context) => AdminPanel(userId: '',),
        '/user_management': (context) => UserManagementScreen(),
        '/candidate_management': (context) => CandidateManagementScreen(),
      },
    );
  }
}
