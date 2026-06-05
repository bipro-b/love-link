import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/call_provider.dart';
import '../utils/constants.dart';
import '../widgets/filter_strip.dart';
import '../widgets/call_controls.dart';
import '../widgets/chat_overlay.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});
  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _controlsVisible = true;
  bool _pipDragging = false;
  Offset _pipOffset = const Offset(16, 120);

  @override
  void initState() {
    super.initState();
    // Auto-hide controls after 4s
    Future.delayed(const Duration(seconds: 4), _hideControls);
  }

  void _hideControls() {
    if (mounted) setState(() => _controlsVisible = false);
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    Future.delayed(const Duration(seconds: 4), _hideControls);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CallProvider>();

    // Pop when call ends
    if (provider.callState == CallState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showControls,
        child: Stack(
          children: [
            // ── Remote video (full screen) ──────────────────────────────
            Positioned.fill(
              child: provider.webRTC.currentFilter != VideoFilter.none
                  ? ColorFiltered(
                      colorFilter: provider.webRTC.currentFilter.colorFilter!,
                      child: RTCVideoView(
                        provider.webRTC.remoteRenderer,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    )
                  : RTCVideoView(
                      provider.webRTC.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
            ),

            // ── Caller name tag ─────────────────────────────────────────
            if (_controlsVisible)
              Positioned(
                bottom: 250, left: 16,
                child: _NameTag(),
              ),

            // ── Timer ───────────────────────────────────────────────────
            if (_controlsVisible)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0, right: 0,
                child: Center(child: _TimerPill(duration: provider.callDuration)),
              ),

            // ── Outgoing / connecting state ─────────────────────────────
            if (provider.callState == CallState.outgoingCall)
              _ConnectingOverlay(),

            // ── PiP (local video) ───────────────────────────────────────
            Positioned(
              right: _pipOffset.dx,
              top: _pipOffset.dy,
              child: GestureDetector(
                onPanUpdate: (d) {
                  setState(() {
                    _pipOffset = Offset(
                      (_pipOffset.dx - d.delta.dx).clamp(8, size.width - 108),
                      (_pipOffset.dy + d.delta.dy).clamp(MediaQuery.of(context).padding.top + 8, size.height - 180),
                    );
                  });
                },
                child: _PiPView(renderer: provider.webRTC.localRenderer),
              ),
            ),

            // ── Controls overlay ────────────────────────────────────────
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _VideoControlsPanel(provider: provider),
              ),
            ),

            // ── Chat overlay ────────────────────────────────────────────
            if (provider.showChat)
              ChatOverlay(provider: provider),
          ],
        ),
      ),
    );
  }
}

class _PiPView extends StatelessWidget {
  final RTCVideoRenderer renderer;
  const _PiPView({required this.renderer});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90, height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.rose.withOpacity(.4), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.5), blurRadius: 12)],
      ),
      clipBehavior: Clip.hardEdge,
      child: RTCVideoView(renderer, mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
    );
  }
}

class _TimerPill extends StatelessWidget {
  final String duration;
  const _TimerPill({required this.duration});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withOpacity(.1)),
      ),
      child: Text(
        duration,
        style: GoogleFonts.dmSans(fontSize: 13, letterSpacing: 2, color: Colors.white.withOpacity(.85)),
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(
            shape: BoxShape.circle, color: AppColors.success,
            boxShadow: [BoxShadow(color: AppColors.success.withOpacity(.6), blurRadius: 5)],
          )),
          const SizedBox(width: 7),
          Text('My Love ♡', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white.withOpacity(.85))),
        ],
      ),
    );
  }
}

class _ConnectingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👩', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 20),
            Text('Calling My Love ♡...',
              style: GoogleFonts.cormorantGaramond(fontSize: 26, color: AppColors.text)),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.rose.withOpacity(.2),
                valueColor: const AlwaysStoppedAnimation(AppColors.rose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoControlsPanel extends StatelessWidget {
  final CallProvider provider;
  const _VideoControlsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.deep, AppColors.deep.withOpacity(.95), Colors.transparent],
          stops: const [0, .7, 1],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter strip
          FilterStrip(
            currentFilter: provider.currentFilter,
            onFilterSelected: provider.setFilter,
          ),
          const SizedBox(height: 20),
          // Main controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CallControlBtn(
                icon: provider.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                isActive: provider.isMuted,
                onTap: provider.toggleMute,
              ),
              const SizedBox(width: 16),
              CallControlBtn(
                icon: provider.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                isActive: provider.isCameraOff,
                onTap: provider.toggleCamera,
              ),
              const SizedBox(width: 16),
              // End call
              GestureDetector(
                onTap: () {
                  provider.hangUp();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppColors.danger, Color(0xFFB71C1C)]),
                    boxShadow: [BoxShadow(color: AppColors.danger.withOpacity(.4), blurRadius: 20, offset: const Offset(0,6))],
                  ),
                  child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              CallControlBtn(
                icon: Icons.flip_camera_ios_rounded,
                onTap: provider.switchCamera,
              ),
              const SizedBox(width: 16),
              CallControlBtn(
                icon: Icons.chat_bubble_outline_rounded,
                isActive: provider.showChat,
                onTap: provider.toggleChat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
