import 'package:flutter/material.dart';
import 'dashboard_admin_page.dart';
import 'users_admin_page.dart';
import 'chat_list_admin_page.dart';
import '../services/verify_service.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

enum VerifyStatus { pending, approved, rejected }
enum VerifyItemType { person, portfolio, company }

class VerifyItem {
  final String id;
  final String badge;
  final String timeAgo;
  final String name;
  final String description;
  final String? idNumber;
  final String? location;
  final String? salary;
  final List<String> tags;
  final String? imageUrl;
  final VerifyItemType type;
  VerifyStatus status;

  VerifyItem({
    required this.id,
    required this.badge,
    required this.timeAgo,
    required this.name,
    required this.description,
    this.idNumber,
    this.location,
    this.salary,
    this.tags = const [],
    this.imageUrl,
    required this.type,
    this.status = VerifyStatus.pending,
  });
}

// ─────────────────────────────────────────────
// VERIFY PAGE
// ─────────────────────────────────────────────

class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF00C853);
  static const Color _red   = Color(0xFFE53935);

  late TabController _tabController;

  List<VerifyItem> _userItems      = [];
  List<VerifyItem> _portfolioItems = [];
  List<VerifyItem> _jobItems       = [];

  bool _isLoading = true;
  String? _errorMessage;

  // ── จำนวน pending แต่ละ tab (ใช้แสดงใน tab label) ──
  int get _userPending      => _userItems.where((e)      => e.status == VerifyStatus.pending).length;
  int get _portfolioPending => _portfolioItems.where((e) => e.status == VerifyStatus.pending).length;
  int get _jobPending       => _jobItems.where((e)       => e.status == VerifyStatus.pending).length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final users      = await VerifyService.getVerifyItems('users');
      final portfolios = await VerifyService.getVerifyItems('portfolios');
      final jobs       = await VerifyService.getVerifyItems('jobs');

      setState(() {
        _userItems      = users.map(_mapVerifyItem).toList();
        _portfolioItems = portfolios.map(_mapVerifyItem).toList();
        _jobItems       = jobs.map(_mapVerifyItem).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  VerifyItem _mapVerifyItem(dynamic json) {
    return VerifyItem(
      id:          json['id'].toString(),
      badge:       json['badge'] ?? 'PENDING',
      timeAgo:     '${json['timeAgo'] ?? ''}',
      name:        json['name'] ?? '',
      description: json['description'] ?? '',
      idNumber:    json['idNumber'],
      location:    json['location'],
      salary:      json['salary'],
      tags:        (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl:    json['imageUrl'],
      type:        _mapType(json['type']),
      status:      _mapStatus(json['status']),
    );
  }

  VerifyItemType _mapType(String? type) {
    switch (type) {
      case 'portfolio': return VerifyItemType.portfolio;
      case 'company':   return VerifyItemType.company;
      default:          return VerifyItemType.person;
    }
  }

  VerifyStatus _mapStatus(String? status) {
    switch (status) {
      case 'approved': return VerifyStatus.approved;
      case 'rejected': return VerifyStatus.rejected;
      default:         return VerifyStatus.pending;
    }
  }

  String _getApiType(VerifyItemType type) {
    switch (type) {
      case VerifyItemType.person:    return 'users';
      case VerifyItemType.portfolio: return 'portfolios';
      case VerifyItemType.company:   return 'jobs';
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTabs(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: _green))
                        : _errorMessage != null
                        ? _buildErrorState()
                        : RefreshIndicator(
                            onRefresh: _loadAllData,
                            color: _green,
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildTabContent(_userItems),
                                _buildTabContent(_portfolioItems),
                                _buildTabContent(_jobItems),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 52, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_errorMessage ?? 'เกิดข้อผิดพลาด',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _loadAllData,
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('ลองใหม่'),
          ),
        ]),
      ),
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
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Text('Local Job Hub Admin',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            Text('ระบบจัดการข้อมูลหลังบ้าน',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
          ]),
        ],
      ),
    );
  }

  // ─── TABS ─────────────────────────────────────
  // ✅ แสดงเลข pending จริง ไม่ใช่ total

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('ตรวจสอบข้อมูล',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          ),
          TabBar(
            controller: _tabController,
            labelColor: _green,
            unselectedLabelColor: const Color(0xFF757575),
            indicatorColor: _green,
            indicatorWeight: 2.5,
            labelStyle:           const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: [
              // ✅ ตัวเลขใน () คือ pending จริง
              Tab(text: 'ผู้ใช้งาน ($_userPending)'),
              Tab(text: 'พอร์ตโฟลิโอ ($_portfolioPending)'),
              Tab(text: 'งาน ($_jobPending)'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── TAB CONTENT ─────────────────────────────

  Widget _buildTabContent(List<VerifyItem> items) {
    final pendingItems = items.where((e) => e.status == VerifyStatus.pending).toList();

    if (pendingItems.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('ไม่มีข้อมูลสำหรับตรวจสอบ',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)))),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('รายการที่รอการตรวจสอบ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFFFF9C4), borderRadius: BorderRadius.circular(20)),
                child: Text('รอดำเนินการ ${pendingItems.length} รายการ',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF57F17))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...pendingItems.map((item) => _buildVerifyCard(item)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─── VERIFY CARD ─────────────────────────────

  Widget _buildVerifyCard(VerifyItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _pendingBadge(item.badge),
                      const SizedBox(width: 8),
                      const Icon(Icons.circle, size: 5, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.timeAgo, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)))),
                    ]),
                    const SizedBox(height: 6),
                    Text(item.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 2),
                    Text(item.description, style: const TextStyle(fontSize: 13, color: Color(0xFF757575))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _thumbnail(item.type),
            ],
          ),
          const SizedBox(height: 10),
          if (item.idNumber != null) ...[
            Row(children: [
              const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 6),
              Expanded(child: Text('เลขบัตร: ${item.idNumber}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
            ]),
            const SizedBox(height: 8),
          ],
          if (item.location != null) ...[
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF9E9E9E)),
              const SizedBox(width: 4),
              Expanded(child: Text(item.location!, style: const TextStyle(fontSize: 13, color: Color(0xFF555555)))),
              if (item.salary != null) ...[
                const SizedBox(width: 8),
                Container(width: 1, height: 14, color: const Color(0xFFE0E0E0)),
                const SizedBox(width: 8),
                Text(item.salary!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
              ],
            ]),
            const SizedBox(height: 8),
          ],
          if (item.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6, runSpacing: 6,
              children: item.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(tag, style: const TextStyle(fontSize: 12, color: Color(0xFF555555))),
              )).toList(),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleApprove(item),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('อนุมัติ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleReject(item),
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.cancel_outlined, color: _red, size: 18),
                      SizedBox(width: 6),
                      Text('ปฏิเสธ', style: TextStyle(color: _red, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF757575), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumbnail(VerifyItemType type) {
    IconData icon; Color bg;
    switch (type) {
      case VerifyItemType.person:    icon = Icons.person;           bg = const Color(0xFFE3F2FD); break;
      case VerifyItemType.portfolio: icon = Icons.image_outlined;   bg = const Color(0xFFF3E5F5); break;
      case VerifyItemType.company:   icon = Icons.business_outlined; bg = const Color(0xFFF5F5F5); break;
    }
    return Container(
      width: 72, height: 80,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.grey.shade500, size: 32),
    );
  }

  Widget _pendingBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFFFF9C4), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF57F17))),
    );
  }

  // ─── ACTIONS ─────────────────────────────────

  Future<void> _handleApprove(VerifyItem item) async {
    try {
      await VerifyService.updateStatus(type: _getApiType(item.type), id: item.id, status: 'approved');
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('อนุมัติ "${item.name}" แล้ว'),
        backgroundColor: _green, duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _red,
      ));
    }
  }

  Future<void> _handleReject(VerifyItem item) async {
    try {
      await VerifyService.updateStatus(type: _getApiType(item.type), id: item.id, status: 'rejected');
      await _loadAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ปฏิเสธ "${item.name}" แล้ว'),
        backgroundColor: _red, duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: _red,
      ));
    }
  }

  // ─── BOTTOM NAV ──────────────────────────────

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      onTap: (index) {
        if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardAdminPage()));
        if (index == 2) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UsersPage()));
        if (index == 3) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _green,
      unselectedItemColor: const Color(0xFF9E9E9E),
      backgroundColor: Colors.white,
      elevation: 8,
      selectedLabelStyle:   const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded),   label: 'แดชบอร์ด'),
        BottomNavigationBarItem(icon: Icon(Icons.shield_outlined),     label: 'ตรวจสอบ'),
        BottomNavigationBarItem(icon: Icon(Icons.group_outlined),      label: 'ผู้ใช้'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'แชท'),
      ],
    );
  }
}