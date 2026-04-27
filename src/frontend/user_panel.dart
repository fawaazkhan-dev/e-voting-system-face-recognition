import 'package:flutter/material.dart';
import 'change_password_screen.dart';
import 'voting_screen.dart';
import 'documentation_screen.dart';
import 'api_service.dart';
import 'login_screen.dart';
import 'results_screen.dart';
import 'election_time.dart';

class UserPanel extends StatelessWidget {
  final String userId;

  UserPanel({required this.userId});

  Future<bool> _canViewResults() async {
    // Call an API service method to check if election results can be viewed
    return await ApiService.checkElectionStatus();
  }

  Future<void> _checkElectionTimeAndNavigate(BuildContext context) async {
    bool isWithinTime = await ApiService.checkElectionTime();

    if (!isWithinTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voting is not allowed outside of the election time')),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VotingScreen(userId: userId)),
      );
    }
  }

  Future<void> _checkElectionTimeEnabledAndNavigate(BuildContext context) async {
    bool isElectionEnabled = await ApiService.isElectionEnabled();

    if (isElectionEnabled) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ElectionTimeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Election time is not enabled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to Change Password Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordScreen(userId: userId)),
                );
              },
              child: Text('Change Password'),
            ),
            ElevatedButton(
              onPressed: () => _checkElectionTimeEnabledAndNavigate(context),
              child: Text('View Election Time'),
            ),
            ElevatedButton(
              key: Key('voteButton'),
              onPressed: () => _checkElectionTimeAndNavigate(context),
              child: Text('Vote'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool canViewResults = await _canViewResults();
                if (canViewResults) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You can view results at the end of the election')),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResultsScreen()),
                  );
                }
              },
              child: Text('View Results'),
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
