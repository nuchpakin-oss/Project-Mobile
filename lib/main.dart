import 'package:flutter/material.dart';
import 'pages/profile_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/earnings_page.dart';
import 'pages/portfolio_page.dart';
import 'pages/reviews_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/admin_login_page.dart';
import 'pages/dashboard_admin_page.dart';
import 'pages/announcement_admin_page.dart';
import 'pages/verify_admin_page.dart';
import 'pages/users_admin_page.dart';
import 'pages/user_detail_page.dart';
import 'pages/chat_list_admin_page.dart';
import 'pages/chat_room_admin_page.dart';
import 'pages/Report_admin_page.dart';
import 'applicants_page.dart';
import 'worker_profile_page.dart';
import 'payment_page.dart';
import 'job_detail_hiring_page.dart';
import 'addjob_page.dart';
import 'home_page.dart';
import 'category_page.dart';
import 'myjobs_page.dart';
import 'chat_page.dart';
import 'job_tracking_page.dart';
import 'job_status_page.dart';
import 'payment_success_page.dart';
import 'services/auth_service.dart';
import 'services/job_api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ServicePro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        fontFamily: 'Prompt',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/admin-login': (context) => const AdminLoginPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/earnings': (context) => const EarningsPage(),
        '/portfolio': (context) => const PortfolioPage(),
        '/reviews': (context) => const ReviewsPage(),
        '/dashboard': (context) => const DashboardAdminPage(),
        '/announcements': (context) => const AnnouncementPage(),
        '/verify': (context) => const VerifyPage(),
        '/users': (context) => const UsersPage(),
        '/user-detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          if (args == null || args is! UserItem) {
            return const Scaffold(
              body: Center(child: Text('ไม่พบข้อมูลผู้ใช้')),
            );
          }

          return UserDetailPage(user: args);
        },
        '/chat-list': (context) => const ChatListPage(),
        '/chat-room': (context) {
          final conversation =
              ModalRoute.of(context)!.settings.arguments as ChatConversation;

          return ChatRoomPage(conversation: conversation);
        },
        '/reports': (context) => const ReportPage(),
        '/home': (context) => const HomePage(),
        '/category': (context) => const CategoryPage(),
        '/myjobs': (context) => const MyJobsPage(),
        '/chat': (context) => const ChatPage(),
        '/job-tracking': (context) {
          final jobData =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          if (jobData == null) {
            return const Scaffold(body: Center(child: Text('ไม่พบข้อมูลงาน')));
          }
          return JobAcceptedDetailPage(job: JobItem.fromJson(jobData));
        },
        '/job-status': (context) {
          final jobData =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>;
          return JobStatusPage(job: jobData);
        },
      },
    );
  }
}
