import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  final TextEditingController _serverCtrl = TextEditingController(
    text: AppConfig.defaultServerHint,
  );
  bool _serverOk = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _serverCtrl.addListener(_validateServer);
    _validateServer();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _serverCtrl.dispose();
    super.dispose();
  }

  void _validateServer() {
    final text = _serverCtrl.text.trim();
    final valid = text.startsWith('http://') || text.startsWith('https://');
    setState(() {
      _serverOk = valid && text.length > 10;
      _serverError = null;
    });
  }

  Future<void> _selectUser(String userId) async {
    final url = _serverCtrl.text.trim();
    if (!_serverOk) {
      setState(() => _serverError = 'Enter a valid server URL (http:// or https://)');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('serverUrl', url);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomeScreen(userId: userId, serverUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _AmbientBg(),
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    _LogoWidget(),
                    const SizedBox(height: 40),

                    // ── Server URL field ──────────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'SERVER URL',
                        style: GoogleFonts.dmSans(
                          fontSize: 11, letterSpacing: 2, color: AppColors.muted),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _serverError != null
                              ? AppColors.danger
                              : (_serverOk ? AppColors.rose.withOpacity(.5) : AppColors.rose.withOpacity(.2)),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _serverCtrl,
                        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text),
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'https://your-server.railway.app',
                          hintStyle: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(
                            Icons.cloud_outlined,
                            color: _serverOk ? AppColors.rose : AppColors.muted,
                            size: 18,
                          ),
                          suffixIcon: _serverOk
                              ? const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18)
                              : null,
                        ),
                      ),
                    ),
                    if (_serverError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_serverError!,
                          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.danger)),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Deploy signaling_server/ to Railway · Render · Fly.io',
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted.withOpacity(.6)),
                    ),

                    const SizedBox(height: 32),
                    Text(
                      'Who are you?',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28, fontWeight: FontWeight.w300, color: AppColors.text, letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select once — this device will always be you',
                      style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted, letterSpacing: .5),
                    ),
                    const SizedBox(height: 32),

                    // ── User cards ──────────────────────────────────────
                    _UserCard(
                      emoji: '🧑',
                      label: 'Me (User 1)',
                      subtitle: 'Your phone in Bangladesh',
                      color: AppColors.rose,
                      enabled: _serverOk,
                      onTap: () => _selectUser(AppConfig.user1Id),
                    ),
                    const SizedBox(height: 16),
                    _UserCard(
                      emoji: '👩',
                      label: 'My Love (User 2)',
                      subtitle: 'Her phone in Australia',
                      color: AppColors.gold,
                      enabled: _serverOk,
                      onTap: () => _selectUser(AppConfig.user2Id),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String emoji, label, subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _UserCard({
    required this.emoji, required this.label,
    required this.subtitle, required this.color,
    required this.enabled, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(.12), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(.5)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.dmSans(
                      fontSize: 17, fontWeight: FontWeight.w500, color: AppColors.text)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 90, height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [AppColors.rose, Color(0xFFC2185B)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: AppColors.rose.withOpacity(.4), blurRadius: 30, offset: const Offset(0,8)),
            ],
          ),
          child: const Center(
            child: Text('♡', style: TextStyle(fontSize: 42, color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.cormorantGaramond(fontSize: 36, fontWeight: FontWeight.w300, color: AppColors.text),
            children: const [
              TextSpan(text: 'Love'),
              TextSpan(text: 'Link', style: TextStyle(color: AppColors.rose, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'JUST THE TWO OF US',
          style: GoogleFonts.dmSans(fontSize: 11, letterSpacing: 3, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _AmbientBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100, right: -80,
          child: Container(
            width: 340, height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.rose.withOpacity(.18), Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80, left: -60,
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.gold.withOpacity(.12), Colors.transparent,
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
