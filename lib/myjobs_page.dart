import 'package:flutter/material.dart';
import 'dart:io';
import 'home_page.dart';
import 'addjob_page.dart';
import 'job_status_page.dart';
import 'job_detail_hiring_page.dart';
import 'job_tracking_page.dart';
import 'category_page.dart';
import 'chat_page.dart';
import 'pages/profile_page.dart';
import 'services/job_api_service.dart';
import 'services/auth_service.dart';
import 'job_detail_page.dart';

class MyJobsPage extends StatefulWidget {
  const MyJobsPage({super.key});

  @override
  State<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends State<MyJobsPage> {
  int? currentUserId;

  Future<List<JobItem>>? _futureMyHiringJobs;
  Future<List<JobItem>>? _futureMyAcceptedJobs;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (!mounted) return;
      setState(() {
        currentUserId = userId;
        _futureMyHiringJobs = JobApiService.getMyHiringJobs(userId);
        _futureMyAcceptedJobs = JobApiService.getMyAcceptedJobs(userId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _futureMyHiringJobs = Future.error('ไม่พบผู้ใช้ที่ล็อกอิน');
        _futureMyAcceptedJobs = Future.error('ไม่พบผู้ใช้ที่ล็อกอิน');
      });
    }
  }

  Future<void> _reloadJobs() async {
    await _loadJobs();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'งานของฉัน',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Color(0xFF00E676),
            labelColor: Color(0xFF00E676),
            unselectedLabelColor: Colors.black54,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'งานที่ฉันจ้าง'),
              Tab(text: 'งานที่ฉันรับ'),
            ],
          ),
        ),
        body: (_futureMyHiringJobs == null || _futureMyAcceptedJobs == null)
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  FutureBuilder<List<JobItem>>(
                    future: _futureMyHiringJobs,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'โหลดงานที่ฉันจ้างไม่สำเร็จ\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final jobs = snapshot.data ?? [];

                      if (jobs.isEmpty) {
                        return _buildEmptyState('ยังไม่มีงานที่จ้าง');
                      }

                      return RefreshIndicator(
                        onRefresh: _reloadJobs,
                        child: _buildHiringJobTabContent(context, jobs),
                      );
                    },
                  ),
                  FutureBuilder<List<JobItem>>(
                    future: _futureMyAcceptedJobs,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'โหลดงานที่ฉันรับไม่สำเร็จ\n${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      final jobs = snapshot.data ?? [];

                      if (jobs.isEmpty) {
                        return _buildEmptyState('ยังไม่มีงานที่รับ');
                      }

                      return RefreshIndicator(
                        onRefresh: _reloadJobs,
                        child: _buildAcceptedJobTabContent(context, jobs),
                      );
                    },
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF00E676),
          child: const Icon(Icons.add, color: Colors.white, size: 35),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddJobPage()),
            );

            if (result == true) {
              await _reloadJobs();
            }
          },
        ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHiringJobTabContent(BuildContext context, List<JobItem> jobs) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return _buildHiringJobCard(context, jobs[index]);
      },
    );
  }

  Widget _buildAcceptedJobTabContent(BuildContext context, List<JobItem> jobs) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        return _buildAcceptedJobCard(context, jobs[index]);
      },
    );
  }

  Widget _buildHiringJobCard(BuildContext context, JobItem job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '฿${job.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _statusColor(job.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'สถานะ: ${_statusText(job.status, job.paymentStatus)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 140,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => job.paymentStatus == 'paid'
                              ? JobDetailHiringPage(job: job.toUiMap())
                              : JobStatusPage(job: job.toUiMap()),
                        ),
                      );

                      if (result == true) {
                        await _reloadJobs();
                      }
                    },
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildJobImage(job.imageUrl),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedJobCard(BuildContext context, JobItem job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '฿${job.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _statusColor(job.status),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'สถานะ: ${_statusText(job.status, job.paymentStatus)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: 140,
                  height: 38,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => job.paymentStatus == 'paid'
                              ? JobAcceptedDetailPage(job: job)
                              : JobDetailPage(job: job),
                        ),
                      );
                    },
                    child: const Text(
                      'ดูรายละเอียด',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildJobImage(job.imageUrl),
          ),
        ],
      ),
    );
  }

  String _statusText(String status, String paymentStatus) {
    if (paymentStatus == 'paid') {
      return 'กำลังดำเนินการ';
    }

    switch (status) {
      case 'open':
        return 'กำลังรับสมัคร';
      case 'pending':
        return 'รอดำเนินการ';
      case 'closed':
        return 'ปิดงานแล้ว';
      default:
        return 'รอดำเนินการ';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String? _normalizeImageUrl(String? imgPath) {
    if (imgPath == null || imgPath.trim().isEmpty) return null;

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

    return null;
  }

  Widget _buildJobImage(String? imgPath) {
    final normalizedUrl = _normalizeImageUrl(imgPath);

    if (normalizedUrl != null) {
      return Image.network(
        normalizedUrl,
        width: 85,
        height: 85,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
      );
    }

    if (imgPath != null && imgPath.isNotEmpty) {
      final file = File(imgPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 85,
          height: 85,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
        );
      }
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 85,
      height: 85,
      color: Colors.grey[100],
      child: Icon(Icons.image_outlined, color: Colors.grey[300]),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            context,
            Icons.home_filled,
            'หน้าหลัก',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          _navItem(
            context,
            Icons.grid_view_outlined,
            'หมวดหมู่',
            false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
            },
          ),
          _navItem(context, Icons.assignment, 'งานของฉัน', true, onTap: () {}),
          _navItem(
            context,
            Icons.chat_bubble_outline,
            'ข้อความ',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
            },
          ),
          _navItem(
            context,
            Icons.person_outline,
            'โปรไฟล์',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
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
            const SizedBox(height: 5),
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
