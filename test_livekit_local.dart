// Local LiveKit Testing Script
// Run: dart run test_livekit_local.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🧪 Testing LiveKit Connection Locally...\n');

  // Test 1: Check backend connectivity
  print('1️⃣ Testing Backend Connection...');
  try {
    final response = await http.get(Uri.parse('http://localhost:5000'));
    print('   ✅ Backend is running');
    print('   Response: ${response.statusCode}');
  } catch (e) {
    print('   ❌ Backend connection failed: $e');
    print('   💡 Make sure backend is running: npm start');
    return;
  }

  print('');

  // Test 2: Test token generation (requires auth token)
  print('2️⃣ Testing LiveKit Token Generation...');
  print('   ℹ️ You need to login first and provide auth token');
  print('');

  // Get auth token from user
  print('📝 Enter your auth token (from login):');
  final authToken = stdin.readLineSync();

  if (authToken == null || authToken.isEmpty) {
    print('   ⚠️ No auth token provided. Skipping token test.');
    print('');
    print('📱 To get auth token:');
    print('   1. Run the app: flutter run');
    print('   2. Login with your mobile number');
    print('   3. Check console for token or SharedPreferences');
    return;
  }

  print('');

  // Test 3: Generate LiveKit token for test frequency
  print('3️⃣ Generating LiveKit Token for frequency 450...');
  try {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/v1/livekit/token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'frequencyId': '450', 'participantName': 'Test User'}),
    );

    print('   Response Status: ${response.statusCode}');
    print('   Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('   ✅ LiveKit Token Generated Successfully!');
        print('   🔗 LiveKit URL: ${data['data']['url']}');
        print('   🎫 Token: ${data['data']['token'].substring(0, 50)}...');
        print('   🏠 Room: ${data['data']['roomName']}');
      } else {
        print('   ❌ Token generation failed: ${data['message']}');
      }
    } else {
      print('   ❌ Request failed with status: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('   ❌ Error: $e');
  }

  print('');
  print('🎯 Next Steps:');
  print('   1. Run app in debug mode: flutter run -v');
  print('   2. Join frequency 450');
  print('   3. Watch console logs for LiveKit connection messages');
  print('   4. Look for: "🔊 [LiveKit] ✅ Receiving audio from:"');
  print('');
}
