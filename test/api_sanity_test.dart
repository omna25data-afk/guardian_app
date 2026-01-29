// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  // Use 127.0.0.1 for local testing on Windows (Host)
  // Use http://10.0.2.2:8000 if running inside Android Emulator
  const String baseUrl = 'http://127.0.0.1:8000/api';
  
  // Credentials from Seeder
  const String directorEmail = 'director@example.com';
  const String guardianEmail = 'guardian@example.com'; 
  const String password = 'password';

  String? directorToken;
  String? guardianToken;

  group('API Sanity Checks', () {
    
    // 1. Director Login Test
    test('Director Login should return 200 and Token', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'login_identifier': directorEmail,
          'password': password,
        }),
      );

      print('Director Login Response: ${response.body}');
      expect(response.statusCode, 200);

      final data = jsonDecode(response.body);
      expect(data['status'], true);
      expect(data['token'], isNotNull);
      
      directorToken = data['token'];
      
      // Verify Role
      final user = data['user'];
      final roleNames = user['role_names'] as List;
      expect(roleNames.contains('director'), true, reason: 'User should have director role');
    });

    // 2. Guardian Login Test
    test('Guardian Login should return 200 and Token', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'login_identifier': guardianEmail,
          'password': password,
        }),
      );

      print('Guardian Login Response: ${response.body}');
      expect(response.statusCode, 200);

      final data = jsonDecode(response.body);
      expect(data['status'], true);
      expect(data['token'], isNotNull);
      
      guardianToken = data['token'];

      // Verify Role
      final user = data['user'];
      final roleNames = user['role_names'] as List;
      expect(roleNames.contains('guardian'), true);
    });

    // 3. Authenticated Data Fetch (Guardian Dashboard)
    test('Fetch Guardian Dashboard Data', () async {
      expect(guardianToken, isNotNull, reason: 'Guardian Token is required');

      final response = await http.get(
        Uri.parse('$baseUrl/guardian/dashboard-stats'),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'Authorization': 'Bearer $guardianToken'
        },
      );

      print('Dashboard Response: ${response.body}');
      expect(response.statusCode, 200);
      
      final data = jsonDecode(response.body);
      // Depending on API structure, adjust expectations
      // Assuming it returns stats object
      expect(data, isNotNull);
    });

    // 4. Authenticated Data Fetch (Record Books)
    test('Fetch Record Books', () async {
      expect(guardianToken, isNotNull, reason: 'Guardian Token is required');

      final response = await http.get(
        Uri.parse('$baseUrl/record-books'),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'Authorization': 'Bearer $guardianToken'
        },
      );

      print('Record Books Response: ${response.body}');
      expect(response.statusCode, 200);
      
      final data = jsonDecode(response.body);
      expect(data['data'], isA<List>());
    });

    // 5. Admin (Director) Dashboard Stats Check
    test('Fetch Admin Dashboard Real Stats', () async {
      expect(directorToken, isNotNull, reason: 'Director Token is required');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'Authorization': 'Bearer $directorToken'
        },
      );

      print('Admin Dashboard Response: ${response.body}');
      expect(response.statusCode, 200);
      
      final data = jsonDecode(response.body);
      expect(data['stats'], isNotNull);
      expect(data['stats']['guardians'], isNotNull);
      expect(data['urgent_actions'], isA<List>());
    });

  });
}
