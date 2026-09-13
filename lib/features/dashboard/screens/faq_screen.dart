// ══════════════════════════════════════════════════════════════════
// faq_screen.dart
//
// Professional FAQ screen for CartKaro Partner Hub.
// Theme color: Color.fromARGB(255, 34, 53, 84) — dark navy blue
//
// FEATURES:
//   - Search bar with live filtering
//   - Category chips (filter by topic)
//   - Expandable accordion-style Q&A
//   - "Was this helpful?" feedback per answer
//   - Empty state when search finds nothing
//   - Contact support fallback at bottom
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
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
}

class _FaqItem {
  final String question;
  final String answer;
  final String category;
  bool? helpful; // null = not voted, true = yes, false = no

  _FaqItem({required this.question, required this.answer, required this.category, this.helpful});
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';
  int? _expandedIndex;

  final List<String> _categories = ['All', 'Orders', 'Payments', 'Account', 'Delivery', 'Products', 'Verification'];

  late List<_FaqItem> _faqs;

  @override
  void initState() {
    super.initState();
    _faqs = [
      _FaqItem(
        category: 'Orders',
        question: 'How do I accept or reject a new order?',
        answer: 'When a new order arrives, you\'ll receive a notification with sound. Open the Orders tab to see order details, then tap "Accept" to confirm or "Reject" if you cannot fulfill it. You can also enable Auto Accept Orders from Settings to skip manual confirmation.',
      ),
      _FaqItem(
        category: 'Orders',
        question: 'What happens if I miss an order notification?',
        answer: 'If an order is not accepted within the response window (usually 2 minutes), it may be automatically reassigned to another nearby partner. We recommend keeping notification sound and vibration enabled to avoid missed orders.',
      ),
      _FaqItem(
        category: 'Payments',
        question: 'When will I receive my earnings?',
        answer: 'Earnings are settled to your linked bank account every 24–48 hours after order completion. You can track pending and completed settlements under Payments & Earnings → Settlement History in your Settings.',
      ),
      _FaqItem(
        category: 'Payments',
        question: 'How do I change my bank account details?',
        answer: 'Go to Settings → Payments & Earnings → Change Bank Account. Fill in your new account holder name, account number, IFSC code and bank name. Changes are submitted for verification and typically approved within 24–48 hours.',
      ),
      _FaqItem(
        category: 'Payments',
        question: 'Why was my withdrawal delayed?',
        answer: 'Withdrawals can be delayed due to bank verification holds, incorrect account details, or weekend/holiday processing schedules. If a withdrawal is delayed more than 48 hours, please contact Payments Support directly.',
      ),
      _FaqItem(
        category: 'Account',
        question: 'How do I add a new business to my account?',
        answer: 'From Settings, go to Manage Businesses → Add New Business. Choose your business type (Grocery, Restaurant, or Medical Store) and complete the registration form. Your new business will appear as "Pending Review" until approved.',
      ),
      _FaqItem(
        category: 'Account',
        question: 'Can I run multiple businesses from one account?',
        answer: 'Yes. CartKaro Partner Hub supports managing multiple approved businesses from a single account. Use the Manage Businesses section in Settings to switch between them instantly.',
      ),
      _FaqItem(
        category: 'Account',
        question: 'How do I change my login PIN?',
        answer: 'Go to Settings → Security → Change Login PIN. Enter your current PIN, followed by your new 4-digit PIN twice to confirm. For added security, you can also enable Fingerprint Login.',
      ),
      _FaqItem(
        category: 'Delivery',
        question: 'How do I set my delivery radius?',
        answer: 'In Settings → Delivery Settings → Delivery Radius, drag the slider to set how far (in kilometers) you are willing to deliver. A smaller radius means faster deliveries; a larger radius reaches more customers.',
      ),
      _FaqItem(
        category: 'Delivery',
        question: 'What is the difference between CartKaro Delivery and Self Delivery?',
        answer: 'CartKaro Delivery assigns a delivery partner automatically through our platform. Self Delivery means you or your own staff handle deliveries. You can switch between the two anytime in Delivery Settings.',
      ),
      _FaqItem(
        category: 'Delivery',
        question: 'How do I set my delivery availability by day?',
        answer: 'Open Settings → Delivery Settings → Delivery Availability. Toggle "All Days" for full-week delivery, or select specific days individually if you only deliver on certain days.',
      ),
      _FaqItem(
        category: 'Products',
        question: 'How do I mark an item as out of stock?',
        answer: 'Go to Settings → Out of Stock Management to choose how out-of-stock items behave — auto-hide them, mark them unavailable, allow pre-orders, or notify customers when restocked.',
      ),
      _FaqItem(
        category: 'Products',
        question: 'How do I update which categories I sell?',
        answer: 'Open Settings → Selling Categories → Edit Selling Categories. Tap to select or deselect categories. Disabling a category hides related items from customers without deleting them.',
      ),
      _FaqItem(
        category: 'Verification',
        question: 'Why is my document marked as Pending?',
        answer: 'Newly uploaded or updated documents go through manual verification, which usually takes 24–48 hours. You\'ll see the status change to Verified once approved, or Expired if renewal is needed.',
      ),
      _FaqItem(
        category: 'Verification',
        question: 'What documents are required for my business type?',
        answer: 'Grocery and Restaurant businesses need FSSAI Certificate, GST Certificate, Trade License, PAN, and Aadhaar. Medical stores need Drug License, Pharmaceutical License, GST Certificate, PAN, and Aadhaar.',
      ),
    ];
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filtered {
    return _faqs.where((f) {
      final matchesCategory = _selectedCategory == 'All' || f.category == _selectedCategory;
      final matchesQuery = _query.isEmpty ||
          f.question.toLowerCase().contains(_query.toLowerCase()) ||
          f.answer.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
        title: const Text('FAQs', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _Palette.darkText, letterSpacing: -0.3)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Search bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: _Palette.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Palette.border),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(fontSize: 13.5, color: _Palette.darkText),
                  decoration: InputDecoration(
                    hintText: 'Search for help...',
                    hintStyle: TextStyle(color: _Palette.lightText, fontSize: 13.5),
                    prefixIcon: Icon(LucideIcons.search, size: 18, color: _Palette.lightText),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(LucideIcons.x, size: 16, color: _Palette.lightText),
                            onPressed: () => setState(() { _search.clear(); _query = ''; }),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  ),
                ),
              ),
            ),

