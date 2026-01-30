import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/admin/data/models/admin_guardian_model.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';

class AdminGuardianRepository {
  final AuthRepository _authRepository;

  AdminGuardianRepository(this._authRepository);

  Future<List<AdminGuardian>> getGuardians({
    int page = 1,
    String status = 'all',
    String? searchQuery,
  }) async {
    final token = await _authRepository.getToken();
    if (token == null) throw Exception('Not authenticated');

    final queryParams = {
      'page': page.toString(),
      'employment_status': status,
    };
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/admin/guardians')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = json['data'] as List;
      return data.map((e) => AdminGuardian.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load guardians: ${response.statusCode}');
    }
  }
}
