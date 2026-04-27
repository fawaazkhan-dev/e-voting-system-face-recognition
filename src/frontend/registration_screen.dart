import 'package:flutter/material.dart';
import 'api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  // late final ImagePicker imagePicker;
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _faceImage;
  final _apiService = ApiService();

  void _register() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final phone = _phoneController.text;

    // Email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid email address')));
      return;
    }

    // Password validation
    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Password must be at least 6 characters long')));
      return;
    }

    // Phone number validation
    final phoneRegex = RegExp(r'^\+230\d+$'); // only digits
    if (phone.isEmpty || !phoneRegex.hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid phone number')));
      return;
    }


    if (_faceImage != null) {
      final success = await _apiService.register(email, password, phone, _faceImage!);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Successful')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration failed')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please capture your face image')));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _faceImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, key: Key('emailField'), decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, key: Key('passwordField'), decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            TextField(controller: _phoneController, key: Key('phoneField'), decoration: InputDecoration(labelText: 'Phone')),
            ElevatedButton(key: Key('takePictureButton'), onPressed: _pickImage, child: Text('Capture Face Image')),
            ElevatedButton(key: Key('registerButton'), onPressed: _register, child: Text('Register')),
          ],
        ),
      ),
    );
  }
}
