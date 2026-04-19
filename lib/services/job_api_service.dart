import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class JobApiService {
  // static const String baseUrl = 'http://localhost:3000/api';
  // Android Emulator:
  static const String baseUrl = 'http://192.168.1.162:3000/api';

  static Future<JobApplicantsResponse> getApplicants(int jobId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/$jobId/applicants'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดผู้สมัครไม่สำเร็จ: ${response.body}');
    }

    return JobApplicantsResponse.fromJson(jsonDecode(response.body));
  }

  static Future<SubmitReviewResponse> submitWorkerReview({
    required int jobId,
    required int workerUserId,
    required int reviewerUserId,
    required int rating,
    required String reviewText,
    double tipAmount = 0,
    String imageUrl = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/review'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'worker_user_id': workerUserId,
        'reviewer_user_id': reviewerUserId,
        'rating': rating,
        'review_text': reviewText,
        'image_url': imageUrl,
        'tip_amount': tipAmount,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('ส่งรีวิวไม่สำเร็จ: ${response.body}');
    }

    return SubmitReviewResponse.fromJson(jsonDecode(response.body));
  }

  static Future<WorkerReviewsResponse> getWorkerReviews(
    int workerUserId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workers/$workerUserId/reviews'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดรีวิวไม่สำเร็จ: ${response.body}');
    }

    return WorkerReviewsResponse.fromJson(jsonDecode(response.body));
  }

  static Future<WorkerProfileResponse> getWorkerProfile(
    int workerUserId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/workers/$workerUserId/profile'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดโปรไฟล์ช่างไม่สำเร็จ: ${response.body}');
    }

    return WorkerProfileResponse.fromJson(jsonDecode(response.body));
  }

  static Future<List<JobStatusUpdateItem>> getJobStatusUpdates(
    int jobId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/$jobId/status-updates'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลด timeline ไม่สำเร็จ: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => JobStatusUpdateItem.fromJson(e)).toList();
  }

  static Future<void> postJobStatusUpdate({
    required int jobId,
    required int workerUserId,
    required String updateType,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/status-updates'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'worker_user_id': workerUserId,
        'update_type': updateType,
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('อัปเดตงานไม่สำเร็จ: ${response.body}');
    }
  }

  static Future<void> markJobComplete({
    required int jobId,
    required int workerUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'worker_user_id': workerUserId}),
    );

    if (response.statusCode != 200) {
      throw Exception('เปลี่ยนสถานะงานไม่สำเร็จ: ${response.body}');
    }
  }

  static Future<void> confirmJobComplete(int jobId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/customer-confirm'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('ยืนยันงานไม่สำเร็จ: ${response.body}');
    }
  }

  static Future<JobApplicantItem> getHiredWorker(int jobId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/$jobId/hired-worker'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดข้อมูลผู้รับจ้างไม่สำเร็จ: ${response.body}');
    }

    return JobApplicantItem.fromJson(jsonDecode(response.body));
  }

  static Future<PaymentSummaryResponse> getPaymentSummary({
    required int jobId,
    required int workerUserId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/$jobId/payment-summary/$workerUserId'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดข้อมูลการชำระเงินไม่สำเร็จ: ${response.body}');
    }

    return PaymentSummaryResponse.fromJson(jsonDecode(response.body));
  }

  static Future<PaymentRecord> payNow({
    required int jobId,
    required int workerUserId,
    required double amount,
    String paymentMethod = 'manual',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/pay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'worker_user_id': workerUserId,
        'amount': amount,
        'payment_method': paymentMethod,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('ชำระเงินไม่สำเร็จ: ${response.body}');
    }

    return PaymentRecord.fromJson(jsonDecode(response.body));
  }

  static Future<JobItem> hireApplicant({
    required int jobId,
    required int applicantId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/hire/$applicantId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('จ้างผู้สมัครไม่สำเร็จ: ${response.body}');
    }

    return JobItem.fromJson(jsonDecode(response.body));
  }

  static Future<void> cancelJob(int jobId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/jobs/$jobId/cancel'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('ยกเลิกงานไม่สำเร็จ: ${response.body}');
    }
  }

  static Future<List<JobItem>> getJobs() async {
    final response = await http.get(Uri.parse('$baseUrl/jobs'));

    if (response.statusCode != 200) {
      throw Exception('โหลดงานไม่สำเร็จ: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => JobItem.fromJson(e)).toList();
  }

  static Future<JobItem> getJobById(int jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/jobs/$jobId'));

    if (response.statusCode != 200) {
      throw Exception('โหลดรายละเอียดงานไม่สำเร็จ: ${response.body}');
    }

    return JobItem.fromJson(jsonDecode(response.body));
  }

  static Future<void> submitJobReport({
    required int jobId,
    required int reporterUserId,
    required int reportedUserId,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/report');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'job_id': jobId,
        'reporter_user_id': reporterUserId,
        'reported_user_id': reportedUserId,
        'reason': message,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('ส่งรายงานไม่สำเร็จ: ${response.body}');
    }
  }

  // แก้เฉพาะ method createJob ใน job_api_service.dart
  // เพิ่ม latitude และ longitude parameter

  static Future<JobItem> createJob({
    required int userId,
    required String title,
    required String category,
    required String description,
    required String budget,
    required String location,
    required String workDate,
    required String workTime,
    Uint8List? imageBytes,
    String? imageFileName,
    double? latitude, // ← เพิ่ม
    double? longitude, // ← เพิ่ม
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/jobs'));

    request.fields['user_id'] = userId.toString();
    request.fields['title'] = title;
    request.fields['category'] = category;
    request.fields['description'] = description;
    request.fields['budget'] = budget;
    request.fields['location'] = location;
    request.fields['work_date'] = workDate;
    request.fields['work_time'] = workTime;

    // ส่ง lat/lng ถ้ามี
    if (latitude != null) request.fields['latitude'] = latitude.toString();
    if (longitude != null) request.fields['longitude'] = longitude.toString();

    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFileName ?? 'job.jpg',
        ),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 201) {
      throw Exception('สร้างงานไม่สำเร็จ: ${response.body}');
    }

    return JobItem.fromJson(jsonDecode(response.body));
  }

  static Future<List<JobItem>> getMyHiringJobs(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/user/$userId/hiring'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดงานที่ฉันจ้างไม่สำเร็จ: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => JobItem.fromJson(e)).toList();
  }

  static Future<List<JobItem>> getMyAcceptedJobs(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/jobs/user/$userId/accepted'),
    );

    if (response.statusCode != 200) {
      throw Exception('โหลดงานที่ฉันรับไม่สำเร็จ: ${response.body}');
    }

    final data = jsonDecode(response.body) as List;
    return data.map((e) => JobItem.fromJson(e)).toList();
  }

  static Future<JobItem> applyJob({
    required int jobId,
    required int workerUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/jobs/$jobId/apply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'worker_user_id': workerUserId}),
    );

    if (response.statusCode != 200) {
      throw Exception('สมัครงานไม่สำเร็จ: ${response.body}');
    }

    return JobItem.fromJson(jsonDecode(response.body));
  }
}

