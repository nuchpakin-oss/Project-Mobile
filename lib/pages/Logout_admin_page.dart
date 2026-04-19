import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // ปรับ path ตาม project

// ─────────────────────────────────────────────
// LOGOUT PAGE
// ─────────────────────────────────────────────

class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF00C853);
  static const Color _darkNavy = Color(0xFF1A1A2E);
  static const Color _red = Color(0xFFEF5350);

  bool _isLoading = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top green bar ──
            Container(height: 4, color: _green),

            // ── App Bar ──
            _buildAppBar(context),

            // ── Body ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildIcon(),
                    const SizedBox(height: 36),
                    _buildTexts(),
                    const Spacer(flex: 3),
                    _buildButtons(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // APP BAR
  // ─────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back button (left)
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back,
                  size: 24, color: _darkNavy),
            ),
          ),
          // Title (center)
          const Text(
            'ออกจากระบบ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _darkNavy,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ICON (dashed circle + logout icon)
  // ─────────────────────────────────────────────

  Widget _buildIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(
        scale: _pulseAnimation.value,
        child: child,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer dashed ring
          CustomPaint(
            size: const Size(180, 180),
            painter: _DashedCirclePainter(
              color: _green.withOpacity(0.4),
              strokeWidth: 2,
              dashLength: 8,
              gapLength: 6,
            ),
          ),
          // Inner filled circle
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              size: 68,
              color: _green,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TEXTS
  // ─────────────────────────────────────────────

  Widget _buildTexts() {
    return Column(
      children: const [
        Text(
          'คุณแน่ใจหรือไม่?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _darkNavy,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'การออกจากระบบ GigFindr จะทำให้คุณต้อง\nเข้าสู่ระบบใหม่อีกครั้งเพื่อจัดการงานและดูแดช\nบอร์ดผู้ดูแลระบบ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BUTTONS
  // ─────────────────────────────────────────────

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // ── ออกจากระบบ ──
        GestureDetector(
          onTap: _isLoading ? null : () => _handleLogout(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: _isLoading ? _red.withOpacity(0.7) : _red,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _red.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ── ยกเลิก ──
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF555555),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // LOGOUT LOGIC
  // ─────────────────────────────────────────────

  Future<void> _handleLogout(BuildContext context) async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800)); // simulate

    try {
      // TODO: เชื่อมกับ AuthService จริง
      // await AuthService().signOut();

      if (!mounted) return;

      // Navigate ไปหน้า login แล้ว clear stack ทั้งหมด
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', // ปรับ route ตาม project
        (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
// CUSTOM PAINTER — Dashed Circle
// ─────────────────────────────────────────────

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final circumference = 2 * 3.14159265 * radius;
    final totalDash = dashLength + gapLength;
    final count = (circumference / totalDash).floor();
    final anglePerDash = 2 * 3.14159265 / count;
    final dashAngle = anglePerDash * (dashLength / totalDash);

    for (int i = 0; i < count; i++) {
      final startAngle = i * anglePerDash - 3.14159265 / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}