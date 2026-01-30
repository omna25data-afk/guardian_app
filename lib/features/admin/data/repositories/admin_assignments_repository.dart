import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guardian_app/features/admin/data/models/admin_assignment_model.dart';
import 'package:guardian_app/main_common.dart';

class AdminAssignmentsRepository {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AdminAssignmentsRepository({required this.baseUrl});

  Future<List<AdminAssignment>> getAssignments({
    int page = 1, 
    String? searchQuery,
    String? status,
    String? type,
  }) async {
    final token = await _storage.read(key: 'auth_token');
    
    Map<String, String> queryParams = {
      'page': page.toString(),
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }
    if (status != null && status != 'all') {
      queryParams['status'] = status;
    }
    if (type != null && type != 'all') {
      queryParams['type'] = type;
    }

    final uri = Uri.parse('$baseUrl/api/admin/assignments').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['data'];
        return items.map((json) => AdminAssignment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load assignments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching assignments: $e');
    }
  }
}
