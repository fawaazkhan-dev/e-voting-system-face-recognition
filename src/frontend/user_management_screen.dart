import 'package:flutter/material.dart';
import 'api_service.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _apiService = ApiService();
  List<String> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    final users = await _apiService.getUsers();
    setState(() {
      _users = users;
    });
  }

  void _deleteUser(String email) async {
    final success = await _apiService.deleteUser(email);
    if (success) {
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User $email deleted.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Management')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: _users.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _users.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(_users[index]),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteUser(_users[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
