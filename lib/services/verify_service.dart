import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VerifyService {
  static const String baseUrl = 'http://192.168.1.162:3000/api/verify';
  // static const String baseUrl = 'https://192.168.1.162:3000/api/verify';


  static Future<List<dynamic>> getVerifyItems(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/$type'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) return decoded;
      throw Exception('รูปแบบข้อมูล verify ไม่ถูกต้อง');
    }

    throw Exception(
      'โหลดข้อมูลตรวจสอบไม่สำเร็จ (${response.statusCode}) ${response.body}',
    );
  }

  static Future<void> updateStatus({
    required String type,
    required String id,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.patch(
      Uri.parse('$baseUrl/$type/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'อัปเดตสถานะไม่สำเร็จ (${response.statusCode}) ${response.body}',
      );
    }
  }
}