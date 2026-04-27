// import 'package:flutter/material.dart';
// import 'main.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
// import 'package:http/io_client.dart';

class ApiService {
  // static const String baseUrl = 'https://localhost:5000';
  // static const String baseUrl = 'https://10.0.2.2:5000';
  // static const String baseUrl = 'https://192.168.100.95:5000';
  static const String baseUrl = 'https://192.168.142.166:5000';
  // final IOClient client = IOClient(_getHttpClient());
  //
  // static HttpClient _getHttpClient() {
  //   HttpClient client = HttpClient();
  //   client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  //   return client;
  // }

  //ORIGINAL
  // Future<bool> login(String email, String password, String phone) async {
  //   final response = await http.post(
  //     Uri.parse('$baseUrl/login'),
  //     body: {'email': email, 'password': password, 'phone': phone},
  //   );
  //   return response.statusCode == 200;
  // }

  //TEST
  Future<Map<String, dynamic>?> login(String email, String password, String phone) async {

    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'email': email, 'password': password, 'phone': phone},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return null;
    }
  }
  //TEST END

  // Future<bool> register(String email, String password, String phone, File faceImage) async {
  //   final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));
  //   request.fields['email'] = email;
  //   request.fields['password'] = password;
  //   request.fields['phone'] = phone;
  //   request.files.add(await http.MultipartFile.fromPath('face_image', faceImage.path));
  //   final response = await request.send();
  //   return response.statusCode == 200;
  // }

  Future<bool> register(String email, String password, String phone, File faceImage) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/register'));
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['phone'] = phone;
      request.files.add(await http.MultipartFile.fromPath('face_image', faceImage.path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Registration failed: ${response.statusCode} - $responseBody');
        return false;
      }
    } catch (e) {
      print('An error occurred during registration: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> changePassword(String userId, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/change-password'),
      body: {'userId': userId, 'new_password': newPassword},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to change password');
    }
  }


  // Future<bool> verifyOtp(String phone, String otp) async {
  //   final response = await http.post(
  //     Uri.parse('$baseUrl/verify-otp'),
  //     body: {'phone': phone, 'otp': otp},
  //   );
  //   return response.statusCode == 200;
  // }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      body: {'phone': phone},
    );
    // return response.statusCode == 200;
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }else {
      throw Exception('Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      body: {'phone': phone, 'otp': otp},
    );
    // return response.statusCode == 200;
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }else {
      throw Exception('Failed to verify OTP');
    }
  }

  Future<List<String>> getCandidates() async {
    final response = await http.get(Uri.parse('$baseUrl/candidates'));
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }

  // Future<bool> vote(String candidate) async {
  //   final response = await http.post(
  //     Uri.parse('$baseUrl/vote'),
  //     body: {'candidate': candidate},
  //   );
  //   return response.statusCode == 200;
  // }

  Future<bool> vote(String userId, String candidate) async {
  final response = await http.post(
    Uri.parse('$baseUrl/vote'),
    body: {'user_id': userId, 'candidate': candidate},
  );
  
  if (response.statusCode == 200) {
    return true;
  } else {
    print('Vote failed: ${response.body}');  // Debugging output
    return false;
  }
}


  Future<List<String>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<bool> deleteUser(String email) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-user?email=$email'),
    );
    return response.statusCode == 200;
  }

  Future<bool> addUser(String email, String password, String phone) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-user'),
      body: {'email': email, 'password': password, 'phone': phone},
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteCandidate(String candidate) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/delete-candidate?candidate=$candidate'),
    );
    return response.statusCode == 200;
  }

  Future<bool> addCandidate(String candidate) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add-candidate'),
      body: {'candidate': candidate},
    );
    return response.statusCode == 200;
  }

  Future<List<Map<String, dynamic>>> getResults() async {
    final response = await http.get(Uri.parse('$baseUrl/results'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((result) => {
        'candidate': result['candidate'],
        'vote_count': result['vote_count']
      }).toList();
    } else {
      throw Exception('Failed to load results');
    }
  }

  Future<bool> detectFace(String imagePath) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/detect-face'));
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final response = await request.send();
    return response.statusCode == 200;
  }

  // Future<bool> recognizeFace(String imagePath) async {
  //   final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/recognize-face'));
  //   request.files.add(await http.MultipartFile.fromPath('image', imagePath));
  //   final response = await request.send();
  //   if (response.statusCode == 200) {
  //     final responseBody = await response.stream.bytesToString();
  //     final responseData = jsonDecode(responseBody);
  //     return responseData['success'];
  //   }
  //   return false;
  // }

  // Future<http.Response> recognizeFace(String imagePath) async {
  //   final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/recognize-face'));
  //   request.files.add(await http.MultipartFile.fromPath('image', imagePath));
  //   final streamedResponse = await request.send();
  //   final response = await http.Response.fromStream(streamedResponse);
  //   return response;
  //
  // }

  Future recognizeFace(String imagePath) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/recognize-face'));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      // Print the response from the server
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle response as needed
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          print('Face recognized: ${result['user']}');

        } else {
          print('Face recognition failed: ${result['error']}');
        }
      } else {
        print('Server returned error: ${response.reasonPhrase}');
      }

      return response;
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<bool> checkIsAdmin(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/is_admin?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_admin'] == true;
    } else {
      throw Exception('Failed to check admin status');
    }
  }

  static Future<bool> setAdmin(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set-admin'),
      body: {'email': email},
    );

    return response.statusCode == 200;
  }

  static Future<bool> setElectionTime(DateTime startTime, DateTime endTime, bool isEnabled) async {
    final response = await http.post(
      Uri.parse('$baseUrl/set-election-time'),
        body: {
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'is_enabled': isEnabled.toString(),
        }
    );

    // if (response.statusCode == 200) {
    //   return true;
    // } else {
    //   return false;
    // }
    return response.statusCode == 200;

  }

  static Future<bool> disableElectionTime() async {
    final response = await http.post(
      Uri.parse('$baseUrl/disable-election-time'),
    );

    return response.statusCode == 200;
  }


  static Future<bool> checkElectionTime() async {
    final response = await http.get(
      Uri.parse('$baseUrl/check-election-time'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['is_within_time'];
    } else {
      return false;
    }
  }

  static Future<bool> checkElectionStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/check-election-status'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['election_enabled'];
    } else {
      return false;
    }
  }

  static Future<bool> isElectionEnabled() async {
    final response = await http.get(Uri.parse('$baseUrl/check-election-enabled'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['is_enabled'];
    } else {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getElectionTime() async {
    final response = await http.get(Uri.parse('$baseUrl/get-election-time'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  static Future<void> logout() async {

  }
}
