import 'package:flutter/material.dart';
import 'review_page.dart';
import 'home_page.dart';
import 'myjobs_page.dart';
import 'category_page.dart';
import 'pages/profile_page.dart';
import 'chat_page.dart';
import 'services/job_api_service.dart';
import 'services/auth_service.dart';
import 'chat_room_user_page.dart';
import 'voice_call_page.dart';

class JobProgressPage extends StatefulWidget {
  final int jobId;
  final int workerUserId;
  final Map<String, dynamic> job;

  const JobProgressPage({
    super.key,
    required this.jobId,
    required this.workerUserId,
    required this.job,
  });

  @override
  State<JobProgressPage> createState() => _JobProgressPageState();
}

class _JobProgressPageState extends State<JobProgressPage> {
  late Future<PaymentSummaryResponse> _futureSummary;
  late Future<List<JobStatusUpdateItem>> _futureUpdates;
  int? _currentUserId;
  bool _isConfirming = false;
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _futureSummary = JobApiService.getPaymentSummary(
      jobId: widget.jobId,
      workerUserId: widget.workerUserId,
    );
    _futureUpdates = JobApiService.getJobStatusUpdates(widget.jobId);
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final id = await AuthService.getCurrentUserId();
    if (!mounted) return;
    setState(() {
      _currentUserId = id;
    });
  }

  Future<void> _reload() async {
    setState(() {
      _futureSummary = JobApiService.getPaymentSummary(
        jobId: widget.jobId,
        workerUserId: widget.workerUserId,
      );
      _futureUpdates = JobApiService.getJobStatusUpdates(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaymentSummaryResponse>(
      future: _futureSummary,
      builder: (context, summarySnap) {
        if (summarySnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (summarySnap.hasError || !summarySnap.hasData) {
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
                'ความคืบหน้างาน',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
            body: const Center(child: Text('โหลดสถานะงานไม่สำเร็จ')),
          );
        }

        final summary = summarySnap.data!;
        final job = summary.job;
        final worker = summary.worker;
        final isEmployer =
            _currentUserId != null && job.userId == _currentUserId;
        final priceText = summary.payment != null
            ? summary.payment!.amount.toStringAsFixed(2)
            : job.budget.toStringAsFixed(2);

        return FutureBuilder<List<JobStatusUpdateItem>>(
          future: _futureUpdates,
          builder: (context, updateSnap) {
            final updates = updateSnap.data ?? [];

            final jobMap = {
              'id': job.id.toString(),
              'title': job.title,
              'price': '฿$priceText',
              'desc': job.description,
              'img': job.imageUrl,
              'cate': job.category,
              'location': job.location,
              'date': job.workDate.isNotEmpty || job.workTime.isNotEmpty
                  ? '${job.workDate}${job.workTime.isNotEmpty ? ' | ${job.workTime}' : ''}'
                  : '',
              'status': job.status,
              'payment_status': job.paymentStatus,
              'workerUserId': worker.id.toString(),
              'workerName': worker.name,
              'workerImg': worker.img,
            };

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
                  'ความคืบหน้างาน',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.black),
                    onPressed: () {},
                  ),
                ],
                centerTitle: true,
              ),
              body: RefreshIndicator(
                onRefresh: _reload,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildWorkerHeader(worker),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: updates.isEmpty
                            ? Column(
                                children: [
                                  _buildTimelineStep(
                                    title: 'กำลังดำเนินการ',
                                    subtitle: 'ชำระเงินแล้ว',
                                    isCompleted: true,
                                    isLast: false,
                                  ),
                                  _buildTimelineStep(
                                    title: 'รอช่างอัปเดต',
                                    subtitle: 'ยังไม่มีการอัปเดตล่าสุด',
                                    isCompleted: false,
                                    isLast: true,
                                  ),
                                ],
                              )
                            : Column(
                                children: List.generate(updates.length, (
                                  index,
                                ) {
                                  final item = updates[index];
                                  return _buildTimelineStep(
                                    title: _statusTitle(item.updateType),
                                    subtitle: item.message,
                                    isCompleted: true,
                                    isLast: index == updates.length - 1,
                                    showExtraCard: index == updates.length - 1,
                                  );
                                }),
                              ),
                      ),
                      const SizedBox(height: 30),
                      _buildPriceSummary(priceText),
                      const SizedBox(height: 20),

                      if (isEmployer && job.status == 'waiting_review')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isConfirming
                                      ? null
                                      : () async {
                                          setState(() => _isConfirming = true);
                                          try {
                                            await JobApiService.confirmJobComplete(
                                              job.id,
                                            );

                                            if (!mounted) return;
                                            setState(() => _isConfirming = false);

                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ReviewPage(job: jobMap),
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            setState(() => _isConfirming = false);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('ยืนยันงานไม่สำเร็จ'),
                                              ),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00E676),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isConfirming
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'ยืนยันงานและไปรีวิว',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _isReporting
                                      ? null
                                      : () => _showReportDialog(context),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: _isReporting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.red,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'รายงานปัญหา',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildBottomNav(context),
            );
          },
        );
      },
    );
  }

  String _statusTitle(String type) {
    switch (type) {
      case 'traveling':
        return 'กำลังเดินทาง';
      case 'arrived':
        return 'ถึงหน้างานแล้ว';
      case 'started':
        return 'เริ่มงานแล้ว';
      case 'in_progress':
        return 'กำลังดำเนินงาน';
      case 'almost_done':
        return 'ใกล้เสร็จแล้ว';
      case 'waiting_review':
        return 'รอลูกค้ายืนยัน';
      case 'completed':
        return 'ลูกค้ายืนยันแล้ว';
      default:
        return 'อัปเดตงาน';
    }
  }

  Widget _buildWorkerHeader(PaymentWorkerInfo worker) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: worker.img.isNotEmpty
              ? NetworkImage(worker.img)
              : null,
          child: worker.img.isEmpty
              ? Text(worker.name.isNotEmpty
                  ? worker.name.characters.first
                  : '?')
              : null,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                worker.name.isNotEmpty ? worker.name : 'ผู้รับจ้าง',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                '${worker.jobTitle.isNotEmpty ? worker.jobTitle : 'ผู้รับจ้าง'} • ติดต่อ',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),

        /// 📞 ปุ่มโทร
        GestureDetector(
          onTap: () => _startCall(worker),
          child: _circleIconButton(Icons.phone, Colors.green[50]!, Colors.green),
        ),

        const SizedBox(width: 10),

        /// 💬 ปุ่มแชท
        GestureDetector(
          onTap: () => _startChat(worker),
          child: _circleIconButton(
            Icons.chat_bubble_outline,
            Colors.green[50]!,
            Colors.green,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
    bool showExtraCard = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF00E676) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? Colors.transparent
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: showExtraCard ? 130 : 50,
                color: Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.black87 : Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (showExtraCard) ...[
                const SizedBox(height: 10),
                _buildTaskDetailCard(subtitle),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetailCard(String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF00E676), fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('เสร็จสิ้น', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(String priceText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FDF6),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ยอดรวมทั้งหมด',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'ติดตามอัตราค่าบริการรายชั่วโมง',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          Text(
            '\$$priceText',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
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
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'กรอกรายละเอียดปัญหา',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final message = controller.text.trim();
              if (message.isEmpty) return;

              Navigator.pop(context);
              setState(() => _isReporting = true);

              try {
                await JobApiService.submitJobReport(
                  jobId: widget.jobId,
                  reporterUserId: _currentUserId ?? 0,
                  reportedUserId: widget.workerUserId,
                  message: message,
                );

                if (!mounted) return;
                setState(() => _isReporting = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ส่งรายงานสำเร็จ')),
                );
              } catch (e) {
                if (!mounted) return;
                setState(() => _isReporting = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ส่งรายงานไม่สำเร็จ')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ส่งรายงาน'),
          ),
        ],
      ),
    );
  }
  // ===================== 📞 CALL =====================
void _startCall(PaymentWorkerInfo worker) {
  final channelName = 'call_job_${widget.jobId}_${worker.id}';

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VoiceCallPage(
        contactName: worker.name,
        avatarUrl: worker.img,
        channelName: channelName,
        localUid: _currentUserId ?? 0,
      ),
    ),
  );
}

// ===================== 💬 CHAT =====================
Future<void> _startChat(PaymentWorkerInfo worker) async {
  try {
    final conversationId = await ChatApiService.startUserChat(
      otherUserId: worker.id,
      title: 'แชทงาน ${widget.jobId}',
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomUserPage(
          contact: ChatListItem(
            id: conversationId,
            userName: worker.name,
            lastMessage: '',
            unreadCount: 0,
            timeText: '',
            isOnline: true,
            avatarUrl: worker.img,
            type: 'user_user',
          ),
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เริ่มแชทไม่สำเร็จ: $e')),
    );
  }
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
            Icons.home_outlined,
            'หน้าหลัก',
            false,
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
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
          _navItem(
            context,
            Icons.assignment,
            'งาน',
            true,
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
            'แชท',
            false,
            onTap: () {
              Navigator.push(
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
              Navigator.push(
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
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
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