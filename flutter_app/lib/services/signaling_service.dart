import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../utils/constants.dart';

enum SignalingEvent {
  partnerOnline,
  partnerOffline,
  incomingCall,
  callAnswered,
  callRejected,
  callEnded,
  iceCandidate,
  receiveMessage,
  forceDisconnect,
}

class IncomingCallData {
  final String callType; // 'video' | 'audio'
  final Map<String, dynamic> offer;
  final String callerId;
  IncomingCallData({required this.callType, required this.offer, required this.callerId});
}

class SignalingService {
  static final SignalingService _instance = SignalingService._internal();
  factory SignalingService() => _instance;
  SignalingService._internal();

  late io.Socket _socket;
  String? _userId;
  bool _isConnected = false;

  final StreamController<Map<SignalingEvent, dynamic>> _eventController =
      StreamController.broadcast();

  Stream<Map<SignalingEvent, dynamic>> get events => _eventController.stream;
  bool get isConnected => _isConnected;
  String? get userId => _userId;

  // ── Connect & Register ────────────────────────────────────────────────────
  Future<void> connect(String userId) async {
    _userId = userId;

    _socket = io.io(
      AppConfig.signalingServer,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .enableAutoConnect()
          .build(),
    );

    _socket.onConnect((_) {
      _isConnected = true;
      _socket.emit('register', {'userId': userId});
    });

    _socket.onDisconnect((_) => _isConnected = false);

    _socket.on('partner_status', (data) {
      final online = data['online'] as bool;
      _emit(online ? SignalingEvent.partnerOnline : SignalingEvent.partnerOffline, data);
    });

    _socket.on('incoming_call', (data) {
      _emit(SignalingEvent.incomingCall, IncomingCallData(
        callType: data['callType'],
        offer: Map<String, dynamic>.from(data['offer']),
        callerId: data['callerId'],
      ));
    });

    _socket.on('call_answered', (data) {
      _emit(SignalingEvent.callAnswered, Map<String, dynamic>.from(data['answer']));
    });

    _socket.on('call_rejected', (_) => _emit(SignalingEvent.callRejected, null));

    _socket.on('call_ended', (_) => _emit(SignalingEvent.callEnded, null));

    _socket.on('ice_candidate', (data) {
      _emit(SignalingEvent.iceCandidate, Map<String, dynamic>.from(data['candidate']));
    });

    _socket.on('receive_message', (data) {
      _emit(SignalingEvent.receiveMessage, data);
    });

    _socket.on('force_disconnect', (data) {
      _emit(SignalingEvent.forceDisconnect, data);
    });
  }

  void _emit(SignalingEvent event, dynamic data) {
    _eventController.add({event: data});
  }

  // ── Outgoing actions ──────────────────────────────────────────────────────
  void callUser({required String callType, required Map<String, dynamic> offer}) {
    _socket.emit('call_user', {'callType': callType, 'offer': offer});
  }

  void answerCall(Map<String, dynamic> answer) {
    _socket.emit('call_answer', {'answer': answer});
  }

  void rejectCall() {
    _socket.emit('call_rejected');
  }

  void hangUp() {
    _socket.emit('hang_up');
  }

  void sendIceCandidate(Map<String, dynamic> candidate) {
    _socket.emit('ice_candidate', {'candidate': candidate});
  }

  void sendMessage(String message) {
    _socket.emit('send_message', {'message': message});
  }

  void disconnect() {
    _socket.disconnect();
    _socket.dispose();
  }
}
