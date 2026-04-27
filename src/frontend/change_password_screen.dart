import 'package:flutter/material.dart';
import 'api_service.dart'; // Correct import


class ChangePasswordScreen extends StatefulWidget {
  final String userId;

  ChangePasswordScreen({required this.userId});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService(); // Fix ApiService instance

  // Validate the form fields and submit
  Future<void> _changePassword() async {
    // Make the method async
    if (_formKey.currentState!.validate()) {
      final newPassword = _newPasswordController.text;

      try {
        // Call the API to change the password
        final response = await _apiService.changePassword(widget.userId, newPassword);

        if (response['success']) {
          // Show success message and navigate away
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${response['message']}')),
          );
          Navigator.pop(context); // Go back to the previous screen
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                '${response['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  } else if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  // Optional: Add more validation logic here if needed
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  } else if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _changePassword,
                child: Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
