import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/services/auth_service.dart';

import 'create_offer_screen.dart';
import 'business_settings_screen.dart';
import 'customer_reviews_screen.dart'; 
import '../../auth/screens/business_type_screen.dart' hide BusinessTypeScreen;
import '../../../models/business_model.dart';

class DashboardScreen extends StatefulWidget {
  final String? businessId;
  final Function(String) onBusinessChanged;
  final int activeCount; 
  final VoidCallback onAddProductTap;
  final VoidCallback onViewProductsTap;
  final VoidCallback onOrdersTap;  // NAYA Callback
  final VoidCallback onRevenueTap; // NAYA Callback

  const DashboardScreen({
    Key? key,
    this.businessId,
    required this.onBusinessChanged,
    required this.activeCount,
    required this.onAddProductTap,
    required this.onViewProductsTap,
    required this.onOrdersTap,
    required this.onRevenueTap,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late BusinessModel _business;
  bool _isLoading = true;
  bool _isTogglingLive = false;

  @override
  void initState() {
    super.initState();
    _fetchBusinessData();
  }

  Future<void> _fetchBusinessData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && widget.businessId != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).get();
        if (doc.exists) {
          final data = doc.data()!;
          if (!mounted) return;
          
          setState(() {
            _business = BusinessModel.fromFirestore(data, doc.id);
            _isLoading = false;
          });
          widget.onBusinessChanged(_business.businessType);
          return;
        }
      } catch (e) {
        debugPrint('Error fetching business data: $e');
      }
    }
    
    // Fallback to mock if fetch fails or user is null
    if (!mounted) return;
    setState(() {
      _business = BusinessModel.empty();
      _isLoading = false;
    });
    widget.onBusinessChanged(_business.businessType);
  }

  String get itemName => _business.itemName;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    else if (hour < 17) return 'Good afternoon';
    else return 'Good evening';
  }

  void _switchBusiness(BusinessModel newBusiness) {
    if (newBusiness.id == _business.id) return;
    setState(() {
      _business = newBusiness;
    });
    widget.onBusinessChanged(newBusiness.businessType);
  }

  IconData get _businessIcon {
    switch (_business.businessType) {
      case 'grocery': return LucideIcons.shoppingCart;
      case 'restaurant': return LucideIcons.utensilsCrossed;
      case 'medical': return LucideIcons.pill;
      default: return LucideIcons.store;
    }
  }

  List<Color> get _businessGradient {
    switch (_business.businessType) {
      case 'grocery': return [const Color(0xFF16A34A), const Color(0xFF22C55E)]; // Green
      case 'restaurant': return [const Color(0xFFEA580C), const Color(0xFFF97316)]; // Orange
      case 'medical': return [const Color(0xFF0284C7), const Color(0xFF0EA5E9)]; // Light Blue
      default: return [AppColors.kPrimary, AppColors.kPrimary.withOpacity(0.78)];
    }
  }

  String get _businessBadgeText {
    switch (_business.businessType) {
      case 'grocery': return 'Grocery Partner';
      case 'restaurant': return 'Restaurant Partner';
      case 'medical': return 'Medical Partner';
      default: return 'Partner';
    }
  }

  Future<void> _onLiveToggleChanged(bool newValue) async {
    if (_business.isLive && newValue == false) {
      final confirmed = await _showGoUnliveDialog();
      if (confirmed != true) return; 
    }

    final previousValue = _business.isLive;
    setState(() {
      _business = _business.copyWith(isLive: newValue);
      _isTogglingLive = true;
    });

    bool success = false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && widget.businessId != null) {
        await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).update({
          'isLive': newValue,
        });
        success = true;
      }
    } catch (e) {
      debugPrint('Error updating live status: $e');
    }

    if (!mounted) return;

    if (success) {
      setState(() => _isTogglingLive = false);
    } else {
      setState(() {
        _business = _business.copyWith(isLive: previousValue);
        _isTogglingLive = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update status. Please try again.')));
    }
  }

  Future<bool?> _showGoUnliveDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Go Unlive?', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.kDarkText)),
        content: const Text('Your business will stop receiving new orders.', style: TextStyle(color: AppColors.kLightText, fontSize: 13.5, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.kLightText, fontWeight: FontWeight.w600))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Go Unlive', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Future<void> _openBusinessSwitcher() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Show a small loading indicator while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerUid', isEqualTo: user.uid)
          .get();
          
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      final businesses = snapshot.docs.map((doc) {
        final data = doc.data();
        return BusinessModel.fromFirestore(data, doc.id);
      }).toList();
      
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _SwitchBusinessSheet(
          businesses: businesses,
          currentBusinessId: _business.id,
          onSelect: (b) {
            Navigator.pop(context);
            context.go('/dashboard', extra: b.id);
          },
          onAddNew: () {
            Navigator.pop(context); 
            context.go('/business-type');
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      debugPrint('Error fetching businesses for switcher: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.kBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_business.status == BusinessStatus.pending) {
      return _buildPendingVerificationView();
    }
    
    if (_business.status == BusinessStatus.rejected) {
      return _buildRejectedView();
    }
    
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildRevenueHeroCard(context),
              _buildSmallStatsRow(context),
              const SizedBox(height: 24),
              Responsive.isDesktop(context)
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 20),
                          Expanded(flex: 1, child: _buildQuickActionsCard(context)),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _buildQuickActionsCard(context),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingVerificationView() {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.kDarkText),
            onPressed: () async {
              final hasPin = await AuthService.isPinSet();
              if (hasPin) {
                if (mounted) context.go('/pin-login');
              } else {
                await FirebaseAuth.instance.signOut();
                if (mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.kPrimary, width: 2.5),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: AppColors.kPrimary, size: 52),
              ),
              const SizedBox(height: 28),
              const Text(
                'Verification\nUnder Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.kDarkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your documents and details are currently being verified by our team. This usually takes 24-48 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.kLightText, fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchBusinessData();
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: const Text('Refresh Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedView() {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: AppColors.kBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.kDarkText),
            onPressed: () async {
              final hasPin = await AuthService.isPinSet();
              if (hasPin) {
                if (mounted) context.go('/pin-login');
              } else {
                await FirebaseAuth.instance.signOut();
                if (mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.red, width: 2.5),
                ),
                child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 52),
              ),
              const SizedBox(height: 28),
              const Text(
                'Application Rejected',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.kDarkText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Unfortunately, your application was rejected. Please contact support for more details.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.kLightText, fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Contact Support action
                  },
                  icon: const Icon(LucideIcons.headphones, size: 18),
                  label: const Text('Contact Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kDarkText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_businessIcon, size: 14, color: AppColors.kPrimary),
                    const SizedBox(width: 6),
                    Text('$_greeting 👋', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kPrimary, letterSpacing: 0.2)),
                  ],
                ),
                const SizedBox(height: 4), 
                GestureDetector(
                  onTap: _openBusinessSwitcher, 
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(_business.displayName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 4),
                      const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.kDarkText), 
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10), 
          _buildOnlineToggle(),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.kPrimary.withOpacity(0.15),
              child: const Icon(LucideIcons.user, size: 20, color: AppColors.kPrimary),
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile screen coming soon!')),
                );
              } else if (value == 'logout') {
                final hasPin = await AuthService.isPinSet();
                if (hasPin) {
                  if (context.mounted) {
                    context.go('/pin-login');
                  }
                } else {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(LucideIcons.user, size: 18, color: AppColors.kDarkText),
                    SizedBox(width: 12),
                    Text('Profile', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.kDarkText)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(LucideIcons.logOut, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    final bool isLive = _business.isLive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: AppColors.kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(30), border: Border.all(color: AppColors.kPrimary.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isTogglingLive)
            const SizedBox(width: 7, height: 7, child: CircularProgressIndicator(strokeWidth: 1.4, valueColor: AlwaysStoppedAnimation(AppColors.kPrimary)))
          else
            Container(width: 7, height: 7, decoration: BoxDecoration(color: isLive ? AppColors.kPrimary : AppColors.kLightText, shape: BoxShape.circle, boxShadow: isLive ? [BoxShadow(color: AppColors.kPrimary.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)] : null)),
          const SizedBox(width: 7),
          Text(isLive ? 'Live' : 'Unlive', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isLive ? AppColors.kPrimary : AppColors.kLightText, letterSpacing: 0.3)),
          const SizedBox(width: 6),
          SizedBox(height: 24, child: Transform.scale(scale: 0.75, child: Switch(value: isLive, onChanged: _isTogglingLive ? null : _onLiveToggleChanged, activeColor: Colors.white, activeTrackColor: AppColors.kPrimary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap))),
        ],
      ),
    );
  }

  Widget _buildRevenueHeroCard(BuildContext context) {
    final b = _business;
    final String revenueStr = '₹${b.todayRevenue.toStringAsFixed(0)}';
    final bool growthPositive = b.revenueGrowthPct >= 0;
    final String growthStr = '${growthPositive ? '+' : ''}${b.revenueGrowthPct.toStringAsFixed(1)}%';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: _businessGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: _businessGradient[0].withOpacity(0.30), blurRadius: 28, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAYA: GestureDetector to Earnings Page
          GestureDetector(
            onTap: widget.onRevenueTap,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(20)), child: Text(_businessBadgeText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.4))),
                    const Spacer(),
                    Icon(LucideIcons.trendingUp, color: Colors.white.withOpacity(0.9), size: 18),
                  ],
                ),
                const SizedBox(height: 18),
                Text(revenueStr, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5, height: 1)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Total Revenue', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(growthPositive ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(growthStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.15), height: 1),
          const SizedBox(height: 16),
          
          // NAYA: GestureDetector to Orders Page
          GestureDetector(
            onTap: widget.onOrdersTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _heroStat('${b.totalOrders}', 'Orders'),
                _heroDivider(),
                _heroStat('${b.completedOrders}', 'Completed'),
                _heroDivider(),
                _heroStat('${b.pendingOrders}', 'Pending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String val, String label) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)), const SizedBox(height: 2), Text(label, style: TextStyle(fontSize: 11.5, color: Colors.white.withOpacity(0.65), fontWeight: FontWeight.w500))]));
  Widget _heroDivider() => Container(width: 1, height: 32, color: Colors.white.withOpacity(0.2));

  Widget _buildSmallStatsRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onViewProductsTap,
              child: _SmallStatCard(
                icon: LucideIcons.box,
                label: 'Active $itemName',
                value: widget.activeCount.toString(),
                iconColor: const Color(0xFF6366F1),
                bgColor: const Color(0xFFEEF2FF),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerReviewsScreen(businessName: _business.displayName)));
              },
              child: _SmallStatCard(
                icon: LucideIcons.star,
                label: 'Avg Rating',
                value: _business.avgRating > 0 ? '${_business.avgRating}★' : '—',
                iconColor: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3)),
        const SizedBox(height: 12),
        _QuickActionCard(icon: LucideIcons.plusCircle, title: 'Add $itemName', subtitle: 'Grow your catalogue', iconColor: const Color(0xFF6366F1), bgColor: const Color(0xFFEEF2FF), onTap: widget.onAddProductTap),
        const SizedBox(height: 10),
        _QuickActionCard(icon: LucideIcons.tags, title: 'Create Offer', subtitle: 'Run a discount deal', iconColor: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFFBEB), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => CreateOfferScreen(businessType: _business.businessType))); }),
        const SizedBox(height: 10),
        _QuickActionCard(icon: LucideIcons.settings2, title: '${_business.businessTypeLabel} Settings', subtitle: 'Hours, address, info', iconColor: AppColors.kPrimary, bgColor: AppColors.kPrimary.withOpacity(0.08), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => BusinessSettingsScreen(business: _business))); }),
      ],
    );
  }
}

