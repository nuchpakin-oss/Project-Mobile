import 'package:flutter/material.dart';
import 'services/job_api_service.dart';

class WorkerProfilePage extends StatefulWidget {
  final JobApplicantItem applicant;

  const WorkerProfilePage({
    super.key,
    required this.applicant,
  });

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  late Future<WorkerProfileResponse> _futureProfile;
  late Future<WorkerReviewsResponse> _futureReviews;

  @override
  void initState() {
    super.initState();
    _futureProfile = JobApiService.getWorkerProfile(widget.applicant.workerUserId);
    _futureReviews = JobApiService.getWorkerReviews(widget.applicant.workerUserId);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> skills = widget.applicant.skills
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'โปรไฟล์ผู้สมัคร',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<WorkerProfileResponse>(
        future: _futureProfile,
        builder: (context, profileSnapshot) {
          final profile = profileSnapshot.data;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFFE8F5E9),
                        backgroundImage: (profile?.img.isNotEmpty == true)
                            ? NetworkImage(profile!.img)
                            : (widget.applicant.img.isNotEmpty
                                  ? NetworkImage(widget.applicant.img)
                                  : null),
                        child: (profile?.img.isNotEmpty == true ||
                                widget.applicant.img.isNotEmpty)
                            ? null
                            : Text(
                                widget.applicant.name.isNotEmpty
                                    ? widget.applicant.name.characters.first
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00E676),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile?.name.isNotEmpty == true
                            ? profile!.name
                            : widget.applicant.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile?.jobTitle.isNotEmpty == true
                            ? profile!.jobTitle
                            : (widget.applicant.jobTitle.isNotEmpty
                                  ? widget.applicant.jobTitle
                                  : 'ไม่ระบุตำแหน่ง/อาชีพ'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusText(widget.applicant.status),
                          style: const TextStyle(
                            color: Color(0xFF00A63E),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<WorkerReviewsResponse>(
                        future: _futureReviews,
                        builder: (context, reviewSnapshot) {
                          final ratingAvg = reviewSnapshot.data?.ratingAvg ?? profile?.ratingAvg ?? 0;
                          final reviewCount = reviewSnapshot.data?.reviewCount ?? profile?.ratingCount ?? 0;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFB300),
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${ratingAvg.toStringAsFixed(1)} ($reviewCount รีวิว)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'เกี่ยวกับผู้สมัคร',
                  child: Text(
                    profile?.desc.isNotEmpty == true
                        ? profile!.desc
                        : (widget.applicant.desc.isNotEmpty
                              ? widget.applicant.desc
                              : 'ไม่มีคำอธิบาย'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF374151),
                      height: 1.6,
                    ),
                  ),
                ),
                _sectionCard(
                  title: 'ทักษะและความเชี่ยวชาญ',
                  child: skills.isEmpty
                      ? const Text(
                          'ไม่มีข้อมูลทักษะ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: skills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFCDEFD6),
                                ),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: Color(0xFF166534),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                _sectionCard(
                  title: 'ข้อมูลติดต่อ',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(
                        Icons.email_outlined,
                        profile?.email.isNotEmpty == true
                            ? profile!.email
                            : (widget.applicant.email.isNotEmpty
                                  ? widget.applicant.email
                                  : 'ไม่ระบุอีเมล'),
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        Icons.phone_outlined,
                        profile?.phone.isNotEmpty == true
                            ? profile!.phone
                            : (widget.applicant.phone.isNotEmpty
                                  ? widget.applicant.phone
                                  : 'ไม่ระบุเบอร์โทร'),
                      ),
                    ],
                  ),
                ),
                FutureBuilder<WorkerReviewsResponse>(
                  future: _futureReviews,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _sectionCard(
                        title: 'รีวิวจากลูกค้า',
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return _sectionCard(
                        title: 'รีวิวจากลูกค้า',
                        child: const Text(
                          'โหลดรีวิวไม่สำเร็จ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    }

                    final reviews = snapshot.data?.reviews ?? [];

                    if (reviews.isEmpty) {
                      return _sectionCard(
                        title: 'รีวิวจากลูกค้า',
                        child: const Text(
                          'ยังไม่มีรีวิว',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    }

                    return _sectionCard(
                      title: 'รีวิวจากลูกค้า',
                      child: Column(
                        children: reviews.map((review) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFE8F5E9),
                                      backgroundImage: review.reviewerImg.isNotEmpty
                                          ? NetworkImage(review.reviewerImg)
                                          : null,
                                      child: review.reviewerImg.isEmpty
                                          ? Text(
                                              review.reviewerName.isNotEmpty
                                                  ? review.reviewerName.characters.first
                                                  : '?',
                                              style: const TextStyle(
                                                color: Color(0xFF00E676),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            review.reviewerName.isNotEmpty
                                                ? review.reviewerName
                                                : 'ผู้ใช้งาน',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            review.jobTitle.isNotEmpty
                                                ? review.jobTitle
                                                : 'งานบริการ',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < review.rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: const Color(0xFFFFB300),
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  review.reviewText.isNotEmpty
                                      ? review.reviewText
                                      : '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF374151),
                                    height: 1.5,
                                  ),
                                ),
                                if (review.tipAmount > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'ทิป: ${review.tipAmount.toStringAsFixed(0)} บาท',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF00A63E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _statusText(String status) {
    switch (status) {
      case 'hired':
        return 'ถูกจ้างแล้ว';
      case 'rejected':
        return 'ถูกปฏิเสธ';
      case 'backup':
        return 'รายชื่อสำรอง';
      default:
        return 'สมัครแล้ว';
    }
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B7280), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ],
    );
  }
}