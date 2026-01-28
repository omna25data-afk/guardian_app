import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_app/models/dashboard_data.dart';
import 'package:guardian_app/models/record_book.dart';
import 'package:guardian_app/models/registry_entry.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GuardianRepository {
  final String _baseUrl = "https://your-domain.com/api";
  final _secureStorage = const FlutterSecureStorage();

  Future<String?> _getAuthToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  Future<Map<String, String>> _getJsonHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<DashboardData> getDashboard() async {
    final url = Uri.parse('$_baseUrl/dashboard');
    final headers = await _getJsonHeaders();
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return DashboardData.fromJson(data);
      } else {
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  Future<List<RecordBook>> getRecordBooks() async {
    final url = Uri.parse('$_baseUrl/record-books');
    final headers = await _getJsonHeaders();
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        // FIXED: Parse the nested list from the 'data' or 'date' key
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> data = decoded['data'] ?? decoded['date'] ?? []; // Check for 'data', then 'date', then default to empty list
        return data.map((json) => RecordBook.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load record books: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load record books: $e');
    }
  }
  
  Future<List<RegistryEntry>> getRegistryEntries({String? status, String? searchQuery}) async {
    var queryParams = {
      'status': status,
      'search': searchQuery,
    };
    queryParams.removeWhere((key, value) => value == null);
    
    final url = Uri.parse('$_baseUrl/registry-entries').replace(queryParameters: queryParams);
    final headers = await _getJsonHeaders();

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        // FIXED: Proactively parse the nested list from the 'data' key
        final Map<String, dynamic> decoded = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> data = decoded['data'] ?? [];
        return data.map((json) => RegistryEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load registry entries: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load registry entries: $e');
    }
  }

  Future<RegistryEntry> createEntry(Map<String, String> entryData) async {
    final url = Uri.parse('$_baseUrl/registry-entries');
    final token = await _getAuthToken();
    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.post(url, headers: headers, body: entryData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        // The response for a create might be nested under a 'data' key as well
        final entryJson = data['data'] ?? data;
        return RegistryEntry.fromJson(entryJson);
      } else {
        throw Exception('Failed to create entry: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create entry: $e');
    }
  }
}
