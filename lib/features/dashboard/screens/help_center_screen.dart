// ══════════════════════════════════════════════════════════════════
// help_center_screen.dart
//
// Help Center — searchable categorized topics + expandable answers.
// Uses AppColors.kPrimary (navy blue) throughout.
// ══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

class _HelpTopic {
  final String question;
  final String answer;
  const _HelpTopic(this.question, this.answer);
}

class _HelpCategory {
  final String title;
  final IconData icon;
  final List<_HelpTopic> topics;
  const _HelpCategory(this.title, this.icon, this.topics);
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int? _expandedIndex;

  final List<_HelpCategory> _categories = const [
    _HelpCategory('Orders & Delivery', LucideIcons.packageSearch, [
      _HelpTopic('How do I accept a new order?', 'When a new order arrives, you\'ll get a sound alert and notification. Open the Orders tab and tap "Accept" within the time window shown. Enable Auto Accept Orders in Settings to skip this step.'),
      _HelpTopic('How do I cancel an order?', 'Open the order from your Orders list, tap "Cancel Order", and select a reason. Frequent cancellations may affect your store rating.'),
      _HelpTopic('What if a delivery partner doesn\'t arrive?', 'If a CartKaro delivery partner hasn\'t arrived within the expected pickup window, tap "Report Delay" on the order screen and our support team will reassign a partner.'),
    ]),
    _HelpCategory('Payments & Earnings', LucideIcons.wallet, [
      _HelpTopic('When do I get paid?', 'Settlements are processed every 3 business days to your registered bank account. You can track pending and completed payouts under Settings → Payments & Earnings.'),
      _HelpTopic('How do I change my bank account?', 'Go to Settings → Payments & Earnings → Change Bank Account. New bank details require 24–48 hours verification before payouts switch over.'),
      _HelpTopic('Why is my payout delayed?', 'Payouts can be delayed due to bank verification, order disputes, or holidays. Check Settlement History for status, or contact support if it\'s been more than 5 business days.'),
    ]),
    _HelpCategory('Business Profile', LucideIcons.store, [
      _HelpTopic('How do I update my business hours?', 'Go to Settings → Business Hours. Toggle days on/off and tap any time chip to adjust opening and closing times.'),
      _HelpTopic('How do I add a new business?', 'Go to Settings → Manage Businesses → Add New Business, choose a business type, and complete the registration form. Verification takes 24–48 hours.'),
      _HelpTopic('Can I run multiple businesses on one account?', 'Yes. One owner account can manage multiple approved businesses. Switch between them from the Dashboard header or Settings → Manage Businesses.'),
    ]),
    _HelpCategory('Documents & Verification', LucideIcons.fileBadge, [
      _HelpTopic('Which documents are required?', 'Grocery & Restaurant: FSSAI license, GST certificate, Trade license, PAN, Aadhaar. Medical: Drug license, Pharmaceutical license, GST, PAN, Aadhaar.'),
      _HelpTopic('How long does verification take?', 'Most document and profile changes are verified within 24–48 hours. You\'ll get a notification once approved.'),
      _HelpTopic('My document was rejected, what now?', 'Go to Settings → Legal & Verification, tap the rejected document, and re-upload a clearer copy or corrected details.'),
    ]),
  ];

  List<_HelpCategory> get _filtered {
    if (_query.trim().isEmpty) return _categories;
    final q = _query.toLowerCase();
    return _categories
        .map((c) => _HelpCategory(
              c.title,
              c.icon,
              c.topics.where((t) => t.question.toLowerCase().contains(q) || t.answer.toLowerCase().contains(q)).toList(),
            ))
        .where((c) => c.topics.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Hero header ───────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(18, 4, 18, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.kPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: AppColors.kPrimary.withOpacity(0.25), blurRadius: 18, offset: const Offset(0, 8)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(LucideIcons.lifeBuoy, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'How can we help you today?',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _search,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 13.5, color: AppColors.kDarkText),
                      decoration: InputDecoration(
                        hintText: 'Search help articles...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.kLightText),
                        prefixIcon: Icon(LucideIcons.search, size: 17, color: AppColors.kPrimary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Results ──────────────────────────────────────────
            Expanded(
              child: results.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: results.length,
                      itemBuilder: (context, catIndex) {
                        final cat = results[catIndex];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(9)),
                                    child: Icon(cat.icon, size: 14, color: AppColors.kPrimary),
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    cat.title,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.2),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.kWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Column(
                                  children: cat.topics.asMap().entries.map((e) {
                                    final globalKey = '$catIndex-${e.key}';
                                    final isOpen = _expandedIndex == globalKey.hashCode;
                                    return Column(
                                      children: [
                                        InkWell(
                                          onTap: () => setState(() => _expandedIndex = isOpen ? null : globalKey.hashCode),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    e.value.question,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kDarkText, height: 1.3),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                AnimatedRotation(
                                                  turns: isOpen ? 0.5 : 0,
                                                  duration: const Duration(milliseconds: 200),
                                                  child: Icon(LucideIcons.chevronDown, size: 16, color: AppColors.kLightText),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        AnimatedCrossFade(
                                          firstChild: const SizedBox(width: double.infinity),
                                          secondChild: Padding(
                                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                            child: Text(
                                              e.value.answer,
                                              style: TextStyle(fontSize: 12.5, color: AppColors.kLightText, height: 1.5, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                                          duration: const Duration(milliseconds: 200),
                                        ),
                                        if (e.key < cat.topics.length - 1)
                                          Divider(height: 1, indent: 14, endIndent: 14, color: AppColors.kBorder.withOpacity(0.5)),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // ── Still need help footer ───────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(
                color: AppColors.kWhite,
                border: Border(top: BorderSide(color: AppColors.kBorder.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Still need help?',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(color: AppColors.kPrimary, borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'Contact Support',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
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

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.searchX, size: 40, color: AppColors.kLightText.withOpacity(0.4)),
            const SizedBox(height: 14),
            Text(
              'No results for "$_query"',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText),
            ),
            const SizedBox(height: 6),
            Text(
              'Try a different search term or contact support',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.kLightText),
            ),
          ],
        ),
      ),
    );
  }
}