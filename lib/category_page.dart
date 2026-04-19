import 'package:flutter/material.dart';
import 'home_page.dart';
import 'myjobs_page.dart';
import 'chat_page.dart';
import 'pages/profile_page.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<_CategoryItem> _allCategories = const [
    _CategoryItem(
      title: 'ช่างเทคนิค',
      icon: Icons.build_outlined,
      bgColor: Color(0xFFE8F5E9),
      iconColor: Colors.green,
      imageUrl: 'https://picsum.photos/id/2/400/250',
    ),
    _CategoryItem(
      title: 'ทำความสะอาด',
      icon: Icons.clean_hands_outlined,
      bgColor: Color(0xFFF3E5F5),
      iconColor: Colors.purple,
      imageUrl: 'https://picsum.photos/id/1/400/250',
    ),
    _CategoryItem(
      title: 'งานฝีมือ',
      icon: Icons.content_cut_outlined,
      bgColor: Color(0xFFFFF3E0),
      iconColor: Colors.orange,
      imageUrl: 'https://picsum.photos/id/20/400/250',
    ),
    _CategoryItem(
      title: 'การจัดส่ง',
      icon: Icons.local_shipping_outlined,
      bgColor: Color(0xFFE3F2FD),
      iconColor: Colors.blue,
      imageUrl: 'https://picsum.photos/id/30/400/250',
    ),
  ];

  List<_CategoryItem> get _filteredCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allCategories;

    return _allCategories.where((item) {
      return item.title.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCategory(_CategoryItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('เลือกหมวดหมู่: ${item.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories = _filteredCategories;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            }
          },
        ),
        title: const Text(
          'หมวดหมู่',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(),
            const SizedBox(height: 25),
            const Text(
              'ยอดนิยม',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildPopularCard(_allCategories[1]),
                const SizedBox(width: 15),
                _buildPopularCard(_allCategories[0]),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'หมวดหมู่ทั้งหมด',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 15),
            filteredCategories.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: const Text(
                      'ไม่พบหมวดหมู่ที่ค้นหา',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCategories.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredCategories[index];
                      return _buildCategoryCard(item);
                    },
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.grey),
          hintText: 'ค้นหาบริการ',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPopularCard(_CategoryItem item) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _openCategory(item),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: NetworkImage(item.imageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(15),
          child: Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryItem item) {
    return InkWell(
      onTap: () => _openCategory(item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
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
            true,
            onTap: () {},
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
    final Color color =
        isSelected ? const Color(0xFF00E676) : const Color(0xFF94A3B8);

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
            const SizedBox(height: 4),
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

class _CategoryItem {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String imageUrl;

  const _CategoryItem({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.imageUrl,
  });
}