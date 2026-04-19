import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  // static const String baseUrl = 'http://localhost:3000/api/users';
  static const String baseUrl = 'http://192.168.1.162:3000/api/users';


  static Future<List<dynamic>> getUsers({
    String search = '',
    String status = 'all',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse(baseUrl).replace(
      queryParameters: {
        'search': search,
        'status': status,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      throw Exception('รูปแบบข้อมูลผู้ใช้ไม่ถูกต้อง');
    }

    throw Exception(
      'โหลดผู้ใช้ไม่สำเร็จ (${response.statusCode}) ${response.body}',
    );
  }

  static Future<void> updateUserStatus({
    required String id,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.patch(
      Uri.parse('$baseUrl/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'อัปเดตสถานะผู้ใช้ไม่สำเร็จ (${response.statusCode}) ${response.body}',
      );
    }
  }

  static Future<void> deleteUser(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'ลบผู้ใช้ไม่สำเร็จ (${response.statusCode}) ${response.body}',
      );
    }
  }
}