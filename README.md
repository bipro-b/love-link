# 💕 LoveLink — Private Call App

A fully private, just-for-two video & audio call app built with Flutter + WebRTC + Node.js.

---

## Project Structure

```
lovelink/
├── signaling_server/      # Node.js backend (Socket.io)
│   ├── server.js
│   └── package.json
└── flutter_app/           # Flutter mobile app
    ├── lib/
    │   ├── main.dart
    │   ├── utils/constants.dart       # ← Config & theme
    │   ├── services/
    │   │   ├── signaling_service.dart # Socket.io client
    │   │   ├── webrtc_service.dart    # WebRTC peer connection
    │   │   ├── notification_service.dart # Ringtone & notifications
    │   │   └── call_provider.dart     # State management
    │   ├── screens/
    │   │   ├── setup_screen.dart      # First-time user selection
    │   │   ├── home_screen.dart       # Main screen
    │   │   ├── incoming_call_screen.dart
    │   │   ├── video_call_screen.dart
    │   │   └── audio_call_screen.dart
    │   └── widgets/
    │       ├── filter_strip.dart      # Video filters UI
    │       ├── call_controls.dart     # Button widget
    │       └── chat_overlay.dart      # In-call chat
    ├── android/app/src/main/AndroidManifest.xml
    └── pubspec.yaml
```

---

## ⚙️ Step 1: Configure the Server URL

Open `flutter_app/lib/utils/constants.dart` and set your server address:

```dart
static const String signalingServer = 'http://YOUR_SERVER_IP:3000';
```

- **For local testing**: Use your computer's local IP, e.g. `http://192.168.1.100:3000`
- **For production**: Deploy to a VPS (DigitalOcean, Railway, Render) and use your domain

---

## 🚀 Step 2: Run the Signaling Server

```bash
cd signaling_server
npm install
npm start
```

The server runs on port 3000. For production:
```bash
# Install PM2 for process management
npm install -g pm2
pm2 start server.js --name lovelink
pm2 save
```

---

## 📱 Step 3: Build the Flutter App

### Prerequisites
- Flutter SDK 3.x+
- Android Studio / Xcode

### Add sound assets
Place these files in `flutter_app/assets/sounds/`:
- `ringtone.mp3` — incoming call ringtone
- `ringback.mp3` — outgoing call tone

### Install dependencies
```bash
cd flutter_app
flutter pub get
```

### Run on device
```bash
flutter run --release
```

### Build APK (Android)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build for iOS
```bash
flutter build ios --release
# Then archive in Xcode
```

---

## 📲 Step 4: Install on Both Phones

1. Install the APK on **your phone** → select **"Me (User 1)"** on first launch
2. Install the APK on **her phone** → select **"My Love (User 2)"** on first launch

That's it. Both phones connect to the same server and can call each other.

---

## ✨ Features

| Feature | Details |
|---|---|
| 📹 Video Call | HD video via WebRTC, hardware accelerated |
| 🎙 Audio Call | Crystal clear with echo cancellation & noise suppression |
| 🔔 Ringtone | Full-screen incoming call notification with custom ringtone |
| 🎨 Video Filters | 6 real-time color filters: Normal, Warm, Cool, Bloom, Noir, Glam |
| 🔄 Camera Flip | Switch front/back camera during call |
| 🔇 Mute / Camera off | Toggle anytime during call |
| 🔊 Speaker toggle | Earpiece or speakerphone |
| 💬 In-call Chat | Send text messages during call |
| 📍 Draggable PiP | Drag your self-view anywhere on screen |
| 💚 Online status | Shows when partner is online |
| ⏱ Call timer | Live call duration display |
| 🌙 Beautiful dark UI | Rose + gold themed, Cormorant Garamond typography |

---

## 🌐 For Internet Calls (different networks)

WebRTC needs STUN/TURN servers to work across different WiFi/mobile networks.

**STUN** (free, Google's): already configured — works for ~70% of cases.

**TURN** (needed for strict NAT/corporate networks):
1. Set up a free TURN server: [Coturn](https://github.com/coturn/coturn) on any VPS
2. Or use a free tier: [Metered.ca](https://www.metered.ca/tools/openrelay/)
3. Add to `AppConfig.iceServers` in `constants.dart`:

```dart
{
  'urls': 'turn:YOUR_TURN_SERVER:3478',
  'username': 'youruser',
  'credential': 'yourpassword',
}
```

---

## 🔒 Privacy

- No third-party servers
- No data stored (calls are peer-to-peer after signaling)
- Only your signaling server sees connection requests (not call content)
- All media is encrypted via DTLS-SRTP (WebRTC standard)