            // ── Category chips ──────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 16),
                itemCount: _categories.length,
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final bool sel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _Palette.primary : _Palette.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sel ? _Palette.primary : _Palette.border),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          cat,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: sel ? Colors.white : _Palette.darkText),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Results count ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} ${filtered.length == 1 ? 'result' : 'results'}',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _Palette.lightText),
                  ),
                ],
              ),
            ),

            // ── FAQ list ──────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final bool expanded = _expandedIndex == i;
                        return _buildFaqCard(item, i, expanded);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: _Palette.primaryLight, borderRadius: BorderRadius.circular(20)),
              child: Icon(LucideIcons.searchX, size: 30, color: _Palette.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 18),
            const Text('No results found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _Palette.darkText)),
            const SizedBox(height: 6),
            Text(
              'Try a different search term or browse all categories',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: _Palette.lightText, height: 1.4),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() { _search.clear(); _query = ''; _selectedCategory = 'All'; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(color: _Palette.primary, borderRadius: BorderRadius.circular(12)),
                child: const Text('Clear Search', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard(_FaqItem item, int index, bool expanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _Palette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: expanded ? _Palette.primaryBorder : _Palette.border, width: expanded ? 1.3 : 1),
        boxShadow: expanded ? [BoxShadow(color: _Palette.primary.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))] : [],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expandedIndex = expanded ? null : index),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: _Palette.primaryLight, borderRadius: BorderRadius.circular(20)),
                          child: Text(item.category, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _Palette.primary)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.question,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _Palette.darkText, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: _Palette.background, borderRadius: BorderRadius.circular(8)),
                      child: Icon(LucideIcons.chevronDown, size: 15, color: _Palette.lightText),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(height: 1, color: _Palette.border),
                  const SizedBox(height: 12),
                  Text(item.answer, style: TextStyle(fontSize: 13, color: _Palette.darkText.withOpacity(0.85), height: 1.5)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text('Was this helpful?', style: TextStyle(fontSize: 11.5, color: _Palette.lightText, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      _feedbackBtn(item, true, LucideIcons.thumbsUp),
                      const SizedBox(width: 6),
                      _feedbackBtn(item, false, LucideIcons.thumbsDown),
                      const Spacer(),
                      if (item.helpful != null)
                        Text(
                          item.helpful! ? 'Thanks!' : 'We\'ll improve this',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.helpful! ? _Palette.success : _Palette.lightText),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedbackBtn(_FaqItem item, bool isYes, IconData icon) {
    final bool selected = item.helpful == isYes;
    return GestureDetector(
      onTap: () => setState(() => item.helpful = isYes),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: selected ? (isYes ? _Palette.successBg : const Color(0xFFFEF2F2)) : _Palette.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? (isYes ? _Palette.success : const Color(0xFFEF4444)) : _Palette.border),
        ),
        child: Icon(icon, size: 13, color: selected ? (isYes ? _Palette.success : const Color(0xFFEF4444)) : _Palette.lightText),
      ),
    );
  }
}