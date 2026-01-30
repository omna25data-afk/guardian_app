import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:guardian_app/features/admin/data/models/admin_area_model.dart';
import 'package:guardian_app/main_common.dart';

class AdminAreasRepository {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AdminAreasRepository({required this.baseUrl});

  Future<List<AdminArea>> getAreas({int page = 1, String? searchQuery}) async {
    final token = await _storage.read(key: 'auth_token');
    
    // Construct query parameters
    Map<String, String> queryParams = {
      'page': page.toString(),
    };
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }

    final uri = Uri.parse('$baseUrl/api/admin/areas').replace(queryParameters: queryParams);

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
        return items.map((json) => AdminArea.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load areas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching areas: $e');
    }
  }
}
