import 'dart:async';
import 'package:flutter/material.dart';
import '../services/signaling_service.dart';
import '../services/webrtc_service.dart';
import '../services/notification_service.dart';

enum CallState {
  idle,
  outgoingCall,
  incomingCall,
  inCall,
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;
  ChatMessage({required this.text, required this.isMe, required this.time});
}

class CallProvider extends ChangeNotifier {
  final SignalingService  _signaling    = SignalingService();
  final WebRTCService     _webRTC       = WebRTCService();
  final NotificationService _notif      = NotificationService();

  StreamSubscription? _signalingSubscription;

  // State
  CallState  _callState       = CallState.idle;
  bool       _partnerOnline   = false;
  bool       _isVideoCall     = false;
  String     _callDuration    = '00:00';
  Timer?     _callTimer;
  int        _callSeconds     = 0;
  IncomingCallData? _pendingCall;
  List<ChatMessage> _messages = [];
  bool       _showChat        = false;

  // Getters
  CallState  get callState      => _callState;
  bool       get partnerOnline  => _partnerOnline;
  bool       get isVideoCall    => _isVideoCall;
  String     get callDuration   => _callDuration;
  bool       get isMuted        => _webRTC.isMuted;
  bool       get isCameraOff    => _webRTC.isCameraOff;
  bool       get isSpeakerOn    => _webRTC.isSpeakerOn;
  bool       get isFrontCamera  => _webRTC.isFrontCamera;
  VideoFilter get currentFilter => _webRTC.currentFilter;
  WebRTCService get webRTC      => _webRTC;
  IncomingCallData? get pendingCall => _pendingCall;
  List<ChatMessage> get messages    => _messages;
  bool get showChat => _showChat;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize(String userId, String serverUrl) async {
    await _webRTC.initialize();
    await _notif.initialize();
    await _signaling.connect(userId, serverUrl);
    _listenToSignaling();
  }

  void _listenToSignaling() {
    _signalingSubscription = _signaling.events.listen((event) {
      final type = event.keys.first;
      final data = event.values.first;

      switch (type) {
        case SignalingEvent.partnerOnline:
          _partnerOnline = true;
          notifyListeners();
          break;

        case SignalingEvent.partnerOffline:
          _partnerOnline = false;
          notifyListeners();
          break;

        case SignalingEvent.incomingCall:
          _handleIncomingCall(data as IncomingCallData);
          break;

        case SignalingEvent.callAnswered:
          _handleCallAnswered(data as Map<String, dynamic>);
          break;

        case SignalingEvent.callRejected:
          _handleCallRejected();
          break;

        case SignalingEvent.callEnded:
          _handleCallEnded();
          break;

        case SignalingEvent.iceCandidate:
          _webRTC.addIceCandidate(data as Map<String, dynamic>);
          break;

        case SignalingEvent.receiveMessage:
          _messages.add(ChatMessage(
            text: data['message'],
            isMe: false,
            time: DateTime.now(),
          ));
          notifyListeners();
          break;

        case SignalingEvent.forceDisconnect:
          _handleCallEnded();
          break;
      }
    });
  }

  // ── Outgoing call ──────────────────────────────────────────────────────────
  Future<void> startCall({required bool isVideo}) async {
    if (!_partnerOnline) return;
    _isVideoCall = isVideo;
    _callState = CallState.outgoingCall;
    notifyListeners();

    await _notif.startRingback();
    await _webRTC.startCall(isVideo: isVideo);
  }

  void _handleCallAnswered(Map<String, dynamic> answer) {
    _notif.stopRingback();
    _webRTC.handleAnswer(answer);
    _callState = CallState.inCall;
    _startTimer();
    notifyListeners();
  }

  void _handleCallRejected() {
    _notif.stopRingback();
    _callState = CallState.idle;
    notifyListeners();
  }

  // ── Incoming call ──────────────────────────────────────────────────────────
  Future<void> _handleIncomingCall(IncomingCallData data) async {
    _pendingCall = data;
    _isVideoCall = data.callType == 'video';
    _callState = CallState.incomingCall;
    await _notif.startRinging('My Love ♡');
    notifyListeners();
  }

  Future<void> acceptCall() async {
    if (_pendingCall == null) return;
    await _notif.stopRinging();
    await _webRTC.answerCall(
      offer: _pendingCall!.offer,
      isVideo: _isVideoCall,
    );
    _pendingCall = null;
    _callState = CallState.inCall;
    _startTimer();
    notifyListeners();
  }

  Future<void> rejectCall() async {
    await _notif.stopRinging();
    _signaling.rejectCall();
    _pendingCall = null;
    _callState = CallState.idle;
    notifyListeners();
  }

  // ── Hang up ────────────────────────────────────────────────────────────────
  Future<void> hangUp() async {
    _signaling.hangUp();
    await _endCallLocally();
  }

  Future<void> _handleCallEnded() async {
    await _notif.stopRinging();
    await _notif.stopRingback();
    await _endCallLocally();
  }

  Future<void> _endCallLocally() async {
    _stopTimer();
    await _webRTC.endCall();
    await _notif.releaseWakelock();
    _messages.clear();
    _showChat = false;
    _callState = CallState.idle;
    notifyListeners();
  }

  // ── In-call controls ───────────────────────────────────────────────────────
  void toggleMute()        { _webRTC.toggleMute();   notifyListeners(); }
  void toggleCamera()      { _webRTC.toggleCamera(); notifyListeners(); }
  Future<void> switchCamera() async { await _webRTC.switchCamera(); notifyListeners(); }
  void toggleSpeaker()     { _webRTC.toggleSpeaker(); notifyListeners(); }
  void setFilter(VideoFilter f) { _webRTC.setFilter(f); notifyListeners(); }
  void toggleChat()        { _showChat = !_showChat; notifyListeners(); }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _signaling.sendMessage(text.trim());
    _messages.add(ChatMessage(text: text.trim(), isMe: true, time: DateTime.now()));
    notifyListeners();
  }

  // ── Timer ──────────────────────────────────────────────────────────────────
  void _startTimer() {
    _callSeconds = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _callSeconds++;
      final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
      final s = (_callSeconds % 60).toString().padLeft(2, '0');
      _callDuration = '$m:$s';
      notifyListeners();
    });
  }

  void _stopTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _callSeconds = 0;
    _callDuration = '00:00';
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _signalingSubscription?.cancel();
    _stopTimer();
    _webRTC.dispose();
    _notif.dispose();
    _signaling.disconnect();
    super.dispose();
  }
}
