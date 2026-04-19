import 'package:flutter/material.dart';
import 'services/job_api_service.dart';
import 'home_page.dart';
import 'category_page.dart';
import 'myjobs_page.dart';
import 'chat_page.dart';
import 'pages/profile_page.dart';

class JobAcceptedDetailPage extends StatefulWidget {
  final JobItem job;

  const JobAcceptedDetailPage({super.key, required this.job});

  @override
  State<JobAcceptedDetailPage> createState() => _JobAcceptedDetailPageState();
}

class _JobAcceptedDetailPageState extends State<JobAcceptedDetailPage> {
  static const Color _green = Color(0xFF00E676);
  static const Color _darkNavy = Color(0xFF1A1A2E);

  bool _isCompleting = false;
  bool _isUpdating = false;
  bool _isReporting = false;
  late bool _canReportAfterSubmit;
  Future<WorkerProfileResponse>? _futureEmployerProfile;

  @override
  void initState() {
    super.initState();
    if (widget.job.userId != null) {
      _futureEmployerProfile = JobApiService.getWorkerProfile(widget.job.userId!);
    }

    _canReportAfterSubmit = [
      'waiting_review',
      'completed',
      'closed',
    ].contains(widget.job.status);
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, job),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleRow(job),
                        const SizedBox(height: 6),
                        _buildPrice(job),
                        const SizedBox(height: 20),
                        _buildInfoCard(job),
                        const SizedBox(height: 20),
                        _buildDescriptionSection(job),
                        const SizedBox(height: 20),
                        _buildEmployerCard(job),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomActions(context),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, JobItem job) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: _darkNavy, size: 22),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _shareJob(job),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.share_outlined, color: _darkNavy, size: 20),
            ),
          ),
        ),
      ],
      title: const Text(
        'รายละเอียดงาน',
        style: TextStyle(
          color: _darkNavy,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(background: _buildHeroImage(job)),
    );
  }

  Widget _buildHeroImage(JobItem job) {
    if (job.imageUrl.startsWith('http')) {
      return Image.network(
        job.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF4DB6AC),
      child: const Center(
        child: Icon(Icons.ac_unit_rounded, size: 64, color: Colors.white54),
      ),
    );
  }

  Widget _buildTitleRow(JobItem job) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            job.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _darkNavy,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildStatusBadge(job.status),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color bg;
    Color textColor;

    switch (status) {
      case 'open':
        label = 'กำลังรับสมัคร';
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'pending':
      case 'in_progress':
      case 'waiting_review':
        label = 'จ้างงานแล้ว';
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'closed':
      case 'completed':
        label = 'ปิดงานแล้ว';
        bg = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF757575);
        break;
      default:
        label = 'จ้างงานแล้ว';
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPrice(JobItem job) {
    return Text(
      '${job.budget.toStringAsFixed(0)} บาท',
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: _green,
      ),
    );
  }

  Widget _buildInfoCard(JobItem job) {
    return Column(
      children: [
        _buildInfoRow(
          icon: Icons.location_on_outlined,
          title: 'สถานที่ปฏิบัติงาน',
          subtitle: job.location,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.calendar_today_outlined,
          title: 'วันที่ทำงาน',
          subtitle: job.workDate.isNotEmpty ? job.workDate : '-',
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF555555)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _darkNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF757575)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(JobItem job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายละเอียดงาน',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _darkNavy,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          job.description.isNotEmpty ? job.description : 'ไม่มีรายละเอียดเพิ่มเติม',
          style: const TextStyle(
            fontSize: 14,
            height: 1.65,
            color: Color(0xFF444444),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployerCard(JobItem job) {
    return FutureBuilder<WorkerProfileResponse>(
      future: _futureEmployerProfile,
      builder: (context, snapshot) {
        final employer = snapshot.data;

        final employerName =
            employer?.name.isNotEmpty == true ? employer!.name : 'ผู้จ้างงาน';
        final employerImg = employer?.img ?? '';
        final employerRating = employer?.ratingAvg ?? 0;
        final employerReviewCount = employer?.ratingCount ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: employerImg.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          employerImg,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_outline,
                            color: Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _darkNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${employerRating.toStringAsFixed(1)} ($employerReviewCount รีวิว)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _goToChat(job),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: _green,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'คุยกับผู้จ้าง',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: (_isCompleting || _canReportAfterSubmit)
                ? null
                : () => _confirmComplete(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: (_isCompleting || _canReportAfterSubmit)
                    ? _green.withOpacity(0.7)
                    : _green,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _green.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _isCompleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _canReportAfterSubmit ? 'ส่งงานแล้ว' : 'งานเสร็จสิ้น',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _isUpdating ? null : () => _showUpdateSheet(context),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.sync_rounded, color: Color(0xFF555555), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'อัปเดตงาน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF444444),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_canReportAfterSubmit) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _isReporting ? null : () => _showReportDialog(context),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Center(
                  child: _isReporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.report_problem_outlined,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'รายงานปัญหา',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmComplete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF00E676),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'ยืนยันงานเสร็จสิ้น',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: const Text(
          'คุณแน่ใจว่างานเสร็จสมบูรณ์แล้วใช่ไหม?\nหลังจากนี้ระบบจะรอลูกค้ายืนยัน',
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF555555)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() => _isCompleting = true);

                    try {
                      await JobApiService.markJobComplete(
                        jobId: widget.job.id,
                        workerUserId: widget.job.assignedWorkerId ?? 0,
                      );

                      if (!mounted) return;
                      setState(() {
                        _isCompleting = false;
                        _canReportAfterSubmit = true;
                      });
                      _showSnack('งานเสร็จสิ้นแล้ว รอลูกค้ายืนยัน', _green);
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isCompleting = false);
                      _showSnack('เปลี่ยนสถานะงานไม่สำเร็จ', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                  ),
                  child: const Text(
                    'ยืนยัน',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateSheet(BuildContext context) {
    String selectedType = 'in_progress';
    final controller = TextEditingController();

    final quickOptions = <Map<String, String>>[
      {'type': 'traveling', 'label': 'กำลังเดินทาง', 'message': 'กำลังเดินทางไปหน้างาน'},
      {'type': 'arrived', 'label': 'ถึงหน้างานแล้ว', 'message': 'ถึงหน้างานแล้ว'},
      {'type': 'started', 'label': 'เริ่มงานแล้ว', 'message': 'เริ่มดำเนินงานแล้ว'},
      {'type': 'in_progress', 'label': 'กำลังดำเนินงาน', 'message': 'กำลังดำเนินงานอยู่'},
      {'type': 'almost_done', 'label': 'ใกล้เสร็จแล้ว', 'message': 'งานใกล้เสร็จแล้ว'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'อัปเดตสถานะงาน',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickOptions.map((item) {
                    final selected = selectedType == item['type'];
                    return ChoiceChip(
                      label: Text(item['label']!),
                      selected: selected,
                      onSelected: (_) {
                        setSheetState(() {
                          selectedType = item['type']!;
                          controller.text = item['message']!;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'เพิ่มหมายเหตุเพิ่มเติม',
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final message = controller.text.trim();
                      if (message.isEmpty) return;

                      Navigator.pop(context);
                      setState(() => _isUpdating = true);

                      try {
                        await JobApiService.postJobStatusUpdate(
                          jobId: widget.job.id,
                          workerUserId: widget.job.assignedWorkerId ?? 0,
                          updateType: selectedType,
                          message: message,
                        );

                        if (!mounted) return;
                        setState(() => _isUpdating = false);
                        _showSnack('อัปเดตสถานะสำเร็จ ✓', _green);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _isUpdating = false);
                        _showSnack('อัปเดตสถานะไม่สำเร็จ', Colors.red);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                    ),
                    child: const Text(
                      'ส่งอัปเดต',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'รายงานปัญหา',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'กรอกรายละเอียดปัญหาที่ต้องการรายงาน',
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final message = controller.text.trim();
                    if (message.isEmpty) return;

                    Navigator.pop(context);
                    setState(() => _isReporting = true);

                    try {
                      await JobApiService.submitJobReport(
                        jobId: widget.job.id,
                        reporterUserId: widget.job.assignedWorkerId ?? 0,
                        reportedUserId: widget.job.userId ?? 0,
                        message: message,
                      );

                      if (!mounted) return;
                      setState(() => _isReporting = false);
                      _showSnack('ส่งรายงานสำเร็จ', Colors.red);
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isReporting = false);
                      _showSnack('ส่งรายงานไม่สำเร็จ', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text(
                    'ส่งรายงาน',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToChat(JobItem job) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatPage()),
    );
  }

  void _shareJob(JobItem job) {
    _showSnack('คัดลอกลิงก์งานแล้ว', const Color(0xFF1565C0));
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 72,
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
              MaterialPageRoute(builder: (_) => const HomePage()),
            ),
          ),
          _navItem(
            context,
            Icons.grid_view_outlined,
            'หมวดหมู่',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            ),
          ),
          _navItem(
            context,
            Icons.work_outline_rounded,
            'งานของฉัน',
            true,
            onTap: () {},
          ),
          _navItem(
            context,
            Icons.chat_bubble_outline,
            'แชท',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChatPage()),
            ),
          ),
          _navItem(
            context,
            Icons.person_outline,
            'โปรไฟล์',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
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
    final color = isSelected ? _green : const Color(0xFF94A3B8);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
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