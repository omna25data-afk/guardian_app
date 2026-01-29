import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:guardian_mobile_app/core/constants/api_constants.dart';
import 'dart:convert';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final _storage = const FlutterSecureStorage();
  String _log = "Ready to test...";
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _log += "\n\n$message";
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _log = "Starting Test...";
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      _addLog("Token found: ${token != null ? 'YES (${token.substring(0, 10)}...)' : 'NO'}");

      if (token == null) {
        _isLoading = false;
        return;
      }

      // Test 1: User Endpoint
      _addLog("--- Testing /user ---");
      final userUrl = Uri.parse(ApiConstants.user); // Assuming this exists or construct it
      final userResponse = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      _addLog("Status: ${userResponse.statusCode}");
      _addLog("Body: ${userResponse.body}");

      // Test 2: Record Books Endpoint
      _addLog("--- Testing /record-books ---");
      final booksResponse = await http.get(
        ApiConstants.recordBooks,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      _addLog("Status: ${booksResponse.statusCode}");
      _addLog("Body: ${booksResponse.body}");

    } catch (e) {
      _addLog("ERROR: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connection Debugger")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check),
              label: const Text("Run Connection Test"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log,
                  style: const TextStyle(
                      color: Colors.greenAccent, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
