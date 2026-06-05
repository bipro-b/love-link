import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/call_provider.dart';
import '../utils/constants.dart';
import '../widgets/call_controls.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({super.key});
  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _waveCtrl;
  late List<Animation<double>> _waveBars;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _waveBars = List.generate(7, (i) => Tween<double>(begin: .2, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveCtrl,
        curve: Interval(i * .1, (i * .1 + .6).clamp(0, 1), curve: Curves.easeInOut),
      ),
    ));
    _waveCtrl.repeat(reverse: true);
  }

  @override
  void dispose() { _waveCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CallProvider>();

    if (provider.callState == CallState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    final isConnecting = provider.callState == CallState.outgoingCall;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient bg
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -.2),
                radius: 1.1,
                colors: [AppColors.gold.withOpacity(.18), AppColors.deep],
              ),
            ),
          ),
          Positioned(bottom: -80, left: -60, child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.rose.withOpacity(.12), Colors.transparent]),
            ),
          )),

          SafeArea(
            child: Column(
              children: [
                // Timer
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.25),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isConnecting ? 'Calling...' : provider.callDuration,
                        style: GoogleFonts.dmSans(fontSize: 13, letterSpacing: 2, color: AppColors.text.withOpacity(.8)),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Wave bars
                if (!isConnecting) ...[
                  AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (_, __) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 5,
                        height: 50 * _waveBars[i].value,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: AppColors.gold,
                          boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(.4), blurRadius: 6)],
                        ),
                      )),
                    ),
                  ),
                  const SizedBox(height: 40),
                ] else ...[
                  // Pulsing ring for outgoing
                  _PulsingRing(),
                  const SizedBox(height: 24),
                ],

                // Avatar
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.card,
                    border: Border.all(color: AppColors.gold, width: 3),
                    boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(.35), blurRadius: 36)],
                  ),
                  child: const Center(child: Text('👩', style: TextStyle(fontSize: 50))),
                ),
                const SizedBox(height: 20),
                Text('My Love ♡',
                  style: GoogleFonts.cormorantGaramond(fontSize: 34, fontWeight: FontWeight.w300, color: AppColors.text)),
                const SizedBox(height: 8),
                Text(
                  isConnecting ? 'Ringing...' : 'Connected',
                  style: GoogleFonts.dmSans(fontSize: 12, letterSpacing: 2.5, color: AppColors.muted),
                ),

                const Spacer(),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CallControlBtn(
                        icon: provider.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        isActive: provider.isMuted,
                        onTap: provider.toggleMute,
                      ),
                      const SizedBox(width: 20),
                      // End call
                      GestureDetector(
                        onTap: () {
                          provider.hangUp();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [AppColors.danger, Color(0xFFB71C1C)]),
                            boxShadow: [BoxShadow(color: AppColors.danger.withOpacity(.4), blurRadius: 20, offset: const Offset(0,6))],
                          ),
                          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(width: 20),
                      CallControlBtn(
                        icon: provider.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        isActive: provider.isSpeakerOn,
                        activeColor: AppColors.gold,
                        onTap: provider.toggleSpeaker,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingRing extends StatefulWidget {
  @override
  State<_PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<_PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: 1 - _anim.value,
        child: Container(
          width: 80 + 80 * _anim.value,
          height: 80 + 80 * _anim.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withOpacity(.6), width: 2),
          ),
        ),
      ),
    );
  }
}
