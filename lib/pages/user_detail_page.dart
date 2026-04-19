import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'dashboard_admin_page.dart';
import 'verify_admin_page.dart';
import 'chat_list_admin_page.dart';

// ─────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────

enum UserStatus { active, pending, suspended }

class UserItem {
  final String id;
  final String name;
  final String email;
  final String registeredDate;
  final UserStatus status;
  final String? avatarUrl;
  final bool isOnline;
  final String? phone;
  final double? rating;
  final int? totalJobs;
  final bool isVerified;
  final String? bio;

  const UserItem({
    required this.id,
    required this.name,
    required this.email,
    required this.registeredDate,
    required this.status,
    this.avatarUrl,
    this.isOnline = false,
    this.phone,
    this.rating,
    this.totalJobs,
    this.isVerified = false,
    this.bio,
  });
}

// ─────────────────────────────────────────────
// USER DETAIL PAGE
// ─────────────────────────────────────────────

class UserDetailPage extends StatefulWidget {
  final UserItem user;
  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  static const Color _green    = Color(0xFF00C853);
  static const Color _darkNavy = Color(0xFF1A1A2E);
  static const Color _grey     = Color(0xFF757575);
  static const Color _lightGrey = Color(0xFFF5F7FA);
  static const Color _danger   = Color(0xFFE53935);
  static const Color _warning  = Color(0xFFF57C00);

