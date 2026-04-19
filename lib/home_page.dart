import 'package:flutter/material.dart';
import 'dart:io';
import 'addjob_page.dart';
import 'myjobs_page.dart';
import 'job_detail_page.dart';
import 'job_status_page.dart';
import 'category_page.dart';
import 'chat_page.dart';
import '../pages/announcement_list_page.dart';
import '../pages/profile_page.dart';
import '../services/job_api_service.dart';
import '../services/auth_service.dart';
import '../services/announcement_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  late Future<List<JobItem>> _futureJobs;

  static List<Map<String, String>> acceptedJobList = [];

  int? currentUserId;
  int _announcementCount = 0;

  @override
  void initState() {
    super.initState();
    _futureJobs = JobApiService.getJobs();
    _loadCurrentUser();
    _loadAnnouncementsCount();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (!mounted) return;
      setState(() {
        currentUserId = userId;
      });
    } catch (_) {}
  }

  Future<void> _loadAnnouncementsCount() async {
    try {
      final items = await AnnouncementService.getAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcementCount = items.length;
      });
    } catch (_) {}
  }

  Future<void> _reloadJobs() async {
    setState(() {
      _futureJobs = JobApiService.getJobs();
    });
    await _loadAnnouncementsCount();
  }

  bool _shouldShowOnHome(JobItem job) {
    final bool isHired = job.assignedWorkerId != null;
    final bool isPaid = job.paymentStatus == 'paid';
    final bool isClosed = job.status == 'closed';
    final bool isPending = job.status == 'pending';

    return !isHired && !isPaid && !isClosed && !isPending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Local Job Hub',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnnouncementListPage(),
                    ),
                  );
                  await _loadAnnouncementsCount();
                },
              ),
              if (_announcementCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _announcementCount > 99
                          ? '99+'
                          : _announcementCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: FutureBuilder<List<JobItem>>(
              future: _futureJobs,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'โหลดงานไม่สำเร็จ\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final allJobs = snapshot.data ?? [];
                final jobList = allJobs.where(_shouldShowOnHome).toList();

                if (jobList.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _reloadJobs,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: jobList.length,
                    itemBuilder: (context, index) {
                      return _buildJobItem(jobList[index]);
                    },
                  ),
                );
              },
            ),
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
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('ยังไม่มีงานที่ลงประกาศ'));
  }

  Widget _buildFilterSection() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip('ใกล้ฉัน', true),
          _filterChip('งานด่วน', false),
          _filterChip('ยอดนิยม', false),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Chip(
        label: Text(label),
        backgroundColor: selected ? const Color(0xFF00E676) : Colors.grey[100],
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _buildJobItem(JobItem job) {
    return GestureDetector(
      onTap: () {
        final bool isMyOwnJob =
            currentUserId != null && job.userId == currentUserId;

        if (isMyOwnJob) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobStatusPage(job: job.toUiMap()),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => JobDetailPage(job: job)),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImageWidget(job.imageUrl),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '฿${job.budget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildImageWidget(String? imgPath) {
    final normalizedUrl = _normalizeImageUrl(imgPath);

    if (normalizedUrl != null) {
      return Image.network(
        normalizedUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image, color: Colors.grey, size: 30),
      );
    }

    if (imgPath != null && imgPath.isNotEmpty) {
      final file = File(imgPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image, color: Colors.grey),
        );
      }
    }

    return const Icon(Icons.image, color: Colors.grey, size: 30);
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home_filled, 'หน้าหลัก', true, onTap: () {}),
          _navItem(
            context,
            Icons.grid_view_outlined,
            'หมวดหมู่',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
            },
          ),
          _navItem(
            context,
            Icons.assignment_outlined,
            'งานของฉัน',
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyJobsPage()),
              );
            },
          ),
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
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
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
