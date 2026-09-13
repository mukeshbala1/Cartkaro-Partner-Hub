// ══════════════════════════════════════════════════════════════════
// chat_support_screen.dart
//
// Chat Support — functional chat interface. Wire `_sendToBackend`
// to your real support/chat API later; UI and message flow already
// work end-to-end with a mock auto-reply.
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

enum _Sender { user, agent, system }

class _ChatMessage {
  final String text;
  final _Sender sender;
  final DateTime time;
  _ChatMessage({required this.text, required this.sender, required this.time});
}

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({Key? key}) : super(key: key);

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _agentTyping = false;

  static const List<String> _quickReplies = [
    'Order issue',
    'Payment delay',
    'Update business info',
    'App not working',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: 'Hi! I\'m CartKaro Support. How can I help you with your business today?',
      sender: _Sender.agent,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), sender: _Sender.user, time: DateTime.now()));
      _input.clear();
      _agentTyping = true;
    });
    _scrollToBottom();

    // TODO: replace with real API call to your support backend.
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      setState(() {
        _agentTyping = false;
        _messages.add(_ChatMessage(
          text: 'Thanks for the details. A support agent will review this and respond shortly. Your reference ID is #CK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.',
          sender: _Sender.agent,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  String _fmtTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.headset_mic, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CartKaro Support', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white)),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('Online', style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                itemCount: _messages.length + (_agentTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _messages.length) return _typingBubble();
                  return _bubble(_messages[i]);
                },
              ),
            ),

            // ── Quick replies ────────────────────────────────────
            if (_messages.length <= 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickReplies.map((q) {
                    return GestureDetector(
                      onTap: () => _send(q),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.kPrimary.withOpacity(0.22)),
                        ),
                        child: Text(q, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kPrimary)),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // ── Input bar ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                border: Border(top: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.kDarkText),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.kLightText),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        ),
                        onSubmitted: _send,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _send(_input.text),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(21)),
                      child: const Icon(LucideIcons.send, color: Colors.white, size: 17),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_ChatMessage m) {
    final bool isUser = m.sender == _Sender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.kPrimary : AppColors.kWhite,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: AppColors.kBorder.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: isUser ? Colors.white : AppColors.kDarkText, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              _fmtTime(m.time),
              style: TextStyle(fontSize: 10, color: isUser ? Colors.white60 : AppColors.kLightText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.kWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4), bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => Padding(
            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: _Dot(delay: i * 150),
          )),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(_ctrl),
      child: Container(width: 7, height: 7, decoration: BoxDecoration(color: AppColors.kPrimary, shape: BoxShape.circle)),
    );
  }
}