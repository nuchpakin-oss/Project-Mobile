import 'package:flutter/material.dart';
import '../services/profile_api_service.dart';
import '../services/auth_service.dart';
import '../services/job_api_service.dart';
import '../home_page.dart';
import '../category_page.dart';
import '../myjobs_page.dart';
import '../chat_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _profileFuture;
  Future<WorkerReviewsResponse>? _reviewsFuture;
  Future<List<PortfolioItem>>? _portfoliosFuture;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = AuthService.getCurrentUserId().then((userId) {
      _currentUserId = userId;
      _reviewsFuture = JobApiService.getWorkerReviews(userId);
      _portfoliosFuture = ProfileApiService.getPortfolios(userId);
      return ProfileApiService.getProfile(userId);
    });
  }

  Future<void> _refreshProfile() async {
    setState(() => _loadProfile());
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF5350), size: 22),
            SizedBox(width: 8),
            Text(
              'ออกจากระบบ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: const Text(
          'คุณต้องการออกจากระบบใช่ไหม?\nคุณจะต้องเข้าสู่ระบบใหม่เพื่อใช้งาน',
          style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF555555)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Color(0xFF757575)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await AuthService.logout();
                    if (!mounted) return;
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'ออกจากระบบ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openPortfolioPage(BuildContext context) {
    Navigator.pushNamed(context, '/portfolio');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'โปรไฟล์ของฉัน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_rounded),
            color: const Color(0xFFEF5350),
            tooltip: 'ออกจากระบบ',
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'โหลดโปรไฟล์ไม่สำเร็จ\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, profile),
                const SizedBox(height: 16),
                _buildAboutSection(profile),
                const SizedBox(height: 24),
                _buildPortfolioSection(context),
                const SizedBox(height: 24),
                _buildReviewSection(context),
                const SizedBox(height: 24),
                _buildLogoutButton(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(
          Icons.logout_rounded,
          color: Color(0xFFEF5350),
          size: 20,
        ),
        label: const Text(
          'ออกจากระบบ',
          style: TextStyle(
            color: Color(0xFFEF5350),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFFFFCDD2), width: 1.5),
          backgroundColor: const Color(0xFFFFF5F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfile profile) {
    final String? imageUrl = profile.profileImageUrl;
    final ImageProvider? imageProvider =
        (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null;

    return FutureBuilder<WorkerReviewsResponse>(
      future: _reviewsFuture,
      builder: (context, reviewSnapshot) {
        final ratingAvg = reviewSnapshot.data?.ratingAvg ?? profile.rating;
        final reviewCount = reviewSnapshot.data?.reviewCount ?? 0;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundImage: imageProvider,
              backgroundColor: const Color(0xFFE8F5E9),
              child: imageProvider == null
                  ? Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName.characters.first
                          : '?',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00E676),
                      ),
                    )
                  : Align(
                      alignment: Alignment.bottomRight,
                      child: profile.isVerified
                          ? Container(
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              profile.fullName.isNotEmpty ? profile.fullName : 'Alex Rivera',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (profile.jobTitle?.isNotEmpty == true)
              Text(profile.jobTitle!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(ratingAvg.toStringAsFixed(1)),
                const SizedBox(width: 8),
                Text(
                  '($reviewCount รีวิว)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/edit-profile',
                      arguments: profile.id,
                    );
                    if (result == true) await _refreshProfile();
                  },
                  icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  label: const Text('แก้ไขโปรไฟล์'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/earnings'),
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  label: const Text('ดูรายได้'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection(UserProfile profile) {
    final bio = (profile.bio != null && profile.bio!.trim().isNotEmpty)
        ? profile.bio!
        : 'มีประสบการณ์มากกว่า 10 ปีในงานไฟฟ้าและงานซ่อมแซมบ้านทั่วไป';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'เกี่ยวกับฉัน',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bio,
            style: const TextStyle(color: Colors.black87, height: 1.4),
          ),
          if (profile.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile.skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: const Color(0xFFEFFAF1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFD7F5DF)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Text('เบอร์โทร: ${(profile.phone?.isNotEmpty == true) ? profile.phone! : '-'}'),
          const SizedBox(height: 4),
          Text('อีเมล: ${profile.email}'),
        ],
      ),
    );
  }

  Widget _buildPortfolioSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_library_outlined, color: Colors.green),
            const SizedBox(width: 8),
            const Text(
              'ผลงานของฉัน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _openPortfolioPage(context),
              child: const Text('ดูผลงาน →'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<PortfolioItem>>(
          future: _portfoliosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('โหลดผลงานไม่สำเร็จ\n${snapshot.error}'),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return GestureDetector(
                onTap: () => _openPortfolioPage(context),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'ยังไม่มีผลงาน\nกดเพื่อไปหน้าอัปโหลดผลงาน',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              );
            }

            final bool hasMoreThan3 = items.length > 3;
            final List<PortfolioItem> visibleItems =
                hasMoreThan3 ? items.take(3).toList() : items.take(4).toList();
            final int remainingCount = items.length - 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: hasMoreThan3 ? 4 : visibleItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (hasMoreThan3 && index == 3) {
                  return GestureDetector(
                    onTap: () => _openPortfolioPage(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              color: Color(0xFF64748B),
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+$remainingCount เพิ่มเติม',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final item = visibleItems[index];
                final imageUrl = item.imageUrl ?? '';

                return GestureDetector(
                  onTap: () => _openPortfolioPage(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return FutureBuilder<WorkerReviewsResponse>(
      future: _reviewsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return const SizedBox.shrink();

        final data = snapshot.data;
        final reviews = data?.reviews ?? [];
        final ratingAvg = data?.ratingAvg ?? 0;
        final reviewCount = data?.reviewCount ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_border, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'รีวิว',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${ratingAvg.toStringAsFixed(1)} ($reviewCount)',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ยังไม่มีรีวิว',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              ...reviews.take(2).map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildReviewItem(
                        r.reviewerName.isNotEmpty ? r.reviewerName : 'ผู้ใช้งาน',
                        r.rating.toStringAsFixed(1),
                        r.createdAt,
                        r.reviewText.isNotEmpty ? r.reviewText : '-',
                        reviewerImg: r.reviewerImg,
                      ),
                    ),
                  ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/reviews'),
                child: Center(
                  child: Text('ดูรีวิวทั้งหมด $reviewCount รายการ'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildReviewItem(
    String name,
    String rating,
    String time,
    String comment, {
    String reviewerImg = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: reviewerImg.isNotEmpty ? NetworkImage(reviewerImg) : null,
            backgroundColor: const Color(0xFFE8F5E9),
            radius: 20,
            child: reviewerImg.isEmpty
                ? Text(
                    name.isNotEmpty ? name.characters.first : '?',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    Text(rating),
                  ],
                ),
                Text(
                  time,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(comment, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_filled,
            'หน้าหลัก',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            ),
          ),
          _navItem(
            Icons.grid_view_outlined,
            'หมวดหมู่',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            ),
          ),
          _navItem(
            Icons.assignment_outlined,
            'งานของฉัน',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MyJobsPage()),
            ),
          ),
          _navItem(
            Icons.chat_bubble_outline,
            'ข้อความ',
            false,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChatPage()),
            ),
          ),
          _navItem(Icons.person_outline, 'โปรไฟล์', true, onTap: () {}),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    final color =
        isSelected ? const Color(0xFF00E676) : const Color(0xFF94A3B8);

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