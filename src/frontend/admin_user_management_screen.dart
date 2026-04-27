import 'package:flutter/material.dart';
import 'api_service.dart';

class AdminUserManagementScreen extends StatefulWidget {
  @override
  _AdminUserManagementScreenState createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _emailController = TextEditingController();
  String _message = '';

  Future<void> _setAdmin() async {
    final email = _emailController.text;

    if (email.isEmpty) {
      setState(() {
        _message = 'Email cannot be empty.';
      });
      return;
    }

    final success = await ApiService.setAdmin(email);

    setState(() {
      _message = success ? '$email has been set as admin.' : 'Failed to set $email as admin.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin User Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'User Email'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _setAdmin,
              child: Text('Set Admin'),
            ),
            SizedBox(height: 16),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
