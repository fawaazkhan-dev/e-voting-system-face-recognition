import 'package:flutter/material.dart';

class DocumentationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Documentation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How to Use the E-Voting App', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('1. Register: Navigate to the registration page and fill in the required details. Ensure your face is clearly captured by the camera.'),
              SizedBox(height: 10),
              Text('2. Login: Use your Email and password to log in. Make Sure to recognize your face to proceed. An OTP will be sent to your registered phone number for verification.'),
              SizedBox(height: 10),
              Text('3. User Panel: After successful login, you get access to the User Panel where you can Vote, access the Election time, view Results etc'),
              SizedBox(height: 10),
              Text('4. Voting: Select a Candidate and Click on Vote. Duplicate votes are not allowed. You can view Election Results after the election ends. When finished you can log out.'),
              SizedBox(height: 10),
              Text('5. Admin Panel: Administrators can manage users and candidates, start and end of voting, and view voting results.'),
            ],
          ),
        ),
      ),
    );
  }
}
