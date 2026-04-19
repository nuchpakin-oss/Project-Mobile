import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'services/agora_call_service.dart';

class VoiceCallPage extends StatefulWidget {
  final String contactName;
  final String? avatarUrl;
  final String channelName;
  final int localUid;

  const VoiceCallPage({
    super.key,
    required this.contactName,
    required this.avatarUrl,
    required this.channelName,
    required this.localUid,
  });

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  static const Color _green = Color(0xFF00C853);
  static const Color _darkNavy = Color(0xFF1A1A2E);
  static const Color _red = Color(0xFFEF5350);

  AgoraVoiceCallController? _controller;
  bool _isMuted = false;
  bool _isSpeaker = true;
  bool _isJoined = false;
  int? _remoteUid;
  String _statusText = 'กำลังเชื่อมต่อ...';

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      final tokenData = await AgoraCallApi.fetchVoiceToken(
        channelName: widget.channelName,
        uid: widget.localUid,
      );

      final controller = await AgoraVoiceCallController.create(
        appId: tokenData.appId,
        eventHandler: RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            if (!mounted) return;
            setState(() {
              _isJoined = true;
              _statusText = 'กำลังโทร...';
            });
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!mounted) return;
            setState(() {
              _remoteUid = remoteUid;
              _statusText = 'กำลังคุย';
            });
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (!mounted) return;
            setState(() {
              _remoteUid = null;
              _statusText = 'อีกฝ่ายออกจากสาย';
            });
          },
          onLeaveChannel: (connection, stats) {
            if (!mounted) return;
            setState(() {
              _isJoined = false;
            });
          },
          onError: (err, msg) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Agora error: $err $msg')),
            );
          },
        ),
      );

      _controller = controller;

      await controller.joinVoiceChannel(
        token: tokenData.token,
        channelName: tokenData.channelName,
        uid: tokenData.uid,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusText = 'โทรไม่สำเร็จ';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เริ่มสายไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _toggleMute() async {
    if (_controller == null) return;
    _isMuted = !_isMuted;
    await _controller!.muteLocalAudio(_isMuted);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _toggleSpeaker() async {
    if (_controller == null) return;
    _isSpeaker = !_isSpeaker;
    await _controller!.setSpeakerphone(_isSpeaker);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _endCall() async {
    await _controller?.leave();
    await _controller?.dispose();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller?.leave();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarAvailable =
        widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _endCall,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: _darkNavy,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Local Job Hub',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _darkNavy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const Spacer(),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0E0E0), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: avatarAvailable
                    ? Image.network(widget.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: const Color(0xFFE8F5E9),
                        child: Center(
                          child: Text(
                            widget.contactName.characters.first,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: _green,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.contactName,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _remoteUid != null ? _green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: _remoteUid != null ? _green : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _callControl(
                    icon: _isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_off_outlined,
                    label: 'ปิดเสียง',
                    active: _isMuted,
                    onTap: _toggleMute,
                  ),
                  _callControl(
                    icon: Icons.dialpad_rounded,
                    label: 'ปุ่มกด',
                    onTap: () {},
                  ),
                  _callControl(
                    icon: _isSpeaker
                        ? Icons.volume_up_rounded
                        : Icons.volume_up_outlined,
                    label: 'สำโพง',
                    active: _isSpeaker,
                    onTap: _toggleSpeaker,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _red.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'วางสาย',
              style: TextStyle(
                fontSize: 13,
                color: _red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _callControl({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: active ? _green : const Color(0xFF555555),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}