import 'package:flutter/material.dart';
import 'registration_screen.dart';
import 'face_recognition_screen.dart';
import 'api_service.dart';
import 'admin_panel.dart';
import 'user_panel.dart';
import 'send_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isFaceRecognized;
  final String recognizedEmail;
  // final bool isLivenessOk;

  LoginScreen({
    this.isFaceRecognized = false,
    this.recognizedEmail = '',
    // this.isLivenessOk = false,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _apiService = ApiService();

  void _login() async {

    final email = _emailController.text;


    if (!widget.isFaceRecognized) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Face recognition is required to log in')));
      return;
    }

    if (widget.recognizedEmail != email) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your Email does not match your recognized face. Try Again')));
      return;
    }

    // if (!widget.isLivenessOk) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Liveness detection failed')));
    //   return;
    // }

    final password = _passwordController.text;
    final phone = _phoneController.text;


    final response = await _apiService.login(email, password, phone);

    if (response != null && response['success']) {
      final userId = response['user_id'].toString();
      final isAdmin = response['is_admin'];

      // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, $email')));


      if (isAdmin) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminPanel(userId: userId)));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, $email')));
      } else {
        // Navigator.push(context, MaterialPageRoute(builder: (context) => UserPanel(userId: userId)));
        Navigator.push(context, MaterialPageRoute(builder: (context) => SendOtpScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, key: Key('loginEmailField'), decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, key: Key('loginPasswordField'), decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            // TextField(controller: _phoneController, key: Key('loginPhoneField'), decoration: InputDecoration(labelText: 'Phone')),
            ElevatedButton(key: Key('loginButton'), onPressed: _login, child: Text('Login')),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FaceRecognitionScreen()),
                  );
                },

                child: Text('Recognize Face'),
              ),
            ),
            Center(
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()));
                  },

                  child: Text('Register'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
