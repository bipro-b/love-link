import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/call_provider.dart';
import '../utils/constants.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key});
  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _rippleCtls;
  late List<Animation<double>> _rippleAnims;

  @override
  void initState() {
    super.initState();
    _rippleCtls = List.generate(3, (i) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    ));
    _rippleAnims = _rippleCtls.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 600), () {
        if (mounted) _rippleCtls[i].repeat();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _rippleCtls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CallProvider>();

    // Pop when call state changes away from incomingCall
    if (provider.callState != CallState.incomingCall &&
        provider.callState != CallState.inCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Radial gradient bg
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.3),
                radius: 1.2,
                colors: [AppColors.rose.withOpacity(.3), AppColors.deep],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Ripples + avatar
                SizedBox(
                  width: 220, height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ripple layers
                      for (var i = 0; i < 3; i++)
                        AnimatedBuilder(
                          animation: _rippleAnims[i],
                          builder: (_, __) => Transform.scale(
                            scale: .5 + _rippleAnims[i].value * .6,
                            child: Opacity(
                              opacity: (1 - _rippleAnims[i].value).clamp(.0, .7),
                              child: Container(
                                width: 200, height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.rose.withOpacity(.5), width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Avatar circle
                      Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.card,
                          border: Border.all(color: AppColors.rose, width: 3),
                          boxShadow: [
                            BoxShadow(color: AppColors.rose.withOpacity(.4), blurRadius: 30),
                          ],
                        ),
                        child: const Center(child: Text('👩', style: TextStyle(fontSize: 50))),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'My Love ♡',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 34, fontWeight: FontWeight.w300, color: AppColors.text),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.pendingCall?.callType == 'video'
                      ? 'INCOMING VIDEO CALL'
                      : 'INCOMING VOICE CALL',
                  style: GoogleFonts.dmSans(
                    fontSize: 11, letterSpacing: 3, color: AppColors.muted),
                ),

                const Spacer(),

                // Answer / Decline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ActionBtn(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        color: AppColors.danger,
                        onTap: () {
                          provider.rejectCall();
                          Navigator.of(context).pop();
                        },
                      ),
                      _ActionBtn(
                        icon: Icons.call_rounded,
                        label: 'Answer',
                        color: AppColors.success,
                        onTap: () {
                          provider.acceptCall();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withOpacity(.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: color.withOpacity(.4), blurRadius: 20, offset: const Offset(0,6))],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}