class JobItem {
  final int id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final double budget;
  final String location;
  final String workDate;
  final String workTime;
  final String status;
  final String paymentStatus;
  final int? userId;
  final int? assignedWorkerId;

  // Optional employer-related fields (used by JobAcceptedDetailPage)
  final String? employerAvatarUrl;
  final String? employerName;
  final double? employerRating;
  final int? employerReviewCount;

  JobItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.budget,
    required this.location,
    required this.workDate,
    required this.workTime,
    required this.status,
    required this.paymentStatus,
    required this.userId,
    required this.assignedWorkerId,
    this.employerAvatarUrl,
    this.employerName,
    this.employerRating,
    this.employerReviewCount,
  });

  factory JobItem.fromJson(Map<String, dynamic> json) {
    // try multiple keys for employer avatar (backend may vary)
    String? avatar;
    if (json['employer_avatar_url'] != null) {
      avatar = json['employer_avatar_url'].toString();
    } else if (json['employer_avatar'] != null) {
      avatar = json['employer_avatar'].toString();
    } else if (json['employer_img'] != null) {
      avatar = json['employer_img'].toString();
    }
    if (avatar != null && avatar.isEmpty) avatar = null;

    final String? empName =
        json['employer_name']?.toString() ?? json['employer']?.toString();

    final double? empRating = json['employer_rating'] == null
        ? null
        : _toDouble(json['employer_rating']);

    final int? empReviewCount = json['employer_review_count'] == null
        ? null
        : _toInt(json['employer_review_count']);

    return JobItem(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      budget: _toDouble(json['budget']),
      location: json['location']?.toString() ?? '',
      workDate: json['work_date']?.toString() ?? '',
      workTime: json['work_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      userId: json['user_id'] == null ? null : _toInt(json['user_id']),
      assignedWorkerId: json['assigned_worker_id'] == null
          ? null
          : _toInt(json['assigned_worker_id']),
      employerAvatarUrl: avatar,
      employerName: empName,
      employerRating: empRating,
      employerReviewCount: empReviewCount,
    );
  }

  Map<String, String> toUiMap() {
    return {
      'id': id.toString(),
      'title': title,
      'price': '฿${budget.toStringAsFixed(0)}',
      'desc': description,
      'img': imageUrl,
      'cate': category,
      'dist': '',
      'location': location,
      'date': workDate.isNotEmpty || workTime.isNotEmpty
          ? '$workDate ${workTime.isNotEmpty ? '| $workTime' : ''}'.trim()
          : '',
      'status': status,
      'payment_status': paymentStatus,
    };
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

class JobApplicantItem {
  final int id;
  final int jobId;
  final int workerUserId;
  final String status;
  final String name;
  final String email;
  final String phone;
  final String img;
  final String jobTitle;
  final String desc;
  final String skills;

  JobApplicantItem({
    required this.id,
    required this.jobId,
    required this.workerUserId,
    required this.status,
    required this.name,
    required this.email,
    required this.phone,
    required this.img,
    required this.jobTitle,
    required this.desc,
    required this.skills,
  });

  factory JobApplicantItem.fromJson(Map<String, dynamic> json) {
    return JobApplicantItem(
      id: _toInt(json['id']),
      jobId: _toInt(json['job_id']),
      workerUserId: _toInt(json['worker_user_id']),
      status: json['status']?.toString() ?? 'applied',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      img: json['img']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      skills: json['skills']?.toString() ?? '',
    );
  }
}

class JobApplicantsResponse {
  final JobItem job;
  final List<JobApplicantItem> applicants;

  JobApplicantsResponse({required this.job, required this.applicants});

  factory JobApplicantsResponse.fromJson(Map<String, dynamic> json) {
    final applicantsJson = (json['applicants'] as List?) ?? [];

    return JobApplicantsResponse(
      job: JobItem.fromJson(Map<String, dynamic>.from(json['job'])),
      applicants: applicantsJson
          .map((e) => JobApplicantItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class PaymentWorkerInfo {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String img;
  final String jobTitle;
  final String desc;
  final String skills;

  PaymentWorkerInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.img,
    required this.jobTitle,
    required this.desc,
    required this.skills,
  });

  factory PaymentWorkerInfo.fromJson(Map<String, dynamic> json) {
    return PaymentWorkerInfo(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      img: json['img']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      skills: json['skills']?.toString() ?? '',
    );
  }
}

class PaymentRecord {
  final int id;
  final int jobId;
  final int workerUserId;
  final double amount;
  final String status;
  final String paymentMethod;
  final String paidAt;

  PaymentRecord({
    required this.id,
    required this.jobId,
    required this.workerUserId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.paidAt,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: _toInt(json['id']),
      jobId: _toInt(json['job_id']),
      workerUserId: _toInt(json['worker_user_id']),
      amount: _toDouble(json['amount']),
      status: json['status']?.toString() ?? 'pending',
      paymentMethod: json['payment_method']?.toString() ?? 'manual',
      paidAt: json['paid_at']?.toString() ?? '',
    );
  }
}

class PaymentSummaryResponse {
  final JobItem job;
  final PaymentWorkerInfo worker;
  final PaymentRecord? payment;

  PaymentSummaryResponse({
    required this.job,
    required this.worker,
    required this.payment,
  });

  factory PaymentSummaryResponse.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryResponse(
      job: JobItem.fromJson(Map<String, dynamic>.from(json['job'])),
      worker: PaymentWorkerInfo.fromJson(
        Map<String, dynamic>.from(json['worker']),
      ),
      payment: json['payment'] == null
          ? null
          : PaymentRecord.fromJson(Map<String, dynamic>.from(json['payment'])),
    );
  }
}

class JobStatusUpdateItem {
  final int id;
  final int jobId;
  final int workerUserId;
  final String updateType;
  final String message;
  final String createdAt;
  final String workerName;
  final String workerImg;

  JobStatusUpdateItem({
    required this.id,
    required this.jobId,
    required this.workerUserId,
    required this.updateType,
    required this.message,
    required this.createdAt,
    required this.workerName,
    required this.workerImg,
  });

  factory JobStatusUpdateItem.fromJson(Map<String, dynamic> json) {
    return JobStatusUpdateItem(
      id: _toInt(json['id']),
      jobId: _toInt(json['job_id']),
      workerUserId: _toInt(json['worker_user_id']),
      updateType: json['update_type']?.toString() ?? 'note',
      message: json['message']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      workerName: json['worker_name']?.toString() ?? '',
      workerImg: json['worker_img']?.toString() ?? '',
    );
  }
}

class WorkerReviewItem {
  final int id;
  final int jobId;
  final int workerUserId;
  final int reviewerUserId;
  final int rating;
  final String reviewText;
  final String imageUrl;
  final double tipAmount;
  final String createdAt;
  final String jobTitle;
  final String reviewerName;
  final String reviewerImg;

  WorkerReviewItem({
    required this.id,
    required this.jobId,
    required this.workerUserId,
    required this.reviewerUserId,
    required this.rating,
    required this.reviewText,
    required this.imageUrl,
    required this.tipAmount,
    required this.createdAt,
    required this.jobTitle,
    required this.reviewerName,
    required this.reviewerImg,
  });

  factory WorkerReviewItem.fromJson(Map<String, dynamic> json) {
    return WorkerReviewItem(
      id: _toInt(json['id']),
      jobId: _toInt(json['job_id']),
      workerUserId: _toInt(json['worker_user_id']),
      reviewerUserId: _toInt(json['reviewer_user_id']),
      rating: _toInt(json['rating']),
      reviewText: json['review_text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      tipAmount: _toDouble(json['tip_amount']),
      createdAt: json['created_at']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      reviewerName: json['reviewer_name']?.toString() ?? '',
      reviewerImg: json['reviewer_img']?.toString() ?? '',
    );
  }
}

class WorkerReviewsResponse {
  final double ratingAvg;
  final int reviewCount;
  final List<WorkerReviewItem> reviews;

  WorkerReviewsResponse({
    required this.ratingAvg,
    required this.reviewCount,
    required this.reviews,
  });

  factory WorkerReviewsResponse.fromJson(Map<String, dynamic> json) {
    final summary = Map<String, dynamic>.from(json['summary'] ?? {});
    final reviewsJson = (json['reviews'] as List?) ?? [];

    return WorkerReviewsResponse(
      ratingAvg: _toDouble(summary['rating_avg']),
      reviewCount: _toInt(summary['review_count']),
      reviews: reviewsJson
          .map((e) => WorkerReviewItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SubmitReviewResponse {
  final int id;
  final int jobId;
  final int workerUserId;
  final int reviewerUserId;
  final int rating;
  final String reviewText;
  final String imageUrl;
  final double tipAmount;
  final String createdAt;
  final double ratingAvg;
  final int ratingCount;

  SubmitReviewResponse({
    required this.id,
    required this.jobId,
    required this.workerUserId,
    required this.reviewerUserId,
    required this.rating,
    required this.reviewText,
    required this.imageUrl,
    required this.tipAmount,
    required this.createdAt,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory SubmitReviewResponse.fromJson(Map<String, dynamic> json) {
    return SubmitReviewResponse(
      id: _toInt(json['id']),
      jobId: _toInt(json['job_id']),
      workerUserId: _toInt(json['worker_user_id']),
      reviewerUserId: _toInt(json['reviewer_user_id']),
      rating: _toInt(json['rating']),
      reviewText: json['review_text']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      tipAmount: _toDouble(json['tip_amount']),
      createdAt: json['created_at']?.toString() ?? '',
      ratingAvg: _toDouble(json['rating_avg']),
      ratingCount: _toInt(json['rating_count']),
    );
  }
}

class WorkerProfileResponse {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String img;
  final String jobTitle;
  final String desc;
  final String skills;
  final double ratingAvg;
  final int ratingCount;

  WorkerProfileResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.img,
    required this.jobTitle,
    required this.desc,
    required this.skills,
    required this.ratingAvg,
    required this.ratingCount,
  });

  factory WorkerProfileResponse.fromJson(Map<String, dynamic> json) {
    return WorkerProfileResponse(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      img: json['img']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      skills: json['skills']?.toString() ?? '',
      ratingAvg: _toDouble(json['rating_avg']),
      ratingCount: _toInt(json['rating_count']),
    );
  }
}
