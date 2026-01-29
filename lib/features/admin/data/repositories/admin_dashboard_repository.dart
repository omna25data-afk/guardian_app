import 'package:guardian_app/core/constants/api_constants.dart';
import 'package:guardian_app/features/auth/data/repositories/auth_repository.dart';
import 'package:guardian_app/features/admin/data/models/admin_dashboard_data.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboardRepository {
  final AuthRepository _authRepository;

  AdminDashboardRepository(this._authRepository);

  Future<AdminDashboardData> getDashboardData() async {
    final token = await _authRepository.getToken();
    
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/admin/dashboard'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return AdminDashboardData.fromJson(json);
    } else {
      throw Exception('Failed to load admin dashboard: ${response.statusCode}');
    }
  }
}
