import 'package:flutter/material.dart';
import 'worker_profile_page.dart';
import 'payment_page.dart';
import 'services/job_api_service.dart';

class ApplicantsPage extends StatefulWidget {
  final int jobId;

  const ApplicantsPage({super.key, required this.jobId});

  @override
  State<ApplicantsPage> createState() => _ApplicantsPageState();
}

class _ApplicantsPageState extends State<ApplicantsPage> {
  late Future<JobApplicantsResponse> _futureApplicants;

  @override
  void initState() {
    super.initState();
    _futureApplicants = JobApiService.getApplicants(widget.jobId);
  }

  Future<void> _reload() async {
    setState(() {
      _futureApplicants = JobApiService.getApplicants(widget.jobId);
    });
  }

  Future<void> _hireApplicant(JobApplicantItem applicant) async {
    try {
      await JobApiService.hireApplicant(
        jobId: widget.jobId,
        applicantId: applicant.id,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('จ้างผู้สมัครสำเร็จ'),
          backgroundColor: Color(0xFF00E676),
        ),
      );

      await _reload();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('จ้างผู้สมัครไม่สำเร็จ: $e')));
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
          'ผู้สมัคร',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<JobApplicantsResponse>(
        future: _futureApplicants,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'โหลดผู้สมัครไม่สำเร็จ\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final result = snapshot.data;
          if (result == null) {
            return const Center(child: Text('ไม่พบข้อมูล'));
          }

          final job = result.job;
          final applicants = result.applicants;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                        Text(
                          ' โพสต์เมื่อ ${job.workDate.isNotEmpty ? job.workDate : '-'}  •  ',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'ผู้สมัคร ${applicants.length} คน',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: applicants.isEmpty
                    ? const Center(child: Text('ยังไม่มีผู้สมัคร'))
                    : RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: applicants.length,
                          itemBuilder: (context, index) {
                            return _buildApplicantCard(
                              context,
                              applicants[index],
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApplicantCard(BuildContext context, JobApplicantItem person) {
    final bool isNew = person.status == 'backup';

    return FutureBuilder<WorkerProfileResponse>(
      future: JobApiService.getWorkerProfile(person.workerUserId),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final ratingAvg = profile?.ratingAvg ?? 0;
        final ratingCount = profile?.ratingCount ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: person.img.isNotEmpty
                            ? NetworkImage(person.img)
                            : null,
                        child: person.img.isEmpty
                            ? Text(
                                person.name.isNotEmpty
                                    ? person.name.characters.first
                                    : '?',
                              )
                            : null,
                      ),
                      if (person.status == 'hired')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'ถูกจ้างแล้ว',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                person.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              person.jobTitle,
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFB300),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${ratingAvg.toStringAsFixed(1)} ($ratingCount รีวิว)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person, color: Colors.grey, size: 16),
                            Expanded(
                              child: Text(
                                ' ${person.email.isNotEmpty ? person.email : person.phone}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          person.desc.isNotEmpty ? person.desc : 'ไม่มีคำอธิบาย',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WorkerProfilePage(applicant: person),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        isNew ? 'ใหม่' : 'ดูโปรไฟล์',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: person.status == 'hired'
                          ? null
                          : () async {
                              await _hireApplicant(person);
                              if (!mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentPage(
                                    jobId: widget.jobId,
                                    applicantId: person.workerUserId,
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: person.status == 'hired'
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF00E676),
                        foregroundColor: person.status == 'hired'
                            ? Colors.grey
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        person.status == 'hired' ? 'จ้างแล้ว' : 'จ้างตอนนี้',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}