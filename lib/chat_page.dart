import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'category_page.dart';
import 'myjobs_page.dart';
import 'pages/profile_page.dart';
import 'chat_room_user_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<List<ChatListItem>> _futureChats;

  @override
  void initState() {
    super.initState();
    _futureChats = ChatApiService.getConversations();
  }

  Future<void> _reloadChats() async {
    setState(() {
      _futureChats = ChatApiService.getConversations();
    });
  }

  Future<void> _startAdminChat() async {
    try {
      final conversationId = await ChatApiService.startAdminChat();
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomUserPage(
            contact: ChatListItem(
              id: conversationId,
              userName: 'แอดมิน',
              lastMessage: '',
              unreadCount: 0,
              timeText: '',
              isOnline: false,
              avatarUrl: null,
              type: 'user_admin',
            ),
          ),
        ),
      );

      await _reloadChats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เริ่มแชตกับแอดมินไม่สำเร็จ: $e')));
    }
  }

  Future<void> _confirmDeleteChat(ChatListItem chat) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบแชต'),
        content: Text('ต้องการลบแชตกับ "${chat.userName}" ใช่ไหม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await ChatApiService.deleteConversation(chat.id);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบแชตสำเร็จ')));

      await _reloadChats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ลบแชตไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'ข้อความ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _startAdminChat,
            icon: const Icon(Icons.support_agent, color: Colors.black87),
            tooltip: 'คุยกับแอดมิน',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadChats,
        child: FutureBuilder<List<ChatListItem>>(
          future: _futureChats,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'โหลดข้อความไม่สำเร็จ\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 180),
                  const Center(
                    child: Text(
                      'ยังไม่มีข้อความในระบบ',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _startAdminChat,
                      icon: const Icon(Icons.support_agent),
                      label: const Text('เริ่มคุยกับแอดมิน'),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _buildChatTile(chat: chat);
              },
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildChatTile({required ChatListItem chat}) {
    return GestureDetector(
      onLongPress: () => _confirmDeleteChat(chat),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: ListTile(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomUserPage(contact: chat),
              ),
            );
            await _reloadChats();
          },
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE8F5E9),
            backgroundImage:
                (chat.avatarUrl != null && chat.avatarUrl!.isNotEmpty)
                ? NetworkImage(chat.avatarUrl!)
                : null,
            child: (chat.avatarUrl == null || chat.avatarUrl!.isEmpty)
                ? Text(
                    chat.userName.isNotEmpty
                        ? chat.userName.characters.first
                        : '?',
                  )
                : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  chat.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chat.isOnline)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            chat.lastMessage ?? 'ยังไม่มีข้อความ',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                chat.timeText,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (chat.unreadCount > 0) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    chat.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
            false,
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CategoryPage()),
              );
            },
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
            true,
            onTap: () {},
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
    bool active, {
    VoidCallback? onTap,
  }) {
    final color = active ? const Color(0xFF00E676) : Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class ChatListItem {
  final int id;
  final String userName;
  final String? lastMessage;
  final int unreadCount;
  final String timeText;
  final bool isOnline;
  final String? avatarUrl;
  final String type;

  ChatListItem({
    required this.id,
    required this.userName,
    required this.lastMessage,
    required this.unreadCount,
    required this.timeText,
    required this.isOnline,
    required this.avatarUrl,
    required this.type,
  });

  String get name => userName;

  factory ChatListItem.fromJson(Map<String, dynamic> json) {
    return ChatListItem(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userName: json['user_name']?.toString() ?? 'ไม่ทราบชื่อ',
      lastMessage: json['last_message']?.toString(),
      unreadCount: int.tryParse(json['unread_count'].toString()) ?? 0,
      timeText: json['time_text']?.toString() ?? '',
      isOnline:
          json['is_online'] == true || json['is_online']?.toString() == '1',
      avatarUrl: json['avatar_url']?.toString(),
      type: json['type']?.toString() ?? 'user_user',
    );
  }
}

class ChatApiService {
  static const String baseUrl = 'http://192.168.1.162:3000/api/chat-v2';

  static Future<List<ChatListItem>> getConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'โหลดรายการแชตไม่สำเร็จ (${response.statusCode}) ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded
          .map((e) => ChatListItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception('รูปแบบข้อมูลรายการแชตไม่ถูกต้อง');
  }

  static Future<int> startAdminChat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/conversations/start-admin-chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('เริ่มแชตกับแอดมินไม่สำเร็จ: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return int.tryParse(decoded['conversation_id'].toString()) ?? 0;
  }

  static Future<int> startUserChat({
    required int otherUserId,
    String? title,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.post(
      Uri.parse('$baseUrl/conversations/start-user-chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'other_user_id': otherUserId, 'title': title}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('เริ่มแชตกับผู้ใช้นี้ไม่สำเร็จ: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return int.tryParse(decoded['conversation_id'].toString()) ?? 0;
  }

  static Future<void> deleteConversation(int conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.delete(
      Uri.parse('$baseUrl/conversations/$conversationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('ลบแชตไม่สำเร็จ: ${response.body}');
    }
  }
}
