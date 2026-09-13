// ══════════════════════════════════════════════════════════════════
// report_problem_screen.dart
//
// Professional Report a Problem screen for CartKaro Partner Hub.
// Theme color: Color.fromARGB(255, 34, 53, 84) — dark navy blue
//
// FEATURES:
//   - Issue category selection (grid of cards)
//   - Detailed description field
//   - Photo attachment (camera/gallery, up to 3 images)
//   - Priority selector
//   - Order ID reference (optional)
//   - Submit confirmation with ticket number
//   - Recent reports / ticket history
// ══════════════════════════════════════════════════════════════════

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Palette {
  static const Color primary       = Color.fromARGB(255, 34, 53, 84);
  static const Color primaryLight  = Color(0xFFEDF0F5);
  static const Color primaryBorder = Color(0xFFD6DCE8);
  static const Color background    = Color(0xFFF7F8FA);
  static const Color white         = Colors.white;
  static const Color darkText      = Color(0xFF1A1F2B);
  static const Color lightText     = Color(0xFF7C8499);
  static const Color border        = Color(0xFFE5E8EF);
  static const Color success       = Color(0xFF16A34A);
  static const Color successBg     = Color(0xFFDCFCE7);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color warningBg     = Color(0xFFFFFBEB);
  static const Color danger        = Color(0xFFEF4444);
  static const Color dangerBg      = Color(0xFFFEF2F2);
}

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({Key? key}) : super(key: key);

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  final TextEditingController _description = TextEditingController();
  final TextEditingController _orderId = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String _priority = 'medium';
  final List<File> _attachments = [];
  bool _submitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'order',     'icon': LucideIcons.packageX,       'label': 'Order Issue'},
    {'id': 'payment',   'icon': LucideIcons.wallet,          'label': 'Payment Issue'},
    {'id': 'app',       'icon': LucideIcons.smartphone,      'label': 'App Bug'},
    {'id': 'delivery',  'icon': LucideIcons.bike,            'label': 'Delivery Issue'},
    {'id': 'account',   'icon': LucideIcons.userX,           'label': 'Account Issue'},
    {'id': 'document',  'icon': LucideIcons.fileWarning,     'label': 'Document/Verification'},
    {'id': 'customer',  'icon': LucideIcons.userCircle,      'label': 'Customer Complaint'},
    {'id': 'other',     'icon': LucideIcons.moreHorizontal,  'label': 'Other'},
  ];

  final List<Map<String, String>> _recentReports = [
    {'id': '#TKT-48213', 'title': 'Payment not credited for order #8821', 'status': 'In Progress', 'date': '2 days ago'},
    {'id': '#TKT-47990', 'title': 'App crashed during checkout', 'status': 'Resolved', 'date': '5 days ago'},
  ];

  @override
  void dispose() {
    _description.dispose();
    _orderId.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: color ?? _Palette.darkText),
    );
  }

  Future<void> _addAttachment() async {
    if (_attachments.length >= 3) {
      _showSnack('Maximum 3 photos allowed');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: _Palette.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: _Palette.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Attach Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _Palette.darkText)),
            const SizedBox(height: 16),
            _pickOption(ctx, LucideIcons.camera, 'Take Photo', () => _pickImage(ImageSource.camera, ctx)),
            const SizedBox(height: 10),
            _pickOption(ctx, LucideIcons.image, 'Choose from Gallery', () => _pickImage(ImageSource.gallery, ctx)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _pickOption(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(color: _Palette.background, borderRadius: BorderRadius.circular(13), border: Border.all(color: _Palette.border)),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: _Palette.primaryLight, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: _Palette.primary, size: 17)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _Palette.darkText)),
          const Spacer(),
          Icon(LucideIcons.chevronRight, size: 15, color: _Palette.lightText),
        ]),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx);
    try {
      final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1000);
      if (picked != null) {
        setState(() => _attachments.add(File(picked.path)));
      }
    } catch (e) {
      _showSnack('Could not attach photo: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  String _generateTicketId() {
    final now = DateTime.now();
    return '#TKT-${now.millisecondsSinceEpoch.toString().substring(7)}';
  }

  Future<void> _submitReport() async {
    if (_selectedCategory == null) {
      _showSnack('Please select an issue category', color: _Palette.danger);
      return;
    }
    if (_description.text.trim().isEmpty) {
      _showSnack('Please describe the problem', color: _Palette.danger);
      return;
    }
    if (_description.text.trim().length < 10) {
      _showSnack('Please provide more detail (at least 10 characters)', color: _Palette.danger);
      return;
    }

    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate network call
    if (!mounted) return;

    final ticketId = _generateTicketId();
    setState(() => _submitting = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _SuccessSheet(ticketId: ticketId),
    ).then((_) => Navigator.pop(context));
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
        title: const Text('Report a Problem', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _Palette.darkText, letterSpacing: -0.3)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Intro banner ─────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _Palette.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Palette.primaryBorder),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.megaphone, size: 16, color: _Palette.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tell us what went wrong — we usually respond within a few hours',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Palette.primary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Category grid ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text('WHAT\'S THE ISSUE?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final bool sel = _selectedCategory == cat['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat['id'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? _Palette.primary : _Palette.white,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: sel ? _Palette.primary : _Palette.border),
                          boxShadow: sel ? [BoxShadow(color: _Palette.primary.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))] : [],
                        ),
                        child: Row(
                          children: [
                            Icon(cat['icon'] as IconData, size: 17, color: sel ? Colors.white : _Palette.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat['label'] as String,
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : _Palette.darkText),
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Order ID (optional) ─────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('ORDER ID (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _orderId,
                  style: const TextStyle(fontSize: 13.5, color: _Palette.darkText),
                  decoration: InputDecoration(
                    hintText: 'e.g. ORD-88213',
                    hintStyle: TextStyle(color: _Palette.lightText, fontSize: 13),
                    prefixIcon: Icon(LucideIcons.hash, size: 17, color: _Palette.lightText),
                    filled: true,
                    fillColor: _Palette.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: _Palette.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: _Palette.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _Palette.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                ),
              ),

              // ── Description ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('DESCRIBE THE PROBLEM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _description,
                  maxLines: 5,
                  maxLength: 500,
                  style: const TextStyle(fontSize: 13.5, color: _Palette.darkText),
                  decoration: InputDecoration(
                    hintText: 'Please explain what happened in detail. Include any error messages you saw.',
                    hintStyle: TextStyle(color: _Palette.lightText, fontSize: 13),
                    filled: true,
                    fillColor: _Palette.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: _Palette.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: _Palette.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _Palette.primary, width: 1.5)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),

              // ── Attachments ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text('ATTACH PHOTOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
                    const SizedBox(width: 6),
                    Text('(${_attachments.length}/3)', style: TextStyle(fontSize: 11, color: _Palette.lightText)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    ..._attachments.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(e.value, width: 70, height: 70, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: -6, right: -6,
                            child: GestureDetector(
                              onTap: () => _removeAttachment(e.key),
                              child: Container(
                                width: 22, height: 22,
                                decoration: const BoxDecoration(color: _Palette.danger, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 13, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (_attachments.length < 3)
                      GestureDetector(
                        onTap: _addAttachment,
                        child: Container(
                          width: 70, height: 70,
                          decoration: BoxDecoration(
                            color: _Palette.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _Palette.border, style: BorderStyle.solid),
                          ),
                          child: Icon(LucideIcons.plus, size: 22, color: _Palette.lightText),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Priority ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text('PRIORITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _priorityChip('low', 'Low', _Palette.success, _Palette.successBg),
                    const SizedBox(width: 8),
                    _priorityChip('medium', 'Medium', _Palette.warning, _Palette.warningBg),
                    const SizedBox(width: 8),
                    _priorityChip('high', 'Urgent', _Palette.danger, _Palette.dangerBg),
                  ],
                ),
              ),

              // ── Submit button ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: GestureDetector(
                  onTap: _submitting ? null : _submitReport,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _submitting ? _Palette.primary.withOpacity(0.7) : _Palette.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                        : const Text('Submit Report', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ),

              // ── Recent reports ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                child: Text('YOUR RECENT REPORTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _Palette.lightText, letterSpacing: 0.9)),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _Palette.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _Palette.border),
                ),
                child: Column(
                  children: List.generate(_recentReports.length, (i) {
                    final r = _recentReports[i];
                    final bool resolved = r['status'] == 'Resolved';
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: resolved ? _Palette.successBg : _Palette.warningBg, borderRadius: BorderRadius.circular(10)),
                                child: Icon(resolved ? LucideIcons.checkCircle2 : LucideIcons.loader, size: 16, color: resolved ? _Palette.success : _Palette.warning),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r['title']!, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _Palette.darkText), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(r['id']!, style: TextStyle(fontSize: 10.5, color: _Palette.lightText, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 6),
                                        Text('· ${r['date']}', style: TextStyle(fontSize: 10.5, color: _Palette.lightText)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: resolved ? _Palette.successBg : _Palette.warningBg, borderRadius: BorderRadius.circular(20)),
                                child: Text(r['status']!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: resolved ? _Palette.success : _Palette.warning)),
                              ),
                            ],
                          ),
                        ),
                        if (i < _recentReports.length - 1) Divider(height: 1, indent: 14, endIndent: 14, color: _Palette.border),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(String id, String label, Color color, Color bg) {
    final bool sel = _priority == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? bg : _Palette.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? color : _Palette.border, width: sel ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(height: 5),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? color : _Palette.darkText)),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SUCCESS CONFIRMATION SHEET
// ════════════════════════════════════════════════════════════════

class _SuccessSheet extends StatelessWidget {
  final String ticketId;
  const _SuccessSheet({required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _Palette.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: _Palette.successBg, shape: BoxShape.circle),
            child: Icon(LucideIcons.checkCircle2, size: 38, color: _Palette.success),
          ),
          const SizedBox(height: 20),
          const Text('Report Submitted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _Palette.darkText)),
          const SizedBox(height: 8),
          Text(
            'Our team will review your report and get back to you within a few hours.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _Palette.lightText, height: 1.4),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(color: _Palette.primaryLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: _Palette.primaryBorder)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.ticket, size: 15, color: _Palette.primary),
                const SizedBox(width: 8),
                Text('Ticket ID: $ticketId', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _Palette.primary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: _Palette.primary, borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: const Text('Done', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}