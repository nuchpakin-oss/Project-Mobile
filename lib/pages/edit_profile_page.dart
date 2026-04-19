import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_api_service.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _picker = ImagePicker();

  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final aboutController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _didInit = false;

  late int userId;
  UserProfile? _profile;

  Uint8List? _imageBytes;
  String? _imageName;

  final List<Uint8List> _portfolioImages = [];
  final List<String> _portfolioNames = [];

  final List<String> _availableSkills = [
    'การเดินสายไฟ',
    'การติดโคมไฟ',
    'การซ่อมระบบไฟ',
    'สมาร์ทโฮม',
    'การติดตั้งเต้ารับ',
    'การติดตั้งสวิตช์',
    'เครื่องปรับอากาศ',
    'งานซ่อมบำรุง',
    'ระบบรักษาความปลอดภัย',
    'ติดตั้งกล้องวงจรปิด',
    'การชาร์จรถยนต์ไฟฟ้า',
    'โซลาร์เซลล์',
    'งานอุตสาหกรรม',
  ];
  List<String> _selectedSkills = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;
    _resolveUserIdAndFetchProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    aboutController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _resolveUserIdAndFetchProfile() async {
    final routeUserId = ModalRoute.of(context)?.settings.arguments as int?;
    userId = routeUserId ?? await AuthService.getCurrentUserId();
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final p = await ProfileApiService.getProfile(userId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        nameController.text = p.fullName;
        titleController.text = p.jobTitle ?? '';
        aboutController.text = p.bio ?? '';
        phoneController.text = p.phone ?? '';
        emailController.text = p.email;
        _selectedSkills = List<String>.from(p.skills);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('โหลดข้อมูลไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _showImageSourceSelector() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'เลือกรูปโปรไฟล์',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.green),
                title: const Text('ถ่ายรูป'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Colors.green),
                title: const Text('เลือกรูปจากอัลบั้ม'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null && mounted) {
      await _pickAvatar(source);
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
    } catch (e) {
      _showSnack('เลือกรูปไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _pickPortfolioImages() async {
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (files.isEmpty) return;

      for (final file in files) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _portfolioImages.add(bytes);
          _portfolioNames.add(file.name);
        });
      }

      _showSnack('เพิ่มรูปผลงาน ${files.length} รูปแล้ว ✓');
    } catch (e) {
      _showSnack('เลือกรูปผลงานไม่สำเร็จ: $e', isError: true);
    }
  }

  void _removePortfolioImage(int index) {
    setState(() {
      _portfolioImages.removeAt(index);
      _portfolioNames.removeAt(index);
    });
  }

  Future<void> _showSkillSelector() async {
    final result = await showDialog<List<String>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SkillSelectorDialog(
        available: _availableSkills,
        selected: List<String>.from(_selectedSkills),
      ),
    );

    if (result != null && mounted) {
      setState(() => _selectedSkills = result);
    }
  }

  void _removeSkill(String s) {
    setState(() => _selectedSkills.remove(s));
  }

  Future<void> _save() async {
    if (_profile == null) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('กรุณากรอกชื่อ-นามสกุล', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ProfileApiService.updateProfile(
        userId: userId,
        fullName: name,
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        bio: aboutController.text.trim(),
        jobTitle: titleController.text.trim(),
        skills: _selectedSkills,
        profileImageBytes: _imageBytes,
        profileImageFileName: _imageName,
      );

      if (_portfolioImages.isNotEmpty) {
        await ProfileApiService.uploadPortfolios(
          userId: userId,
          images: _portfolioImages,
          fileNames: _portfolioNames,
          description: titleController.text.trim(),
          tags: _selectedSkills.join(','),
        );
      }

      if (!mounted) return;
      _showSnack('บันทึกข้อมูลสำเร็จ ✓');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showSnack('บันทึกไม่สำเร็จ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ยืนยันการยกเลิก'),
        content: const Text('ข้อมูลที่แก้ไขไว้จะไม่ถูกบันทึก'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('กลับไปแก้ไขต่อ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ยืนยันการยกเลิก',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  ImageProvider _avatarProvider() {
    if (_imageBytes != null) return MemoryImage(_imageBytes!);
    final url = _profile?.profileImageUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return const AssetImage('assets/alex_rivera.jpg');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: _confirmCancel,
        ),
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'บันทึก',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _avatarProvider(),
                        child: _imageBytes != null
                            ? Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: GestureDetector(
                          onTap: _showImageSourceSelector,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showImageSourceSelector,
                    child: const Text(
                      'เปลี่ยนรูปโปรไฟล์',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('ข้อมูลวิชาชีพ'),
            _field('ชื่อ-นามสกุล', nameController),
            _field('ตำแหน่งวิชาชีพ', titleController),
            _field('เกี่ยวกับฉัน', aboutController, maxLines: 5),
            const SizedBox(height: 16),

            _buildSkillsSection(),
            const SizedBox(height: 16),

            _buildPortfolioSection(),
            const SizedBox(height: 20),

            _sectionTitle('ข้อมูลการติดต่อ'),
            _fieldWithIcon(
              'เบอร์โทรศัพท์',
              phoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _fieldWithIcon(
              'ที่อยู่อีเมล',
              emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _confirmCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Color(0xFFFFCACA)),
                  backgroundColor: const Color(0xFFFFF5F5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'ปิดใช้งานโปรไฟล์บริการ',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'ผลงาน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _pickPortfolioImages,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFFAF1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD7F5DF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.upload_rounded, color: Colors.green, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'อัปโหลดผลงาน',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemSize = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._portfolioImages.asMap().entries.map((entry) {
                  final i = entry.key;
                  final bytes = entry.value;

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          bytes,
                          width: itemSize,
                          height: itemSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removePortfolioImage(i),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                GestureDetector(
                  onTap: _pickPortfolioImages,
                  child: Container(
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00E676),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Color(0xFF00E676), size: 28),
                        SizedBox(height: 4),
                        Text(
                          'เพิ่มโครงการ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        if (_portfolioImages.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'ยังไม่มีรูปผลงาน กด "อัปโหลดผลงาน" เพื่อเพิ่ม',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ทักษะและความเชี่ยวชาญ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showSkillSelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFAF1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD7F5DF)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'เพิ่ม',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedSkills.isEmpty)
            const Text(
              'ยังไม่มีทักษะ กด "เพิ่ม" เพื่อเลือก',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedSkills
                  .map(
                    (s) => Chip(
                      label: Text(s, style: const TextStyle(fontSize: 13)),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeSkill(s),
                      backgroundColor: const Color(0xFFEFFAF1),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFD7F5DF)),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      );

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldWithIcon(
    String label,
    TextEditingController ctrl, {
    required IconData prefixIcon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(
                prefixIcon,
                size: 18,
                color: const Color(0xFF9E9E9E),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillSelectorDialog extends StatefulWidget {
  final List<String> available;
  final List<String> selected;

  const _SkillSelectorDialog({
    required this.available,
    required this.selected,
  });

  @override
  State<_SkillSelectorDialog> createState() => _SkillSelectorDialogState();
}

class _SkillSelectorDialogState extends State<_SkillSelectorDialog> {
  late List<String> _temp;

  @override
  void initState() {
    super.initState();
    _temp = List<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'เลือกทักษะและความเชี่ยวชาญ',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.available.map((skill) {
              final isSelected = _temp.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                selectedColor: const Color(0xFFEFFAF1),
                checkmarkColor: Colors.green,
                side: BorderSide(
                  color: isSelected ? Colors.green : const Color(0xFFE5E7EB),
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      if (!_temp.contains(skill)) _temp.add(skill);
                    } else {
                      _temp.remove(skill);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, null),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('ยกเลิก'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, List<String>.from(_temp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'ยืนยัน',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}