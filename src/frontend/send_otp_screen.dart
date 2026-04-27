import 'package:flutter/material.dart';
import 'api_service.dart';
import 'verify_otp_screen.dart';

class SendOtpScreen extends StatefulWidget {
  @override
  _SendOtpScreenState createState() => _SendOtpScreenState();
}

class _SendOtpScreenState extends State<SendOtpScreen> {
  final _phoneController = TextEditingController();
  final _apiService = ApiService();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final phone = _phoneController.text;
    // final success = await _apiService.sendOtp(phone);
    final response = await _apiService.sendOtp(phone);

    if (response['success']) {

      Future.delayed(Duration(seconds: 3), ()
      {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(phone: phone),
          ),
        );
    });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OTP has been sent')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send OTP')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('An OTP will be sent to your phone via SMS.'),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendOtp,
              child: Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
