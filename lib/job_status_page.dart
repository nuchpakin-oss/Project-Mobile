import 'package:flutter/material.dart';
import 'applicants_page.dart';
import 'job_detail_hiring_page.dart';
import 'services/job_api_service.dart';

class JobStatusPage extends StatefulWidget {
  final Map<String, dynamic> job;

  const JobStatusPage({super.key, required this.job});

  @override
  State<JobStatusPage> createState() => _JobStatusPageState();
}

class _JobStatusPageState extends State<JobStatusPage> {
  late Future<JobItem> _futureJob;

  @override
  void initState() {
    super.initState();
    final jobId = int.tryParse(widget.job['id']?.toString() ?? '') ?? 0;
    _futureJob = JobApiService.getJobById(jobId);
  }

  Future<void> _cancelJob(BuildContext context, int jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ยืนยันการยกเลิกงาน'),
          content: const Text('คุณต้องการยกเลิกงานนี้ใช่หรือไม่'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ไม่'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('ยืนยัน'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await JobApiService.cancelJob(jobId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยกเลิกงานสำเร็จ'),
          backgroundColor: Color(0xFF00E676),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ยกเลิกงานไม่สำเร็จ: $e')));
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
    return FutureBuilder<JobItem>(
      future: _futureJob,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('โหลดข้อมูลงานไม่สำเร็จ')),
          );
        }

        final jobItem = snapshot.data!;
        final uiJob = jobItem.toUiMap();

        if (jobItem.paymentStatus == 'paid') {
          return JobDetailHiringPage(job: uiJob);
        }

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
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.black),
                onPressed: () {},
              ),
            ],
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  _normalizeImageUrl(uiJob['img']?.toString()),
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
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
                      _buildHeaderSection(uiJob),
                      const SizedBox(height: 25),
                      _buildInfoTile(
                        Icons.location_on_outlined,
                        'สถานที่ปฏิบัติงาน',
                        uiJob['location'] ?? 'ไม่ระบุสถานที่',
                      ),
                      const SizedBox(height: 15),
                      _buildInfoTile(
                        Icons.calendar_today_outlined,
                        'วันที่ทำงาน',
                        uiJob['date'] ?? 'ไม่ระบุวันเวลา',
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
                        uiJob['desc'] ?? 'ไม่มีรายละเอียดเพิ่มเติม',
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildActionButtons(context, jobItem.id),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                job['title'] ?? 'ไม่มีชื่อประกาศ',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _badge(
              job['status'] ?? 'กำลังรับสมัคร',
              const Color(0xFFE8F5E9),
              const Color(0xFF00E676),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          job['price'] != null ? '${job['price']}' : 'ไม่ระบุราคา',
          style: const TextStyle(
            fontSize: 26,
            color: Color(0xFF00E676),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, int jobId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ApplicantsPage(jobId: jobId),
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
              'ดูผู้สมัครทั้งหมด',
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
            onPressed: () => _cancelJob(context, jobId),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'ยกเลิกงาน',
              style: TextStyle(
                color: Colors.redAccent,
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
          child: Icon(icon, size: 24, color: const Color(0xFF64748B)),
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
}
