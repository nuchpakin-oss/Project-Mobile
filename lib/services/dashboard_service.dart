import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardService {
  // static const String baseUrl = 'http://localhost:3000/api/dashboard';
  static const String baseUrl = 'http://192.168.1.162:3000/api/dashboard';

  static Future<Map<String, dynamic>> _getJson(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'โหลด Dashboard ไม่สำเร็จ (${response.statusCode}) ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> getOverview() async {
    return _getJson('overview');
  }

  static Future<List<dynamic>> getActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/activities'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      throw Exception('รูปแบบ Activities ไม่ถูกต้อง');
    } else {
      throw Exception(
        'โหลด Activities ไม่สำเร็จ (${response.statusCode}) ${response.body}',
      );
    }
  }

  static Future<Map<String, dynamic>> getCharts() async {
    return _getJson('charts');
  }
}