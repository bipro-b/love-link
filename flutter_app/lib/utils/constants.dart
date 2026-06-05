import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Server config ─────────────────────────────────────────────────────────────
class AppConfig {
  static const String defaultServerHint = 'https://love-link-uw6m.onrender.com';

  // Fixed user IDs — one phone uses 'user1', other uses 'user2'
  static const String user1Id = 'user1';
  static const String user2Id = 'user2';

  // STUN/TURN servers for WebRTC NAT traversal
  static const Map<String, dynamic> iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      // Add your TURN server here for reliability behind strict NATs:
      // {
      //   'urls': 'turn:YOUR_TURN_SERVER:3478',
      //   'username': 'user',
      //   'credential': 'pass',
      // },
    ]
  };
}

// ── Color palette ─────────────────────────────────────────────────────────────
class AppColors {
  static const Color deep       = Color(0xFF1A0A10);
  static const Color card       = Color(0xFF2A1420);
  static const Color rose       = Color(0xFFFF6B8A);
  static const Color blush      = Color(0xFFFFB3C1);
  static const Color gold       = Color(0xFFE8C97A);
  static const Color text       = Color(0xFFF5E8EE);
  static const Color muted      = Color(0xFFB08090);
  static const Color success    = Color(0xFF4CAF50);
  static const Color danger     = Color(0xFFF44336);
  static const Color glass      = Color(0x14FF6B8A);
}

// ── Theme ─────────────────────────────────────────────────────────────────────
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.deep,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.rose,
      secondary: AppColors.gold,
      surface: AppColors.card,
      background: AppColors.deep,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(
      const TextTheme(
        bodyLarge:   TextStyle(color: AppColors.text),
        bodyMedium:  TextStyle(color: AppColors.text),
        bodySmall:   TextStyle(color: AppColors.muted),
      ),
    ),
  );
}

// ── Video filter definitions ───────────────────────────────────────────────────
enum VideoFilter { none, warm, cool, bloom, noir, glam }

extension VideoFilterExt on VideoFilter {
  String get label {
    switch (this) {
      case VideoFilter.none:  return 'Normal';
      case VideoFilter.warm:  return 'Warm';
      case VideoFilter.cool:  return 'Cool';
      case VideoFilter.bloom: return 'Bloom';
      case VideoFilter.noir:  return 'Noir';
      case VideoFilter.glam:  return 'Glam';
    }
  }

  String get emoji {
    switch (this) {
      case VideoFilter.none:  return '○';
      case VideoFilter.warm:  return '🌅';
      case VideoFilter.cool:  return '❄️';
      case VideoFilter.bloom: return '🌸';
      case VideoFilter.noir:  return '🎞';
      case VideoFilter.glam:  return '✨';
    }
  }

  // ColorFilter matrix values [R,G,B,A multipliers + offsets]
  ColorFilter? get colorFilter {
    switch (this) {
      case VideoFilter.none:
        return null;
      case VideoFilter.warm:
        return const ColorFilter.matrix([
          1.2, 0.1, 0.0, 0, 10,
          0.0, 1.0, 0.0, 0,  5,
          0.0, 0.0, 0.8, 0,  0,
          0.0, 0.0, 0.0, 1,  0,
        ]);
      case VideoFilter.cool:
        return const ColorFilter.matrix([
          0.8, 0.0, 0.1, 0,   0,
          0.0, 0.9, 0.1, 0,   5,
          0.1, 0.1, 1.3, 0,  15,
          0.0, 0.0, 0.0, 1,   0,
        ]);
      case VideoFilter.bloom:
        return const ColorFilter.matrix([
          1.1, 0.1, 0.1, 0, 15,
          0.0, 1.0, 0.1, 0, 10,
          0.1, 0.1, 1.1, 0, 10,
          0.0, 0.0, 0.0, 1,  0,
        ]);
      case VideoFilter.noir:
        return const ColorFilter.matrix([
          0.33, 0.33, 0.33, 0, -10,
          0.33, 0.33, 0.33, 0, -10,
          0.33, 0.33, 0.33, 0, -10,
          0.00, 0.00, 0.00, 1,   0,
        ]);
      case VideoFilter.glam:
        return const ColorFilter.matrix([
          1.3, 0.1, 0.1, 0, 20,
          0.0, 1.1, 0.1, 0, 15,
          0.1, 0.0, 1.2, 0, 10,
          0.0, 0.0, 0.0, 1,  0,
        ]);
    }
  }
}
