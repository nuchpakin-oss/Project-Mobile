import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AppConfig {
  // static const String baseUrl = 'http://localhost:3000/api';
  static const String baseUrl = 'http://192.168.1.162:3000/api';
}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

bool _toBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v == 1;
  final t = v.toString().toLowerCase();
  return t == '1' || t == 'true';
}

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? bio;
  final String? jobTitle;
  final double rating;
  final int totalJobs;
  final bool isVerified;
  final String? profileImageUrl;
  final List<String> skills;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.bio,
    this.jobTitle,
    required this.rating,
    required this.totalJobs,
    required this.isVerified,
    this.profileImageUrl,
    required this.skills,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<String> parsedSkills = [];
    final raw = json['skills'];

    if (raw is List) {
      parsedSkills = raw.map((e) => e.toString()).toList();
    } else if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        parsedSkills = decoded is List
            ? decoded.map((e) => e.toString()).toList()
            : raw
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
      } catch (_) {
        parsedSkills = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    return UserProfile(
      id: _toInt(json['id']),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      bio: json['bio']?.toString(),
      jobTitle: json['job_title']?.toString(),
      rating: _toDouble(json['rating']),
      totalJobs: _toInt(json['total_jobs']),
      isVerified: _toBool(json['is_verified']),
      profileImageUrl: json['profile_image_url']?.toString(),
      skills: parsedSkills,
    );
  }
}

class PortfolioItem {
  final int id;
  final int? userId;
  final String? userName;
  final String description;
  final String? tags;
  final String? imageUrl;
  final String verifyStatus;

  PortfolioItem({
    required this.id,
    this.userId,
    this.userName,
    required this.description,
    this.tags,
    this.imageUrl,
    required this.verifyStatus,
  });

  factory PortfolioItem.fromJson(Map<String, dynamic> json) {
    return PortfolioItem(
      id: _toInt(json['id']),
      userId: json['user_id'] == null ? null : _toInt(json['user_id']),
      userName: json['user_name']?.toString(),
      description: json['description']?.toString() ?? '',
      tags: json['tags']?.toString(),
      imageUrl: json['image_url']?.toString(),
      verifyStatus: json['verify_status']?.toString() ?? 'pending',
    );
  }
}

class EarningItem {
  final int id;
  final int? userId;
  final double amount;
  final String? title;
  final String? description;
  final String? workDate;
  final String status;

  EarningItem({
    required this.id,
    this.userId,
    required this.amount,
    this.title,
    this.description,
    this.workDate,
    required this.status,
  });

  factory EarningItem.fromJson(Map<String, dynamic> json) {
    return EarningItem(
      id: _toInt(json['id']),
      userId: json['user_id'] == null ? null : _toInt(json['user_id']),
      amount: _toDouble(json['amount']),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      workDate: json['work_date']?.toString(),
      status: json['status']?.toString() ?? 'paid',
    );
  }
}

class EarningsSummary {
  final double totalMonth;
  final double previousMonth;
  final double availableBalance;
  final List<EarningItem> recentItems;

  EarningsSummary({
    required this.totalMonth,
    required this.previousMonth,
    required this.availableBalance,
    required this.recentItems,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    final items = (json['recent_items'] as List? ?? [])
        .map((e) => EarningItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return EarningsSummary(
      totalMonth: _toDouble(json['total_month']),
      previousMonth: _toDouble(json['previous_month']),
      availableBalance: _toDouble(json['available_balance']),
      recentItems: items,
    );
  }

  double get changePercent {
    if (previousMonth == 0) return 0;
    return ((totalMonth - previousMonth) / previousMonth) * 100;
  }
}

class WithdrawalResult {
  final int id;
  final int userId;
  final double amount;
  final String referenceCode;
  final String status;
  final String note;
  final String transferredAt;
  final String payoutMethod;
  final String payoutName;
  final String payoutAccount;

  WithdrawalResult({
    required this.id,
    required this.userId,
    required this.amount,
    required this.referenceCode,
    required this.status,
    required this.note,
    required this.transferredAt,
    required this.payoutMethod,
    required this.payoutName,
    required this.payoutAccount,
  });

  factory WithdrawalResult.fromJson(Map<String, dynamic> json) {
    return WithdrawalResult(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      amount: _toDouble(json['amount']),
      referenceCode: json['reference_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      transferredAt: json['transferred_at']?.toString() ?? '',
      payoutMethod: json['payout_method']?.toString() ?? '',
      payoutName: json['payout_name']?.toString() ?? '',
      payoutAccount: json['payout_account']?.toString() ?? '',
    );
  }
}

class ProfileApiService {
  static Future<UserProfile> getProfile(int userId) async {
    final res = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/users/$userId/profile'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('โหลดโปรไฟล์ไม่สำเร็จ (${res.statusCode}): ${res.body}');
    }

    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<UserProfile> updateProfile({
    required int userId,
    required String fullName,
    required String email,
    required String phone,
    required String bio,
    required String jobTitle,
    required List<String> skills,
    Uint8List? profileImageBytes,
    String? profileImageFileName,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/users/$userId/profile');
    final request = http.MultipartRequest('PUT', uri);

    request.fields['full_name'] = fullName;
    request.fields['email'] = email;
    request.fields['phone'] = phone;
    request.fields['bio'] = bio;
    request.fields['job_title'] = jobTitle;
    request.fields['skills'] = jsonEncode(skills);

    if (profileImageBytes != null && profileImageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_image',
          profileImageBytes,
          filename: profileImageFileName ?? 'profile.jpg',
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 200) {
      throw Exception(
        'อัปเดตโปรไฟล์ไม่สำเร็จ (${res.statusCode}): ${res.body}',
      );
    }

    return UserProfile.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<List<PortfolioItem>> uploadPortfolios({
    required int userId,
    required List<Uint8List> images,
    required List<String> fileNames,
    String description = '',
    String tags = '',
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/users/$userId/portfolios');
    final request = http.MultipartRequest('POST', uri);

    request.fields['description'] = description;
    request.fields['tags'] = tags;

    for (int i = 0; i < images.length; i++) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          images[i],
          filename: i < fileNames.length ? fileNames[i] : 'portfolio_$i.jpg',
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode != 201) {
      throw Exception('อัปโหลดผลงานไม่สำเร็จ (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body) as List;
    return data
        .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<PortfolioItem>> getPortfolios(int userId) async {
    final res = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/users/$userId/portfolios'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('โหลดผลงานไม่สำเร็จ (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body) as List;
    return data
        .map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<EarningsSummary> getEarnings(int userId) async {
    final res = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/users/$userId/earnings'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) {
      throw Exception('โหลดรายได้ไม่สำเร็จ (${res.statusCode}): ${res.body}');
    }

    return EarningsSummary.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  static Future<WithdrawalResult> withdraw(
    int userId, {
    required String payoutMethod,
    required String payoutName,
    required String payoutAccount,
  }) async {
    final res = await http
        .post(
          Uri.parse('${AppConfig.baseUrl}/users/$userId/withdraw'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'payout_method': payoutMethod,
            'payout_name': payoutName,
            'payout_account': payoutAccount,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      return WithdrawalResult.fromJson(
        Map<String, dynamic>.from(data['withdrawal']),
      );
    } else {
      throw Exception(data['message'] ?? 'ถอนเงินไม่สำเร็จ');
    }
  }
}
