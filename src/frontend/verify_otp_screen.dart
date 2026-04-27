import 'package:flutter/material.dart';
import 'api_service.dart';
import 'user_panel.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String phone;

  VerifyOtpScreen({required this.phone});

  @override
  _VerifyOtpScreenState createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  final _apiService = ApiService();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    final otp = _otpController.text;
    // final success = await _apiService.verifyOtp(widget.phone, otp);
    final response = await _apiService.verifyOtp(widget.phone, otp);
    final userId = response['user_id'].toString();
    final email = response['email'];

    if (response['success']) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserPanel(userId: userId), 
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, $email')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter OTP')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _otpController,
              decoration: InputDecoration(labelText: 'OTP'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
