import 'package:flutter/material.dart';
import 'home_page.dart';
import 'job_progress_page.dart';
import 'services/job_api_service.dart';

class PaymentSuccessPage extends StatefulWidget {
  final int jobId;
  final int workerUserId;

  const PaymentSuccessPage({
    super.key,
    required this.jobId,
    required this.workerUserId,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late Future<PaymentSummaryResponse> _futureSummary;

  @override
  void initState() {
    super.initState();
    _futureSummary = JobApiService.getPaymentSummary(
      jobId: widget.jobId,
      workerUserId: widget.workerUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaymentSummaryResponse>(
      future: _futureSummary,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'โหลดข้อมูลการชำระเงินไม่สำเร็จ\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final job = data.job;
        final payment = data.payment;
        final paymentMethod = _paymentMethodText(payment?.paymentMethod ?? 'manual');
        final paymentId = payment?.id != null
            ? '#GF-${payment!.id.toString().padLeft(6, '0')}'
            : '#GF-000000';
        final priceText = payment != null
            ? payment.amount.toStringAsFixed(2)
            : job.budget.toStringAsFixed(2);

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
        };

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF00E676),
                        size: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'ชำระเงินเสร็จสิ้น',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ขอบคุณที่ใช้บริการ',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  _buildReceiptCard(
                    paymentId: paymentId,
                    paymentMethod: paymentMethod,
                    priceText: priceText,
                  ),

                  const SizedBox(height: 40),

                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download_outlined, size: 18, color: Colors.grey),
                    label: const Text(
                      'บันทึกใบเสร็จรับเงิน',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const Spacer(),

                  _buildButton(
                    label: 'ดูสถานะงาน',
                    color: const Color(0xFF00E676),
                    textColor: Colors.white,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobProgressPage(
                            jobId: widget.jobId,
                            workerUserId: widget.workerUserId,
                            job: jobMap,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),

                  _buildButton(
                    label: 'กลับหน้าหลัก',
                    color: Colors.white,
                    textColor: Colors.black87,
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptCard({
    required String paymentId,
    required String paymentMethod,
    required String priceText,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _receiptRow('หมายเลขรายการ', paymentId),
          const Divider(height: 30),
          _receiptRow('ช่องทางชำระเงิน', paymentMethod, icon: Icons.credit_card),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดชำระทั้งหมด',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '$priceText บาท',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Row(
          children: [
            if (icon != null) Icon(icon, size: 16, color: Colors.grey),
            if (icon != null) const SizedBox(width: 5),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          side: isOutlined ? BorderSide(color: Colors.grey.shade200) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _paymentMethodText(String method) {
    switch (method) {
      case 'card':
        return 'บัตรเครดิต';
      case 'promptpay':
        return 'พร้อมเพย์';
      case 'wallet':
        return 'อี-วอลเล็ต';
      default:
        return 'ชำระเงินออนไลน์';
    }
  }
}