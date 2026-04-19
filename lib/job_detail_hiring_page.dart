import 'package:flutter/material.dart';
import 'home_page.dart';
import 'category_page.dart';
import 'myjobs_page.dart';
import 'worker_profile_page.dart';
import 'job_progress_page.dart';
import 'services/job_api_service.dart';

class JobDetailHiringPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobDetailHiringPage({super.key, required this.job});

  @override
  State<JobDetailHiringPage> createState() => _JobDetailHiringPageState();
}

class _JobDetailHiringPageState extends State<JobDetailHiringPage> {
  late Future<JobApplicantItem?> _futureHiredWorker;
  Future<WorkerProfileResponse>? _futureWorkerProfile;

  @override
  void initState() {
    super.initState();
    _futureHiredWorker = _loadHiredWorker();
  }

  Future<JobApplicantItem?> _loadHiredWorker() async {
    final jobId = int.tryParse(widget.job['id']?.toString() ?? '');
    if (jobId == null) return null;

    try {
      final worker = await JobApiService.getHiredWorker(jobId);
      _futureWorkerProfile = JobApiService.getWorkerProfile(
        worker.workerUserId,
      );
      return worker;
    } catch (_) {
      return null;
    }
  }

  String _normalizeImageUrl(String? imgPath) {
    if (imgPath == null || imgPath.trim().isEmpty) {
      return 'https://picsum.photos/id/119/600/300';
    }

    final raw = imgPath.trim();

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    if (raw.startsWith('/uploads/')) {
      return 'http://192.168.1.162:3000$raw';
    }

    if (raw.startsWith('uploads/')) {
      return 'http://192.168.1.162:3000/$raw';
    }

    return 'http://picsum.photos/id/119/600/300';
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'รายละเอียดงาน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
      ),
      body: FutureBuilder<JobApplicantItem?>(
        future: _futureHiredWorker,
        builder: (context, snapshot) {
          final hiredWorker = snapshot.data;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  _normalizeImageUrl(job['img']?.toString()),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 250,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 50),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(job),
                      const SizedBox(height: 25),
                      _buildInfoTile(
                        Icons.location_on_outlined,
                        'สถานที่ปฏิบัติงาน',
                        job['location'] ?? 'ไม่ระบุสถานที่',
                      ),
                      const SizedBox(height: 15),
                      _buildInfoTile(
                        Icons.calendar_today_outlined,
                        'วันที่ทำงาน',
                        job['date'] ?? 'ไม่ระบุวันเวลา',
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'รายละเอียดงาน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        job['desc'] ??
                            job['description'] ??
                            'ไม่มีรายละเอียดงานเพิ่มเติม',
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildWorkerCard(context, hiredWorker, snapshot),
                      const SizedBox(height: 30),
                      _buildActionButtons(context, hiredWorker),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeaderSection(Map<String, dynamic> job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                job['title'] ?? 'ไม่มีชื่องาน',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _badge(
              job['status'] ?? 'จ้างงานแล้ว',
              const Color(0xFFE8F5E9),
              const Color(0xFF00E676),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          job['price'] != null && job['price'].toString().contains('฿')
              ? '${job['price']}'
              : '${job['price'] ?? '0'} บาท',
          style: const TextStyle(
            fontSize: 26,
            color: Color(0xFF00E676),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerCard(
    BuildContext context,
    JobApplicantItem? hiredWorker,
    AsyncSnapshot<JobApplicantItem?> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (hiredWorker == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'ยังไม่มีข้อมูลผู้รับจ้าง',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return FutureBuilder<WorkerProfileResponse>(
      future: _futureWorkerProfile,
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final ratingAvg = profile?.ratingAvg ?? 0;
        final ratingCount = profile?.ratingCount ?? 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: hiredWorker.img.isNotEmpty
                    ? NetworkImage(hiredWorker.img)
                    : null,
                child: hiredWorker.img.isEmpty
                    ? Text(
                        hiredWorker.name.isNotEmpty
                            ? hiredWorker.name.characters.first
                            : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hiredWorker.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hiredWorker.jobTitle.isNotEmpty
                          ? hiredWorker.jobTitle
                          : 'ไม่ระบุตำแหน่ง',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ratingAvg.toStringAsFixed(1)} ($ratingCount รีวิว)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WorkerProfilePage(applicant: hiredWorker),
                    ),
                  );
                },
                child: const Text(
                  'ดูโปรไฟล์',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    JobApplicantItem? hiredWorker,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: hiredWorker == null
                ? null
                : () {
                    final jobId =
                        int.tryParse(widget.job['id']?.toString() ?? '') ?? 0;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobProgressPage(
                          jobId: jobId,
                          workerUserId: hiredWorker.workerUserId,
                          job: widget.job,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'ดูสถานะ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            onPressed: hiredWorker == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkerProfilePage(applicant: hiredWorker),
                      ),
                    );
                  },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'ดูโปรไฟล์ผู้รับจ้าง',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              sub,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _badge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            context,
            Icons.home_outlined,
            'หน้าหลัก',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            ),
          ),
          _navItem(
            context,
            Icons.grid_view_outlined,
            'หมวดหมู่',
            false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CategoryPage()),
            ),
          ),
          _navItem(
            context,
            Icons.assignment,
            'งานของฉัน',
            true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyJobsPage()),
            ),
          ),
          _navItem(
            context,
            Icons.chat_bubble_outline,
            'ข้อความ',
            false,
            onTap: () {},
          ),
          _navItem(
            context,
            Icons.person_outline,
            'โปรไฟล์',
            false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    final Color color = isSelected
        ? const Color(0xFF00E676)
        : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
