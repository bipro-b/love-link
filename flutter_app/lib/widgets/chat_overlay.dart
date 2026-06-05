import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/call_provider.dart';
import '../utils/constants.dart';

class ChatOverlay extends StatefulWidget {
  final CallProvider provider;
  const ChatOverlay({super.key, required this.provider});
  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textCtrl.text.trim().isEmpty) return;
    widget.provider.sendMessage(_textCtrl.text);
    _textCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: MediaQuery.of(context).size.height * .45,
          decoration: BoxDecoration(
            color: AppColors.deep.withOpacity(.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.rose.withOpacity(.2)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withOpacity(.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('In-call Chat',
                  style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted, letterSpacing: 1)),
              ),
              const Divider(color: Color(0xFF3A1A28), height: 1),

              // Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.provider.messages.length,
                  itemBuilder: (context, i) {
                    final msg = widget.provider.messages[i];
                    return _MessageBubble(message: msg);
                  },
                ),
              ),

              // Input
              Padding(
                padding: EdgeInsets.only(
                  left: 12, right: 12, bottom: MediaQuery.of(context).viewInsets.bottom + 12, top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.rose.withOpacity(.2)),
                        ),
                        child: TextField(
                          controller: _textCtrl,
                          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: 'Say something sweet...',
                            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [AppColors.rose, Color(0xFFE91E63)]),
                          boxShadow: [BoxShadow(color: AppColors.rose.withOpacity(.35), blurRadius: 12)],
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .65),
        decoration: BoxDecoration(
          color: message.isMe ? AppColors.rose.withOpacity(.25) : AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(message.isMe ? 16 : 4),
            bottomRight: Radius.circular(message.isMe ? 4 : 16),
          ),
          border: Border.all(
            color: message.isMe ? AppColors.rose.withOpacity(.3) : Colors.white.withOpacity(.05),
          ),
        ),
        child: Text(
          message.text,
          style: GoogleFonts.dmSans(fontSize: 13.5, color: AppColors.text, height: 1.4),
        ),
      ),
    );
  }
}
