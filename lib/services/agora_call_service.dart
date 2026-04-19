import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class AgoraCallConfig {
  // static const String baseUrl = 'http://localhost:3000/api';
  static const String baseUrl = 'http://192.168.1.162:3000/api';
}

class AgoraTokenResponse {
  final String appId;
  final String channelName;
  final int uid;
  final String token;

  AgoraTokenResponse({
    required this.appId,
    required this.channelName,
    required this.uid,
    required this.token,
  });

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      appId: json['appId']?.toString() ?? '',
      channelName: json['channelName']?.toString() ?? '',
      uid: (json['uid'] as num?)?.toInt() ?? 0,
      token: json['token']?.toString() ?? '',
    );
  }
}

class AgoraCallApi {
  static Future<AgoraTokenResponse> fetchVoiceToken({
    required String channelName,
    required int uid,
  }) async {
    final uri = Uri.parse(
      '${AgoraCallConfig.baseUrl}/agora/voice-token?channelName=$channelName&uid=$uid',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('โหลด Agora token ไม่สำเร็จ: ${response.body}');
    }

    return AgoraTokenResponse.fromJson(jsonDecode(response.body));
  }
}

class AgoraVoiceCallController {
  final RtcEngine engine;

  AgoraVoiceCallController._(this.engine);

  static Future<AgoraVoiceCallController> create({
    required String appId,
    required RtcEngineEventHandler eventHandler,
  }) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw Exception('ไม่ได้รับสิทธิ์ไมโครโฟน');
    }

    final engine = createAgoraRtcEngine();
    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.setChannelProfile(
      ChannelProfileType.channelProfileCommunication,
    );
    await engine.enableAudio();
    await engine.setEnableSpeakerphone(true);
    engine.registerEventHandler(eventHandler);

    return AgoraVoiceCallController._(engine);
  }

  Future<void> joinVoiceChannel({
    required String token,
    required String channelName,
    required int uid,
  }) async {
    await engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  Future<void> leave() async {
    await engine.leaveChannel();
  }

  Future<void> muteLocalAudio(bool muted) async {
    await engine.muteLocalAudioStream(muted);
  }

  Future<void> setSpeakerphone(bool enabled) async {
    await engine.setEnableSpeakerphone(enabled);
  }

  Future<void> dispose() async {
    await engine.release();
  }
}
