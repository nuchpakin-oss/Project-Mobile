import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/job_api_service.dart';
import 'services/auth_service.dart';
import 'home_page.dart';

class ReviewPage extends StatefulWidget {
  final Map<String, dynamic> job;
  const ReviewPage({super.key, required this.job});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _rating = 0;
  bool _isTipEnabled = false;
  final TextEditingController _reviewController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  String _getRatingText() {
    if (_rating == 0) return 'โปรดให้คะแนนงานนี้';
    if (_rating >= 5) return 'ยอดเยี่ยมที่สุด!';
    if (_rating >= 4) return 'ยอดเยี่ยม!';
    if (_rating >= 3) return 'ดีมาก';
    if (_rating >= 2) return 'พอใช้';
    return 'ควรปรับปรุง';
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาให้คะแนนก่อนส่งรีวิว'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final jobId = int.tryParse(widget.job['id']?.toString() ?? '') ?? 0;
    final workerUserId =
        int.tryParse(widget.job['workerUserId']?.toString() ?? '') ?? 0;

    if (jobId == 0 || workerUserId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ข้อมูลรีวิวไม่ครบ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reviewerUserId = await AuthService.getCurrentUserId();

    setState(() => _submitting = true);

    try {
      await JobApiService.submitWorkerReview(
        jobId: jobId,
        workerUserId: workerUserId,
        reviewerUserId: reviewerUserId,
        rating: _rating,
        reviewText: _reviewController.text.trim(),
        tipAmount: _isTipEnabled ? 50 : 0,
        imageUrl: '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ขอบคุณสำหรับการรีวิว!'),
          backgroundColor: Color(0xFF00E676),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งรีวิวไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'รีวิวงาน',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text(
              'งานเป็นอย่างไรบ้าง?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'โปรดให้คะแนนประสบการณ์การใช้บริการของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),
            _buildWorkerProfile(),
            const SizedBox(height: 40),
            _buildRatingStars(),
            const SizedBox(height: 15),
            Text(
              _getRatingText(),
              style: TextStyle(
                color: _rating == 0 ? Colors.grey : const Color(0xFF00E676),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 40),
            _buildReviewInput(),
            const SizedBox(height: 30),
            _buildImageUpload(),
            const SizedBox(height: 30),
            _buildTipSection(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerProfile() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: widget.job['workerImg'] != null &&
                    widget.job['workerImg'].toString().isNotEmpty
                ? NetworkImage(widget.job['workerImg'])
                : null,
            child: (widget.job['workerImg'] == null ||
                    widget.job['workerImg'].toString().isEmpty)
                ? Text(
                    widget.job['workerName'] != null
                        ? widget.job['workerName'].toString().characters.first
                        : '?',
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.job['workerName'] ?? 'ช่างผู้รับงาน',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                widget.job['title'] ?? 'งานบริการ',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: index < _rating
                  ? const Color(0xFF00E676)
                  : Colors.grey.shade300,
              size: 55,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReviewInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เขียนรีวิว',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reviewController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'แบ่งปันรายละเอียดเกี่ยวกับประสบการณ์ของคุณเพื่อช่วยผู้อื่น...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เพิ่มรูปภาพ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FFF4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00E676).withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: Color(0xFF00E676), size: 32),
                    SizedBox(height: 4),
                    Text(
                      'อัปโหลด',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            if (_selectedImage != null)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5252),
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
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildTipSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Color(0xFF00E676),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('เพิ่มทิป?', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '100% มอบให้ช่าง',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: _isTipEnabled,
            activeColor: const Color(0xFF00E676),
            onChanged: (val) => setState(() => _isTipEnabled = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _submitReview,
        icon: _submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'ส่งรีวิว',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
        label: _submitting
            ? const SizedBox.shrink()
            : const Icon(Icons.send_rounded, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E676),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
      ),
    );
  }
}