  late UserStatus _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.user.status;
  }

  /// แปลง ISO / raw date → dd/MM/yyyy
  String _formatDate(String raw) {
    // ตัด prefix "สมัครเมื่อ " ออกก่อน
    final cleaned = raw.replaceAll('สมัครเมื่อ ', '').trim();
    try {
      final dt = DateTime.parse(cleaned).toLocal();
      final d  = dt.day.toString().padLeft(2, '0');
      final m  = dt.month.toString().padLeft(2, '0');
      return '$d/$m/${dt.year}';
    } catch (_) {
      return cleaned; // ถ้า parse ไม่ได้ คืนค่าเดิม
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 16),
                    _buildInfoGrid(),
                    const SizedBox(height: 16),
                    _buildBioSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── APP BAR ─────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_activity_outlined, color: _green, size: 22),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              children: [
                TextSpan(text: 'Local Job Hub ', style: TextStyle(color: _darkNavy)),
                TextSpan(text: 'Admin',          style: TextStyle(color: _green)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROFILE CARD ────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _lightGrey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: _darkNavy),
                ),
              ),
              const Spacer(),
              const Text('รายละเอียดผู้ใช้งาน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _darkNavy)),
              const Spacer(),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 24),

          Stack(
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB2DFDB), Color(0xFF80CBC4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: widget.user.avatarUrl != null
                    ? ClipOval(child: Image.network(widget.user.avatarUrl!, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                          widget.user.name.isNotEmpty ? widget.user.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
              ),
              Positioned(
                bottom: 4, right: 4,
                child: Container(
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color: widget.user.isOnline ? _green : const Color(0xFFBDBDBD),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(widget.user.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _darkNavy)),
          const SizedBox(height: 4),
          Text(widget.user.email,
              style: const TextStyle(fontSize: 13, color: _grey)),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statusBadge(_currentStatus),
              if (widget.user.isVerified) ...[
                const SizedBox(width: 8),
                _verifiedBadge(),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── INFO GRID ───────────────────────────────

  Widget _buildInfoGrid() {
    final displayDate = _formatDate(widget.user.registeredDate);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _infoCell(label: 'วันที่เข้าร่วม', value: displayDate)),
              _divV(),
              Expanded(child: _infoCell(label: 'งานทั้งหมด', value: '${widget.user.totalJobs ?? 0} งาน')),
            ],
          ),
          _divH(),
          Row(
            children: [
              Expanded(child: _infoCell(label: 'คะแนนรีวิว', value: widget.user.rating?.toStringAsFixed(1) ?? '0.0', showStar: true)),
              _divV(),
              Expanded(child: _infoCell(label: 'เบอร์โทรศัพท์', value: widget.user.phone ?? '-')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCell({required String label, required String value, bool showStar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(child: Text(value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _darkNavy))),
              if (showStar) ...[
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _divV() => Container(width: 1, height: 80, color: const Color(0xFFF0F0F0));
  Widget _divH() => Container(height: 1, color: const Color(0xFFF0F0F0));

  // ─── BIO ─────────────────────────────────────

  Widget _buildBioSection() {
    final bio = (widget.user.bio == null || widget.user.bio!.trim().isEmpty)
        ? 'ผู้ใช้นี้ยังไม่ได้เพิ่มประวัติการใช้งานเบื้องต้น'
        : widget.user.bio!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ประวัติการใช้งานเบื้องต้น',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _darkNavy)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _lightGrey, borderRadius: BorderRadius.circular(12)),
            child: Text(bio, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444))),
          ),
        ],
      ),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────

  Widget _buildActionButtons() {
    final isSuspended = _currentStatus == UserStatus.suspended;
    return Column(
      children: [
        // Suspend / Unsuspend
        GestureDetector(
          onTap: _isLoading ? null : _toggleSuspend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              color: _isLoading ? const Color(0xFFBDBDBD) : (isSuspended ? _green : _warning),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (isSuspended ? _green : _warning).withOpacity(_isLoading ? 0 : 0.35),
                  blurRadius: 12, offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(child: SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isSuspended ? Icons.check_circle_outline_rounded : Icons.block_outlined,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(isSuspended ? 'ปลดระงับการใช้งาน' : 'ระงับการใช้งาน',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete
        GestureDetector(
          onTap: _isLoading ? null : _confirmDelete,
          child: Container(
            width: double.infinity, height: 52,
            decoration: BoxDecoration(
              color: _isLoading ? const Color(0xFFBDBDBD) : _danger,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _danger.withOpacity(_isLoading ? 0 : 0.35), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('ลบบัญชีผู้ใช้', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── BADGES ──────────────────────────────────

  Widget _statusBadge(UserStatus status) {
    late String label; late Color bg; late Color tc;
    switch (status) {
      case UserStatus.active:
        label = 'ใช้งานอยู่'; bg = const Color(0xFFE8F5E9); tc = const Color(0xFF2E7D32); break;
      case UserStatus.pending:
        label = 'รอตรวจสอบ'; bg = const Color(0xFFFFF9C4); tc = const Color(0xFFF57F17); break;
      case UserStatus.suspended:
        label = 'ระงับการใช้งาน'; bg = const Color(0xFFFFEBEE); tc = const Color(0xFFE53935); break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: tc)),
    );
  }

  Widget _verifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.verified_outlined, size: 13, color: Color(0xFF1565C0)),
        SizedBox(width: 4),
        Text('ยืนยันตัวตนแล้ว',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1565C0))),
      ]),
    );
  }

  // ─── ACTIONS (API จริง) ──────────────────────

  /// ✅ เรียก API PATCH /users/:id/status แล้วส่ง result กลับ UsersPage
  Future<void> _toggleSuspend() async {
    final isSuspended = _currentStatus == UserStatus.suspended;
    final newStatus   = isSuspended ? 'active' : 'suspended';

    setState(() => _isLoading = true);
    try {
      await UserService.updateUserStatus(id: widget.user.id, status: newStatus);

      if (!mounted) return;
      setState(() {
        _currentStatus = isSuspended ? UserStatus.active : UserStatus.suspended;
        _isLoading     = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isSuspended ? 'ปลดระงับ "${widget.user.name}" แล้ว' : 'ระงับ "${widget.user.name}" แล้ว',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isSuspended ? _green : _warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));

      // ✅ pop พร้อม result → UsersPage จะ reload
      Navigator.of(context).pop({'action': 'status_changed', 'id': widget.user.id, 'status': newStatus});
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 22),
          SizedBox(width: 8),
          Text('ยืนยันการลบ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
            children: [
              const TextSpan(text: 'คุณต้องการลบบัญชี '),
              TextSpan(text: '"${widget.user.name}"',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _darkNavy)),
              const TextSpan(text: ' ใช่หรือไม่?\n\nการกระทำนี้ไม่สามารถย้อนกลับได้'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ยกเลิก', style: TextStyle(color: _grey, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  try {
                    await UserService.deleteUser(widget.user.id);
                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('ลบ "${widget.user.name}" แล้ว',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      backgroundColor: _danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.all(16),
                    ));

                    Navigator.of(context).pop({'action': 'deleted', 'id': widget.user.id});
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    _showError(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _danger,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ลบบัญชี', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: _danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ─── BOTTOM NAV ──────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 2,
      onTap: (index) {
        if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardAdminPage()));
        if (index == 1) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerifyPage()));
        if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _green,
      unselectedItemColor: const Color(0xFF9E9E9E),
      backgroundColor: Colors.white,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded),    label: 'แดชบอร์ด'),
        BottomNavigationBarItem(icon: Icon(Icons.shield_outlined),      label: 'ตรวจสอบ'),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined),       label: 'ผู้ใช้'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline),  label: 'แชท'),
      ],
    );
  }
}