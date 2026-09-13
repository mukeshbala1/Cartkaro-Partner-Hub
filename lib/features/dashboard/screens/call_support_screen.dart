// ══════════════════════════════════════════════════════════════════
// call_support_screen.dart
//
// Professional Call Support screen for CartKaro Partner Hub.
// Theme color: Color.fromARGB(255, 34, 53, 84) — dark navy blue
//
// FEATURES:
//   - Direct call buttons for different departments
//   - Call timing / availability info
//   - Callback request form
//   - Recent call history (mock)
//   - WhatsApp support shortcut
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Palette {
  static const Color primary      = Color.fromARGB(255, 34, 53, 84);
  static const Color primaryLight = Color(0xFFEDF0F5);
  static const Color primaryBorder= Color(0xFFD6DCE8);
  static const Color background   = Color(0xFFF7F8FA);
  static const Color white        = Colors.white;
  static const Color darkText     = Color(0xFF1A1F2B);
  static const Color lightText    = Color(0xFF7C8499);
  static const Color border       = Color(0xFFE5E8EF);
  static const Color success      = Color(0xFF16A34A);
  static const Color successBg    = Color(0xFFDCFCE7);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningBg    = Color(0xFFFFFBEB);
}

class CallSupportScreen extends StatefulWidget {
  const CallSupportScreen({Key? key}) : super(key: key);

  @override
  State<CallSupportScreen> createState() => _CallSupportScreenState();
}

class _CallSupportScreenState extends State<CallSupportScreen> {
  final List<Map<String, dynamic>> _departments = [
    {
      'title': 'General Support',
      'subtitle': 'Account, orders & general queries',
      'icon': LucideIcons.headphones,
      'phone': '+911234567890',
      'displayPhone': '+91 12345 67890',
      'available': true,
      'hours': '24/7 Available',
    },
    {
      'title': 'Payments & Settlements',
      'subtitle': 'Wallet, withdrawals & bank issues',
      'icon': LucideIcons.wallet,
      'phone': '+911234567891',
      'displayPhone': '+91 12345 67891',
      'available': true,
      'hours': '9:00 AM – 9:00 PM',
    },
    {
      'title': 'Technical Support',
      'subtitle': 'App issues & login problems',
      'icon': LucideIcons.wrench,
      'phone': '+911234567892',
      'displayPhone': '+91 12345 67892',
      'available': true,
      'hours': '8:00 AM – 11:00 PM',
    },
    {
      'title': 'Business Verification',
      'subtitle': 'Document & registration support',
      'icon': LucideIcons.shieldCheck,
      'phone': '+911234567893',
      'displayPhone': '+91 12345 67893',
      'available': false,
      'hours': '10:00 AM – 6:00 PM',
    },
  ];

  final List<Map<String, String>> _recentCalls = [
    {'dept': 'General Support', 'date': 'Today, 11:42 AM', 'duration': '4 min 12 sec', 'status': 'completed'},
    {'dept': 'Payments & Settlements', 'date': 'Yesterday, 4:15 PM', 'duration': '2 min 05 sec', 'status': 'completed'},
    {'dept': 'Technical Support', 'date': '2 days ago, 9:30 AM', 'duration': 'Missed', 'status': 'missed'},
  ];

