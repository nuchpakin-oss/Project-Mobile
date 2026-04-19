import 'package:flutter/material.dart';
import 'payment_success_page.dart';
import 'services/job_api_service.dart';

class PaymentPage extends StatefulWidget {
  final int jobId;
  final int applicantId;

  const PaymentPage({
    super.key,
    required this.jobId,
    required this.applicantId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedMethod = 0;

  bool _cardCompleted = false;
  bool _promptPayConfirmed = false;
  bool _walletConfirmed = false;

  String _cardSubtitle = 'แตะเพื่อเพิ่มข้อมูลบัตร';
  String _walletSubtitle = 'PayPal, GrabPay, TrueMoney';

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();

  String _selectedWallet = 'TrueMoney';

  late Future<JobItem> _futureJob;

  @override
  void initState() {
    super.initState();
    _futureJob = JobApiService.getJobById(widget.jobId);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
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
          'ชำระเงินอย่างปลอดภัย',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<JobItem>(
        future: _futureJob,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'โหลดข้อมูลงานไม่สำเร็จ\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final job = snapshot.data;
          if (job == null) {
            return const Center(child: Text('ไม่พบข้อมูลงาน'));
          }

          final amountText = job.budget.toStringAsFixed(2);
          final priceForSuccess =
              job.budget.toStringAsFixed(0) == job.budget.toStringAsFixed(2)
              ? job.budget.toStringAsFixed(0)
              : job.budget.toStringAsFixed(2);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  'ยอดชำระทั้งหมด',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Text(
                  '฿ $amountText',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusBadge(),
                const SizedBox(height: 30),
                _buildJobSummaryCard(job),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'วิธีการชำระเงิน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _openSelectedMethodDialog(amountText);
                      },
                      child: const Text(
                        'เพิ่มใหม่',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildPaymentMethodItem(
                  0,
                  Icons.credit_card,
                  'บัตรเครดิต/เดบิต',
                  _cardSubtitle,
                  amountText,
                ),
                _buildPaymentMethodItem(
                  1,
                  Icons.qr_code_scanner,
                  'พร้อมเพย์',
                  _promptPayConfirmed
                      ? 'สร้าง QR พร้อมเพย์แล้ว'
                      : 'โอนเงินผ่านธนาคารทันที',
                  amountText,
                ),
                _buildPaymentMethodItem(
                  2,
                  Icons.account_balance_wallet_outlined,
                  'อี-วอลเล็ต',
                  _walletConfirmed
                      ? 'เลือก $_selectedWallet แล้ว'
                      : _walletSubtitle,
                  amountText,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey[400]),
                    const SizedBox(width: 5),
                    Text(
                      'การชำระเงินของคุณปลอดภัยและได้รับการเข้ารหัส',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await _handleContinue(amountText);
                      if (!ok || !mounted) return;

                      try {
                        final job = await JobApiService.getJobById(
                          widget.jobId,
                        );

                        await JobApiService.payNow(
                          jobId: widget.jobId,
                          workerUserId: widget.applicantId,
                          amount: job.budget,
                          paymentMethod: _selectedMethod == 0
                              ? 'card'
                              : _selectedMethod == 1
                              ? 'promptpay'
                              : 'wallet',
                        );

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ชำระเงินสำเร็จ'),
                            backgroundColor: Color(0xFF00E676),
                          ),
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentSuccessPage(
                              jobId: widget.jobId,
                              workerUserId: widget.applicantId,
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('จ่ายเงินไม่สำเร็จ: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'ดำเนินการต่อ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _handleContinue(String amountText) async {
    if (_selectedMethod == 0 && !_cardCompleted) {
      await _showCardDialog();
      return _cardCompleted;
    }

    if (_selectedMethod == 1 && !_promptPayConfirmed) {
      await _showPromptPayDialog(amountText);
      return _promptPayConfirmed;
    }

    if (_selectedMethod == 2 && !_walletConfirmed) {
      await _showWalletDialog();
      return _walletConfirmed;
    }

    return true;
  }

  Future<void> _openSelectedMethodDialog(String amountText) async {
    if (_selectedMethod == 0) {
      await _showCardDialog();
    } else if (_selectedMethod == 1) {
      await _showPromptPayDialog(amountText);
    } else {
      await _showWalletDialog();
    }
  }

  Future<void> _showCardDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'เพิ่มบัตรเครดิต/เดบิต',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildDialogTextField(
                  controller: _cardNumberController,
                  label: 'เลขบัตร',
                  hint: '1234 5678 9012 3456',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildDialogTextField(
                  controller: _cardNameController,
                  label: 'ชื่อบนบัตร',
                  hint: 'PAKIN NARKJAROEN',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDialogTextField(
                        controller: _cardExpiryController,
                        label: 'วันหมดอายุ',
                        hint: 'MM/YY',
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDialogTextField(
                        controller: _cardCvvController,
                        label: 'CVV',
                        hint: '123',
                        keyboardType: TextInputType.number,
                        obscureText: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                final cardNumber = _cardNumberController.text.trim();
                final cardName = _cardNameController.text.trim();
                final expiry = _cardExpiryController.text.trim();
                final cvv = _cardCvvController.text.trim();

                if (cardNumber.isEmpty ||
                    cardName.isEmpty ||
                    expiry.isEmpty ||
                    cvv.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณากรอกข้อมูลบัตรให้ครบ')),
                  );
                  return;
                }

                setState(() {
                  _cardCompleted = true;
                  final last4 = cardNumber.length >= 4
                      ? cardNumber.substring(cardNumber.length - 4)
                      : cardNumber;
                  _cardSubtitle = 'Visa ลงท้ายด้วย $last4';
                });

                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
              ),
              child: const Text(
                'บันทึก',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPromptPayDialog(String amountText) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'ชำระผ่านพร้อมเพย์',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 120,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'สแกน QR เพื่อชำระเงิน',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'ยอดชำระ ฿ $amountText',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ปิด'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _promptPayConfirmed = true;
                });
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
              ),
              child: const Text(
                'ยืนยันการชำระ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showWalletDialog() async {
    String tempWallet = _selectedWallet;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'เลือกอี-วอลเล็ต',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    value: 'TrueMoney',
                    groupValue: tempWallet,
                    onChanged: (value) {
                      setDialogState(() => tempWallet = value!);
                    },
                    title: const Text('TrueMoney'),
                  ),
                  RadioListTile<String>(
                    value: 'GrabPay',
                    groupValue: tempWallet,
                    onChanged: (value) {
                      setDialogState(() => tempWallet = value!);
                    },
                    title: const Text('GrabPay'),
                  ),
                  RadioListTile<String>(
                    value: 'PayPal',
                    groupValue: tempWallet,
                    onChanged: (value) {
                      setDialogState(() => tempWallet = value!);
                    },
                    title: const Text('PayPal'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedWallet = tempWallet;
                      _walletConfirmed = true;
                    });
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                  ),
                  child: const Text(
                    'ยืนยัน',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 14,
            color: Color(0xFF00E676),
          ),
          SizedBox(width: 4),
          Text(
            'ตรวจสอบแล้ว',
            style: TextStyle(
              color: Color(0xFF00E676),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSummaryCard(JobItem job) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF00E676),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'หมายเลขประกาศ: #${job.id}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const Text(
            'รายละเอียด',
            style: TextStyle(
              color: Color(0xFF00E676),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(
    int index,
    IconData icon,
    String title,
    String subtitle,
    String amountText,
  ) {
    final bool isSelected = _selectedMethod == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedMethod = index);
        _openSelectedMethodDialog(amountText);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFF00E676) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF64748B)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00E676)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected
                    ? const Color(0xFF00E676)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
