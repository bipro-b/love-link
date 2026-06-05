import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/call_provider.dart';
import '../utils/constants.dart';
import 'incoming_call_screen.dart';
import 'video_call_screen.dart';
import 'audio_call_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallProvider>().initialize(widget.userId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, _) {
        // Route to appropriate screen based on call state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleCallStateNavigation(context, provider);
        });

        return Scaffold(
          body: Stack(
            children: [
              _AmbientBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(userId: widget.userId),
                    const Spacer(),
                    _LogoSection(),
                    const SizedBox(height: 48),
                    _AvatarPair(isPartnerOnline: provider.partnerOnline),
                    const SizedBox(height: 56),
                    _CallButtons(
                      isPartnerOnline: provider.partnerOnline,
                      onVideoCall: () => provider.startCall(isVideo: true),
                      onAudioCall: () => provider.startCall(isVideo: false),
                    ),
                    const Spacer(),
                    _PartnerStatusBar(isOnline: provider.partnerOnline),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCallStateNavigation(BuildContext context, CallProvider provider) {
    switch (provider.callState) {
      case CallState.incomingCall:
        Navigator.of(context).push(
          _slideRoute(const IncomingCallScreen()),
        );
        break;
      case CallState.outgoingCall:
      case CallState.inCall:
        if (provider.isVideoCall) {
          Navigator.of(context).push(_slideRoute(const VideoCallScreen()));
        } else {
          Navigator.of(context).push(_slideRoute(const AudioCallScreen()));
        }
        break;
      case CallState.idle:
        break;
    }
  }

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      );
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String userId;
  const _TopBar({required this.userId});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            userId == AppConfig.user1Id ? 'Me' : 'My Love',
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted, letterSpacing: 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.rose.withOpacity(.12),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.rose.withOpacity(.25)),
            ),
            child: Text(
              'LoveLink',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 14, color: AppColors.rose, fontStyle: FontStyle.italic),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.muted, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 82, height: 82,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [AppColors.rose, Color(0xFFC2185B)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppColors.rose.withOpacity(.42), blurRadius: 32, offset: const Offset(0, 8)),
            ],
          ),
          child: const Center(child: Text('♡', style: TextStyle(fontSize: 40, color: Colors.white))),
        ),
        const SizedBox(height: 14),
        RichText(
          text: TextSpan(
            style: GoogleFonts.cormorantGaramond(fontSize: 34, fontWeight: FontWeight.w300, color: AppColors.text),
            children: const [
              TextSpan(text: 'Love'),
              TextSpan(text: 'Link', style: TextStyle(color: AppColors.rose, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'JUST THE TWO OF US',
          style: GoogleFonts.dmSans(fontSize: 10, letterSpacing: 3.5, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _AvatarPair extends StatefulWidget {
  final bool isPartnerOnline;
  const _AvatarPair({required this.isPartnerOnline});
  @override
  State<_AvatarPair> createState() => _AvatarPairState();
}

class _AvatarPairState extends State<_AvatarPair> with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartAnim;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heartAnim = Tween<double>(begin: 1.0, end: 1.28)
        .animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeInOut));
    _heartCtrl.repeat(reverse: true);
  }

  @override
  void dispose() { _heartCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Avatar(emoji: '🧑', color: AppColors.rose, isOnline: true),
        const SizedBox(width: 16),
        AnimatedBuilder(
          animation: _heartAnim,
          builder: (_, __) => Transform.scale(
            scale: _heartAnim.value,
            child: Text('♡', style: TextStyle(
              fontSize: 22,
              color: AppColors.rose,
              shadows: [Shadow(color: AppColors.rose.withOpacity(.5), blurRadius: 8)],
            )),
          ),
        ),
        const SizedBox(width: 16),
        _Avatar(emoji: '👩', color: AppColors.gold, isOnline: widget.isPartnerOnline),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final String emoji;
  final Color color;
  final bool isOnline;
  const _Avatar({required this.emoji, required this.color, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 68, height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.card,
            border: Border.all(color: color.withOpacity(.5), width: 2),
            boxShadow: [BoxShadow(color: color.withOpacity(.2), blurRadius: 16)],
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))),
        ),
        Positioned(
          bottom: 2, right: 2,
          child: Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.muted,
              border: Border.all(color: AppColors.deep, width: 2),
              boxShadow: isOnline
                  ? [BoxShadow(color: AppColors.success.withOpacity(.6), blurRadius: 6)]
                  : [],
            ),
          ),
        ),
      ],
    );
  }
}

class _CallButtons extends StatelessWidget {
  final bool isPartnerOnline;
  final VoidCallback onVideoCall, onAudioCall;
  const _CallButtons({required this.isPartnerOnline, required this.onVideoCall, required this.onAudioCall});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CallButton(
          icon: Icons.videocam_rounded,
          label: 'VIDEO',
          gradient: const LinearGradient(colors: [AppColors.rose, Color(0xFFE91E63)]),
          shadowColor: AppColors.rose,
          enabled: isPartnerOnline,
          onTap: onVideoCall,
        ),
        const SizedBox(width: 32),
        _CallButton(
          icon: Icons.call_rounded,
          label: 'VOICE',
          gradient: const LinearGradient(colors: [AppColors.gold, Color(0xFFC97D20)]),
          shadowColor: AppColors.gold,
          enabled: isPartnerOnline,
          onTap: onAudioCall,
        ),
      ],
    );
  }
}

class _CallButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final Color shadowColor;
  final bool enabled;
  final VoidCallback onTap;
  const _CallButton({
    required this.icon, required this.label, required this.gradient,
    required this.shadowColor, required this.enabled, required this.onTap,
  });
  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1, end: .93).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => _ctrl.forward(),
          onTapUp: (_) { _ctrl.reverse(); if (widget.enabled) widget.onTap(); },
          onTapCancel: () => _ctrl.reverse(),
          child: AnimatedBuilder(
            animation: _scale,
            builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
            child: Opacity(
              opacity: widget.enabled ? 1.0 : .35,
              child: Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.gradient,
                  boxShadow: widget.enabled
                      ? [BoxShadow(color: widget.shadowColor.withOpacity(.4), blurRadius: 24, offset: const Offset(0, 6))]
                      : [],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(widget.label, style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted, letterSpacing: 2)),
      ],
    );
  }
}

class _PartnerStatusBar extends StatelessWidget {
  final bool isOnline;
  const _PartnerStatusBar({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.rose.withOpacity(.2)),
        color: AppColors.rose.withOpacity(.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.muted,
              boxShadow: isOnline ? [BoxShadow(color: AppColors.success.withOpacity(.6), blurRadius: 6)] : [],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'She\'s online · ready to call' : 'Waiting for her to come online...',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, letterSpacing: .5),
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -120, right: -100, child: _GlowCircle(color: AppColors.rose, size: 400, opacity: .16)),
        Positioned(bottom: -80, left: -80, child: _GlowCircle(color: AppColors.gold, size: 280, opacity: .10)),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color; final double size, opacity;
  const _GlowCircle({required this.color, required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
    ),
  );
}