  Future<void> _makeCall(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack('Could not open dialer');
      }
    } catch (e) {
      _showSnack('Could not place call: $e');
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri uri = Uri.parse('https://wa.me/911234567890?text=Hi%2C%20I%20need%20help%20with%20my%20CartKaro%20Partner%20account');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack('WhatsApp is not installed');
      }
    } catch (e) {
      _showSnack('Could not open WhatsApp: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: _Palette.darkText),
    );
  }

  void _openCallbackSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CallbackRequestSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: _Palette.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: _Palette.darkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Call Support',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _Palette.darkText, letterSpacing: -0.3),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero card ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _Palette.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: _Palette.primary.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.phoneCall, color: Colors.white, size: 21),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('We\'re here to help', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2)),
                              const SizedBox(height: 3),
                              Text('Average wait time: under 2 minutes', style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.75))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _makeCall(_departments.first['phone']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.phone, size: 15, color: _Palette.primary),
                                  const SizedBox(width: 7),
                                  Text('Call Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Palette.primary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: _openWhatsApp,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.messageCircle, size: 15, color: Colors.white),
                                  const SizedBox(width: 7),
                                  const Text('WhatsApp', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Departments ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('CONTACT BY DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
              ),
              ...List.generate(_departments.length, (i) {
                final dept = _departments[i];
                final bool available = dept['available'] as bool;
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  decoration: BoxDecoration(
                    color: _Palette.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _Palette.border),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _Palette.primaryLight,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(dept['icon'] as IconData, color: _Palette.primary, size: 20),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(dept['title'] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _Palette.darkText)),
                              const SizedBox(height: 2),
                              Text(dept['subtitle'] as String, style: TextStyle(fontSize: 11.5, color: _Palette.lightText)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(color: available ? _Palette.success : _Palette.warning, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(dept['hours'] as String, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: available ? _Palette.success : _Palette.warning)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: available ? () => _makeCall(dept['phone'] as String) : () => _showSnack('This department is currently unavailable'),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: available ? _Palette.primary : _Palette.border,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.phone, size: 17, color: available ? Colors.white : _Palette.lightText),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // ── Callback request ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: GestureDetector(
                  onTap: _openCallbackSheet,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _Palette.primaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _Palette.primaryBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: _Palette.primary, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(LucideIcons.phoneOutgoing, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Request a Callback', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _Palette.primary)),
                              const SizedBox(height: 2),
                              Text('We\'ll call you back within 30 minutes', style: TextStyle(fontSize: 11.5, color: _Palette.primary.withOpacity(0.7))),
                            ],
                          ),
                        ),
                        Icon(LucideIcons.chevronRight, size: 16, color: _Palette.primary),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Recent calls ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Text('RECENT CALLS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _Palette.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Palette.border),
                ),
                child: Column(
                  children: List.generate(_recentCalls.length, (i) {
                    final call = _recentCalls[i];
                    final bool missed = call['status'] == 'missed';
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: missed ? const Color(0xFFFEF2F2) : _Palette.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  missed ? LucideIcons.phoneMissed : LucideIcons.phoneCall,
                                  size: 16,
                                  color: missed ? const Color(0xFFEF4444) : _Palette.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(call['dept']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Palette.darkText)),
                                    const SizedBox(height: 2),
                                    Text(call['date']!, style: TextStyle(fontSize: 11, color: _Palette.lightText)),
                                  ],
                                ),
                              ),
                              Text(
                                call['duration']!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: missed ? const Color(0xFFEF4444) : _Palette.lightText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i < _recentCalls.length - 1)
                          Divider(height: 1, indent: 14, endIndent: 14, color: _Palette.border),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CALLBACK REQUEST SHEET
// ════════════════════════════════════════════════════════════════

class _CallbackRequestSheet extends StatefulWidget {
  const _CallbackRequestSheet();
  @override
  State<_CallbackRequestSheet> createState() => _CallbackRequestSheetState();
}

class _CallbackRequestSheetState extends State<_CallbackRequestSheet> {
  final TextEditingController _phone = TextEditingController(text: '+91 98765 43210');
  String _selectedTopic = 'General Support';
  String _selectedTime = 'As soon as possible';

  final List<String> _topics = ['General Support', 'Payments & Settlements', 'Technical Support', 'Business Verification'];
  final List<String> _times = ['As soon as possible', 'In 1 hour', 'In 3 hours', 'Tomorrow morning'];

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _Palette.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 36, height: 4, decoration: BoxDecoration(color: _Palette.border, borderRadius: BorderRadius.circular(2)))),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Request a Callback', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _Palette.darkText, letterSpacing: -0.3)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phone Number', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Palette.lightText)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 13.5, color: _Palette.darkText),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _Palette.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _Palette.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _Palette.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _Palette.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Topic', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Palette.lightText)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: _topics.map((t) {
                final bool sel = _selectedTopic == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTopic = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? _Palette.primary : _Palette.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? _Palette.primary : _Palette.border),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : _Palette.darkText)),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Text('Preferred Time', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Palette.lightText)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: _times.map((t) {
                final bool sel = _selectedTime == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = t),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: sel ? _Palette.primaryLight : _Palette.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? _Palette.primary : _Palette.border, width: sel ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: sel ? _Palette.primary : _Palette.lightText, width: 1.5),
                          ),
                          child: sel ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: _Palette.primary, shape: BoxShape.circle))) : null,
                        ),
                        const SizedBox(width: 12),
                        Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? _Palette.primary : _Palette.darkText)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Callback requested for "$_selectedTopic" — $_selectedTime'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: _Palette.darkText,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(color: _Palette.primary, borderRadius: BorderRadius.circular(13)),
                alignment: Alignment.center,
                child: const Text('Request Callback', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}