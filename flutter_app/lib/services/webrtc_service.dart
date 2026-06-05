import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../utils/constants.dart';
import 'signaling_service.dart';

class WebRTCService extends ChangeNotifier {
  final SignalingService _signaling = SignalingService();

  // Renderers
  final RTCVideoRenderer localRenderer  = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream?       _localStream;

  // State
  bool _isInCall      = false;
  bool _isMuted       = false;
  bool _isCameraOff   = false;
  bool _isSpeakerOn   = true;
  bool _isFrontCamera = true;
  VideoFilter _currentFilter = VideoFilter.none;

  bool get isInCall      => _isInCall;
  bool get isMuted       => _isMuted;
  bool get isCameraOff   => _isCameraOff;
  bool get isSpeakerOn   => _isSpeakerOn;
  bool get isFrontCamera => _isFrontCamera;
  VideoFilter get currentFilter => _currentFilter;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  // ── Create peer connection ─────────────────────────────────────────────────
  Future<RTCPeerConnection> _createPeerConnection() async {
    final pc = await createPeerConnection(AppConfig.iceServers);

    pc.onIceCandidate = (candidate) {
      _signaling.sendIceCandidate(candidate.toMap());
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
        notifyListeners();
      }
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        endCall();
      }
      notifyListeners();
    };

    return pc;
  }

  // ── Get local media ────────────────────────────────────────────────────────
  Future<MediaStream> _getLocalStream({required bool isVideo}) async {
    final constraints = <String, dynamic>{
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl':  true,
      },
      'video': isVideo
          ? {
              'facingMode': _isFrontCamera ? 'user' : 'environment',
              'width':  {'ideal': 1280},
              'height': {'ideal': 720},
              'frameRate': {'ideal': 30},
            }
          : false,
    };
    return await navigator.mediaDevices.getUserMedia(constraints);
  }

  // ── Initiate a call ────────────────────────────────────────────────────────
  Future<void> startCall({required bool isVideo}) async {
    _localStream = await _getLocalStream(isVideo: isVideo);
    localRenderer.srcObject = _localStream;

    _peerConnection = await _createPeerConnection();

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });
    await _peerConnection!.setLocalDescription(offer);

    _signaling.callUser(
      callType: isVideo ? 'video' : 'audio',
      offer: offer.toMap(),
    );

    _isInCall = true;
    notifyListeners();
  }

  // ── Handle incoming call ───────────────────────────────────────────────────
  Future<void> answerCall({
    required Map<String, dynamic> offer,
    required bool isVideo,
  }) async {
    _localStream = await _getLocalStream(isVideo: isVideo);
    localRenderer.srcObject = _localStream;

    _peerConnection = await _createPeerConnection();

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(offer['sdp'], offer['type']),
    );

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    _signaling.answerCall(answer.toMap());

    _isInCall = true;
    notifyListeners();
  }

  // ── Handle answer from callee ──────────────────────────────────────────────
  Future<void> handleAnswer(Map<String, dynamic> answer) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
  }

  // ── Add remote ICE candidate ───────────────────────────────────────────────
  Future<void> addIceCandidate(Map<String, dynamic> candidateMap) async {
    try {
      await _peerConnection?.addCandidate(
        RTCIceCandidate(
          candidateMap['candidate'],
          candidateMap['sdpMid'],
          candidateMap['sdpMLineIndex'],
        ),
      );
    } catch (e) {
      debugPrint('ICE candidate error: $e');
    }
  }

  // ── End call ───────────────────────────────────────────────────────────────
  Future<void> endCall() async {
    await _peerConnection?.close();
    _peerConnection = null;

    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;

    localRenderer.srcObject  = null;
    remoteRenderer.srcObject = null;

    _isInCall    = false;
    _isMuted     = false;
    _isCameraOff = false;
    _currentFilter = VideoFilter.none;
    notifyListeners();
  }

  // ── Controls ───────────────────────────────────────────────────────────────
  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_isMuted);
    notifyListeners();
  }

  void toggleCamera() {
    _isCameraOff = !_isCameraOff;
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !_isCameraOff);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    _isFrontCamera = !_isFrontCamera;
    final videoTrack = _localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
    }
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    // Platform channel to toggle speaker (handled via audioplayers)
    Helper.setSpeakerphoneOn(_isSpeakerOn);
    notifyListeners();
  }

  void setFilter(VideoFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  // ── Dispose ────────────────────────────────────────────────────────────────
  @override
  Future<void> dispose() async {
    await endCall();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    super.dispose();
  }
}
