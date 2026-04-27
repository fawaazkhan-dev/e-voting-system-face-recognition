import 'dart:ffi';

import 'package:flutter/material.dart';
import 'set_election_time.dart';
import 'user_management_screen.dart';
import 'candidate_management_screen.dart';
import 'documentation_screen.dart';
import 'api_service.dart';
import 'admin_user_management_screen.dart';
import 'results_screen.dart';

class AdminPanel extends StatelessWidget {
  final String userId;

  AdminPanel({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminUserManagementScreen()),
                );
              },
              child: Text('Admin Users'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserManagementScreen()),
                );
              },
              child: Text('Manage Users'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CandidateManagementScreen()),
                );
              },
              child: Text('Manage Candidates'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResultsScreen()),
                );
              },
              child: Text('View Results'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetElectionTimeScreen()),
                );
              },
              child: Text('Set Election Time'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DocumentationScreen()),
                );
              },
              child: Text('Documentation'),
            ),

            ElevatedButton(
              onPressed: () async {
                await ApiService.logout();
                Navigator.pop(context);
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
