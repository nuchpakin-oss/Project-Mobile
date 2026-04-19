import 'package:flutter/material.dart';
import '../services/profile_api_service.dart';
import '../services/auth_service.dart';
import 'withdraw_page.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  late Future<EarningsSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSummary();
  }

  Future<EarningsSummary> _loadSummary() async {
    final userId = await AuthService.getCurrentUserId();
    return ProfileApiService.getEarnings(userId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadSummary();
    });
    await _future;
  }

  Future<void> _openWithdrawPage(double balance) async {
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่มียอดเงินให้ถอน')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WithdrawPage(amount: balance),
      ),
    );

    if (result == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'สรุปรายได้',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<EarningsSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'โหลดรายได้ไม่สำเร็จ\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _future = _loadSummary();
                      }),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = snapshot.data!;
          final changePercent = summary.changePercent;
          final isPositive = changePercent >= 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'รายได้สุทธิเดือน',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '฿${_formatAmount(summary.totalMonth)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? const Color(0xFFE8FFF0)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${isPositive ? '↗' : '↘'} ${changePercent.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isPositive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFE53935),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'เดือนที่แล้ว ฿${_formatAmount(summary.previousMonth)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 18),

                _buildBalanceCard(summary.availableBalance),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Text(
                      'รายได้ล่าสุด',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'ดูทั้งหมด',
                        style: TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (summary.recentItems.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'ยังไม่มีรายการ',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...summary.recentItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildIncomeTile(item),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return amount.toStringAsFixed(2);
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ยอดเงินที่ถอนได้',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const Spacer(),
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: Colors.grey[700],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '฿${_formatAmount(balance)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'พร้อมสำหรับการถอน',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: balance <= 0
                  ? null
                  : () => _openWithdrawPage(balance),
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text(
                'ถอนเงิน',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF19E65C),
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTile(EarningItem item) {
    final title = item.title ?? 'รายได้';
    IconData icon;
    Color iconBg;
    Color iconColor;

    if (title.contains('ไฟ')) {
      icon = Icons.electrical_services;
      iconBg = const Color(0xFFEAF2FF);
      iconColor = const Color(0xFF3B82F6);
    } else if (title.contains('ออกแบบ') || title.contains('โครงการ')) {
      icon = Icons.build_rounded;
      iconBg = const Color(0xFFF4E8FF);
      iconColor = const Color(0xFFA855F7);
    } else if (title.contains('ซ่อม')) {
      icon = Icons.home_repair_service;
      iconBg = const Color(0xFFFFF1E8);
      iconColor = const Color(0xFFF97316);
    } else {
      icon = Icons.work_outline;
      iconBg = const Color(0xFFE9FCEB);
      iconColor = const Color(0xFF16A34A);
    }

    String dateStr = '';
    if (item.workDate != null) {
      try {
        final dt = DateTime.parse(item.workDate!).toLocal();
        dateStr = '${dt.day} ${_monthTh(dt.month)} ${dt.year + 543}';
      } catch (_) {
        dateStr = item.workDate!;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+฿${item.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  String _monthTh(int m) {
    const months = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return m >= 1 && m <= 12 ? months[m] : '';
  }
}