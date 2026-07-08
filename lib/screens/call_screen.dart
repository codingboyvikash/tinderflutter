import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    required this.isVideo,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  RtcEngine? _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _speakerOn = true;
  bool _cameraOn = true;
  bool _isIncoming = true; // True if callee, false if caller
  bool _callConnected = false;

  Timer? _callTimer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _checkCallRole();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _destroyAgora();
    super.dispose();
  }

  void _checkCallRole() {
    final socket = ref.read(socketServiceProvider).socket;
    if (socket == null) return;

    final currentUser = (ref.read(authNotifierProvider) as AuthAuthenticated).user;
    final myUserId = currentUser['id'] as String;

    // Check if we initiated call or if we received call arguments
    // For simplicity, we default to caller role, unless callee flag is set.
    // Let's listen to incoming signals
    socket.on('call_answered', (data) {
      final payload = Map<String, dynamic>.from(data);
      if (payload['accept'] == true) {
        setState(() {
          _isIncoming = false;
          _callConnected = true;
        });
        _initAgora();
        _startTimer();
      } else {
        _endCallLocally('Call Declined');
      }
    });

    socket.on('call_ended', (_) {
      _endCallLocally('Call ended');
    });

    // Detect if caller: we trigger call signaling
    // How to determine if we are caller: we pushed to this screen from ChatRoomScreen.
    // So we are the caller! We must emit call setup immediately.
    // Wait, let's check: we can trigger signaling on build
    Future.microtask(() {
      setState(() {
        _isIncoming = false; // We are initiating caller
      });
      socket.emit('initiate_call', {
        'callerId': myUserId,
        'callerName': currentUser['email'] ?? 'Someone',
        'calleeId': widget.recipientId,
        'channelName': widget.chatId,
        'isVideo': widget.isVideo,
      });
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  Future<void> _initAgora() async {
    // 1. Request permissions
    await [Permission.microphone, Permission.camera].request();

    // 2. Load token from API
    try {
      final tokenData = await ref.read(callRepositoryProvider).getAgoraToken(widget.chatId, 0); // 0 for wildcard uid
      final String token = tokenData['token'];
      final String appId = tokenData['appId'];

      if (appId == 'mock_agora_app_id') {
        print('Agora is mock. Simulating connected video stream.');
        setState(() {
          _localUserJoined = true;
          _remoteUid = 999; // Mock remote user ID
        });
        return;
      }

      // 3. Create Rtc Engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            setState(() {
              _localUserJoined = true;
            });
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            setState(() {
              _remoteUid = remoteUid;
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            _endCallLocally('User offline');
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            setState(() {
              _localUserJoined = false;
              _remoteUid = null;
            });
          },
        ),
      );

      if (widget.isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
      }

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.joinChannel(
        token: token,
        channelId: widget.chatId,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      print('Agora error: $e');
      _endCallLocally('Agora failed: $e');
    }
  }

  void _answerCall() {
    final socket = ref.read(socketServiceProvider).socket;
    if (socket != null) {
      socket.emit('answer_call', {
        'callerId': widget.recipientId,
        'accept': true,
      });
    }
    setState(() {
      _isIncoming = false;
      _callConnected = true;
    });
    _initAgora();
    _startTimer();
  }

  void _declineCall() {
    final socket = ref.read(socketServiceProvider).socket;
    if (socket != null) {
      socket.emit('answer_call', {
        'callerId': widget.recipientId,
        'accept': false,
      });
    }
    _endCallLocally('Call Declined');
  }

  void _hangUp() {
    final socket = ref.read(socketServiceProvider).socket;
    if (socket != null) {
      socket.emit('end_call', {
        'recipientId': widget.recipientId,
      });
    }
    _endCallLocally('Call Hung Up');
  }

  void _endCallLocally(String reason) {
    _destroyAgora();
    _callTimer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(reason), backgroundColor: AppTheme.primaryPink),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _destroyAgora() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine?.muteLocalAudioStream(_muted);
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    _engine?.setEnableSpeakerphone(_speakerOn);
  }

  void _toggleCamera() {
    setState(() => _cameraOn = !_cameraOn);
    _engine?.muteLocalVideoStream(!_cameraOn);
  }

  void _switchCamera() {
    _engine?.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (_isIncoming) {
      // Callee Screen: Answer / Decline
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(color: AppTheme.backgroundDark),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: AppTheme.primaryPink, size: 50),
              const SizedBox(height: 32),
              Text(
                'Incoming ${widget.isVideo ? 'Video' : 'Audio'} Call',
                style: const TextStyle(color: AppTheme.textSecondaryLight, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                widget.recipientName,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 80),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decline Button
                  FloatingActionButton.large(
                    heroTag: 'decline',
                    onPressed: _declineCall,
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.call_end, color: Colors.white),
                  ),
                  const SizedBox(width: 48),
                  // Answer Button
                  FloatingActionButton.large(
                    heroTag: 'answer',
                    onPressed: _answerCall,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Call Screen
    return Scaffold(
      body: Stack(
        children: [
          // Video Views or Audio Screen details
          widget.isVideo
              ? _renderVideoView()
              : _renderAudioView(),

          // Overlay top info (Time details, status)
          Positioned(
            top: 56,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipientName,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _callConnected 
                          ? _formatDuration(_secondsElapsed) 
                          : 'Ringing...',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                if (widget.isVideo && _callConnected)
                  IconButton(
                    icon: const Icon(Icons.switch_camera, color: Colors.white, size: 28),
                    onPressed: _switchCamera,
                  ),
              ],
            ),
          ),

          // Bottom Control Overlay
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Speaker Button
                FloatingActionButton(
                  heroTag: 'speaker',
                  onPressed: _toggleSpeaker,
                  backgroundColor: _speakerOn ? Colors.white24 : Colors.white,
                  foregroundColor: _speakerOn ? Colors.white : Colors.black,
                  child: Icon(_speakerOn ? Icons.volume_up : Icons.volume_off),
                ),
                
                if (widget.isVideo) ...[
                  // Camera Toggle Button
                  FloatingActionButton(
                    heroTag: 'cameraToggle',
                    onPressed: _toggleCamera,
                    backgroundColor: _cameraOn ? Colors.white24 : Colors.white,
                    foregroundColor: _cameraOn ? Colors.white : Colors.black,
                    child: Icon(_cameraOn ? Icons.videocam : Icons.videocam_off),
                  ),
                ],

                // Microphone Mute Button
                FloatingActionButton(
                  heroTag: 'mute',
                  onPressed: _toggleMute,
                  backgroundColor: _muted ? Colors.white : Colors.white24,
                  foregroundColor: _muted ? Colors.black : Colors.white,
                  child: Icon(_muted ? Icons.mic_off : Icons.mic),
                ),

                // Hangup Button
                FloatingActionButton(
                  heroTag: 'hangup',
                  onPressed: _hangUp,
                  backgroundColor: Colors.redAccent,
                  child: const Icon(Icons.call_end, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderVideoView() {
    if (!_localUserJoined) {
      return Container(
        color: AppTheme.backgroundDark,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPink),
        ),
      );
    }

    if (_remoteUid != null) {
      if (_remoteUid == 999) {
        // Render Mock Development stream
        return Container(
          color: Colors.blueGrey.shade900,
          child: const Center(
            child: Text('📷 Mock Remote Video Stream', style: TextStyle(color: Colors.white70)),
          ),
        );
      }
      return Stack(
        children: [
          // Remote Video Stream
          AgoraVideoView(
            controller: VideoViewController.remote(
              rtcEngine: _engine!,
              canvas: VideoCanvas(uid: _remoteUid),
              connection: RtcConnection(channelId: widget.chatId),
            ),
          ),
          
          // Local Camera Feed (PIP Overlay)
          if (_cameraOn)
            Positioned(
              right: 16,
              bottom: 120,
              width: 110,
              height: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine!,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Container(
      color: AppTheme.backgroundDark,
      child: const Center(
        child: Text(
          'Connecting Remote User...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  Widget _renderAudioView() {
    return Container(
      color: AppTheme.backgroundDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.surfaceDark,
              child: Icon(Icons.person, size: 60, color: Colors.white54),
            ),
            const SizedBox(height: 24),
            Text(
              _callConnected ? 'Connected' : 'Calling...',
              style: const TextStyle(color: AppTheme.textSecondaryLight, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
