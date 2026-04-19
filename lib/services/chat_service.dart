import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnnouncementService {
  // static const String baseUrl = 'http://localhost:3000/api/announcements';
  static const String baseUrl = 'http://192.168.1.162:3000/api/announcements';

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      throw Exception('รูปแบบข้อมูลประกาศไม่ถูกต้อง');
    } else {
      throw Exception(data['message'] ?? 'โหลดประกาศไม่สำเร็จ');
    }
  }

  static Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String content,
    required String targetGroup,
    String? imageUrl,
  }) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'content': content,
        'target_group': targetGroup,
        'image_url': imageUrl,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'สร้างประกาศไม่สำเร็จ');
    }
  }

  static Future<void> deleteAnnouncement(int id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'ลบประกาศไม่สำเร็จ');
    }
  }
}