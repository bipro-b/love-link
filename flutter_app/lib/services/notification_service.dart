import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _ringPlayer    = AudioPlayer();
  final AudioPlayer _ringbackPlayer = AudioPlayer();

  bool _isRinging = false;

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Set up audio to play through earpiece/speaker properly
    await _ringPlayer.setReleaseMode(ReleaseMode.loop);
    await _ringbackPlayer.setReleaseMode(ReleaseMode.loop);
  }

  // ── Incoming ring ─────────────────────────────────────────────────────────
  Future<void> startRinging(String callerName) async {
    if (_isRinging) return;
    _isRinging = true;

    // Keep screen on
    await WakelockPlus.enable();

    // Play ringtone
    await _ringPlayer.play(AssetSource('sounds/ringtone.mp3'), volume: 1.0);

    // Show heads-up notification
    const androidDetails = AndroidNotificationDetails(
      'lovelink_call',
      'Incoming Call',
      channelDescription: 'LoveLink incoming call notifications',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      sound: RawResourceAndroidNotificationSound('ringtone'),
    );

    const notifDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        sound: 'ringtone.mp3',
      ),
    );

    await _notifications.show(
      42,
      '📞 Incoming Call',
      '$callerName is calling you...',
      notifDetails,
    );
  }

  // ── Stop ringing ──────────────────────────────────────────────────────────
  Future<void> stopRinging() async {
    _isRinging = false;
    await _ringPlayer.stop();
    await _notifications.cancel(42);
  }

  // ── Ringback tone (outgoing call waiting) ─────────────────────────────────
  Future<void> startRingback() async {
    await _ringbackPlayer.play(AssetSource('sounds/ringback.mp3'), volume: 0.8);
  }

  Future<void> stopRingback() async {
    await _ringbackPlayer.stop();
  }

  // ── Release wakelock ──────────────────────────────────────────────────────
  Future<void> releaseWakelock() async {
    await WakelockPlus.disable();
  }

  void dispose() {
    _ringPlayer.dispose();
    _ringbackPlayer.dispose();
  }
}