// _SwitchBusinessSheet, _SmallStatCard, _QuickActionCard classes remain same as before
class _SwitchBusinessSheet extends StatelessWidget {
  final List<BusinessModel> businesses; 
  final String currentBusinessId;
  final ValueChanged<BusinessModel> onSelect;
  final VoidCallback onAddNew;

  const _SwitchBusinessSheet({
    required this.businesses,
    required this.currentBusinessId,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Switch Business',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.3),
          ),
          const SizedBox(height: 14),
          ...businesses.map((b) => _businessRow(b)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onAddNew,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.kPrimary.withOpacity(0.35), width: 1.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.plusCircle, size: 16, color: AppColors.kPrimary),
                  const SizedBox(width: 8),
                  const Text('Add New Business', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.kPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _businessRow(BusinessModel b) {
    final bool isSelected = b.id == currentBusinessId;
    return InkWell(
      onTap: () => onSelect(b),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kPrimary.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.kPrimary.withOpacity(0.2) : AppColors.kBorder.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.kBackground, borderRadius: BorderRadius.circular(11)),
              child: Icon(LucideIcons.store, size: 17, color: isSelected ? AppColors.kPrimary : AppColors.kLightText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.kDarkText)),
                  const SizedBox(height: 2),
                  Text(b.businessTypeLabel, style: TextStyle(fontSize: 11.5, color: AppColors.kLightText, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (isSelected) const Icon(LucideIcons.checkCircle2, size: 18, color: AppColors.kPrimary),
          ],
        ),
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  const _SmallStatCard({required this.icon, required this.label, required this.value, required this.iconColor, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.kBorder.withOpacity(0.6)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 3))]),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.kDarkText, letterSpacing: -0.4)),
                Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.kLightText, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.title, required this.subtitle, required this.iconColor, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.kWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.kBorder.withOpacity(0.6)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: iconColor, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.kDarkText, letterSpacing: -0.2)), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.kLightText, fontWeight: FontWeight.w500))])),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.kLightText),
          ],
        ),
      ),
    );
  }
}