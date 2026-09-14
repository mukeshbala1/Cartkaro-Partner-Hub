import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/services/auth_service.dart';

class BusinessTypeScreen extends StatefulWidget {
  const BusinessTypeScreen({super.key});

  @override
  State<BusinessTypeScreen> createState() => _BusinessTypeScreenState();
}

class _BusinessTypeScreenState extends State<BusinessTypeScreen> {
  String? _selectedCategory;
  Map<String, String> _registeredBusinesses = {}; // type -> businessId
  Map<String, String> _registeredStoreNames = {}; // type -> storeName
  bool _isLoading = true;

  final List<_CategoryData> _categories = const [
    _CategoryData(
      id: 'grocery',
      title: 'Grocery Store',
      subtitle: 'Groceries, fresh produce, daily essentials & FMCG',
      imagePath: 'assets/categories/grocery.jpg',
      accentColor: Color(0xFF059669),
      badgeText: 'Popular',
    ),
    _CategoryData(
      id: 'restaurant',
      title: 'Restaurant & Cafe',
      subtitle: 'Dine-in, cloud kitchen, food delivery & digital menu',
      imagePath: 'assets/categories/restaurant.jpg',
      accentColor: Color(0xFFEA580C),
      badgeText: 'Trending',
    ),
    _CategoryData(
      id: 'medical',
      title: 'Medical & Pharmacy',
      subtitle: 'Prescriptions, medicines, healthcare & wellness items',
      imagePath: 'assets/categories/medical.jpg',
      accentColor: Color(0xFF0284C7),
      badgeText: 'Verified',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserBusinesses();
  }

  Future<void> _loadUserBusinesses() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('businesses')
            .where('ownerUid', isEqualTo: user.uid)
            .get()
            .timeout(const Duration(seconds: 4));

        final Map<String, String> registered = {};
        final Map<String, String> names = {};

        for (var doc in snap.docs) {
          final data = doc.data();
          final type = (data['businessType'] as String?)?.toLowerCase();
          final name = data['storeName'] ?? data['restaurantName'] ?? data['medicalName'] ?? data['name'] ?? 'Store';
          if (type != null && type.isNotEmpty) {
            registered[type] = doc.id;
            names[type] = name.toString();
          }
        }

        if (mounted) {
          setState(() {
            _registeredBusinesses = registered;
            _registeredStoreNames = names;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading businesses for business type screen: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBack() async {
    final hasPin = await AuthService.isPinSet();
    if (!mounted) return;
    if (hasPin) {
      context.go('/pin-login');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  Future<void> _onCategorySelected(String categoryId) async {
    // 1. If already registered under this mobile number, open its dashboard directly
    if (_registeredBusinesses.containsKey(categoryId)) {
      final bId = _registeredBusinesses[categoryId]!;
      await AuthService.saveActiveBusinessId(bId);
      await AuthService.saveBusinessType(categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${_registeredStoreNames[categoryId] ?? 'your store'} dashboard...'),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
          ),
        );
        context.go('/dashboard', extra: bId);
      }
      return;
    }

    // 2. If already 3 businesses registered (capacity full)
    if (_registeredBusinesses.length >= 3) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(LucideIcons.shieldAlert, color: Color(0xFFEA580C)),
                SizedBox(width: 10),
                Text("Business Limit Reached"),
              ],
            ),
            content: const Text(
              "One mobile number can register up to 3 businesses (1 Grocery, 1 Restaurant, and 1 Medical).\n\nYour account has already registered all 3 business categories.",
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/business-selector');
                },
                child: const Text("View My Businesses"),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 3. Category is available to register
    setState(() => _selectedCategory = categoryId);
    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted) {
        context.push('/register/$categoryId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final regCount = _registeredBusinesses.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _handleBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    color: Color(0xFF0F172A),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.kPrimary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.sparkles, size: 13, color: AppColors.kPrimary),
                    const SizedBox(width: 5),
                    Text(
                      '$regCount/3 Registered',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 32,
            vertical: 8,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'What type of business\ndo you own?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.6,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Choose your category to personalize your store tools, catalog, and checkout flow.',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 1 Number = 3 Business Info Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(LucideIcons.layers, size: 20, color: AppColors.kPrimary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                regCount >= 3
                                    ? 'All 3 Categories Registered (Maximum Capacity)'
                                    : '1 Mobile Number = Up to 3 Businesses ($regCount of 3 Active)',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                regCount >= 3
                                    ? 'Grocery, Restaurant & Medical stores are all registered. Tap any store to open its dashboard.'
                                    : 'You can register 1 Grocery, 1 Restaurant, and 1 Medical Store under this account.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  if (!isMobile)
                    Row(
                      children: _categories.map((cat) {
                        final isRegistered = _registeredBusinesses.containsKey(cat.id);
                        final registeredName = _registeredStoreNames[cat.id];
                        final isSelected = _selectedCategory == cat.id;
                        final isCapacityFull = regCount >= 3 && !isRegistered;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _CategoryCard(
                              category: cat,
                              isSelected: isSelected,
                              isRegistered: isRegistered,
                              registeredStoreName: registeredName,
                              isCapacityFull: isCapacityFull,
                              isVerticalLayout: true,
                              onTap: () => _onCategorySelected(cat.id),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    ..._categories.map((cat) {
                      final isRegistered = _registeredBusinesses.containsKey(cat.id);
                      final registeredName = _registeredStoreNames[cat.id];
                      final isSelected = _selectedCategory == cat.id;
                      final isCapacityFull = regCount >= 3 && !isRegistered;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CategoryCard(
                          category: cat,
                          isSelected: isSelected,
                          isRegistered: isRegistered,
                          registeredStoreName: registeredName,
                          isCapacityFull: isCapacityFull,
                          onTap: () => _onCategorySelected(cat.id),
                        ),
                      );
                    }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryData {
  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final Color accentColor;
  final String badgeText;

  const _CategoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accentColor,
    required this.badgeText,
  });
}

class _CategoryCard extends StatefulWidget {
  final _CategoryData category;
  final bool isSelected;
  final bool isRegistered;
  final String? registeredStoreName;
  final bool isCapacityFull;
  final VoidCallback onTap;
  final bool isVerticalLayout;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
    this.isRegistered = false,
    this.registeredStoreName,
    this.isCapacityFull = false,
    required this.onTap,
    this.isVerticalLayout = false,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final isRegistered = widget.isRegistered;
    final isFull = widget.isCapacityFull;
    final active = (widget.isSelected || _isHovered) && !isFull;

    final borderColor = isRegistered
        ? const Color(0xFF059669)
        : active
            ? cat.accentColor
            : const Color(0xFFE2E8F0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isFull ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: (active || isRegistered) ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isRegistered
                  ? const Color(0xFF059669).withOpacity(0.12)
                  : active
                      ? cat.accentColor.withValues(alpha: 0.14)
                      : const Color(0x06000000),
              blurRadius: (active || isRegistered) ? 16 : 8,
              offset: Offset(0, (active || isRegistered) ? 5 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            splashColor: cat.accentColor.withValues(alpha: 0.08),
            highlightColor: cat.accentColor.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: widget.isVerticalLayout
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo Container
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isRegistered
                                  ? const Color(0xFF059669).withOpacity(0.3)
                                  : cat.accentColor.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRegistered
                                    ? const Color(0xFF059669).withOpacity(0.15)
                                    : cat.accentColor.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                cat.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(LucideIcons.store, color: cat.accentColor, size: 30),
                                  );
                                },
                              ),
                              if (isRegistered)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF059669),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.check, color: Colors.white, size: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          cat.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: isFull ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Badge
                        if (isRegistered)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF059669).withOpacity(0.35)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.checkCircle2, size: 12, color: Color(0xFF059669)),
                                SizedBox(width: 5),
                                Text(
                                  'Registered • Tap to Open',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isFull)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF94A3B8).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Max 3 Reached',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.2,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: cat.accentColor.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              cat.badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: cat.accentColor,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          isRegistered && widget.registeredStoreName != null
                              ? 'Active Store: ${widget.registeredStoreName}\nTap to open your live dashboard.'
                              : cat.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.8,
                            color: isRegistered ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            height: 1.4,
                            fontWeight: isRegistered ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),

                        // Action Icon
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isRegistered
                                ? const Color(0xFF059669)
                                : active
                                    ? cat.accentColor
                                    : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRegistered
                                ? LucideIcons.layoutDashboard
                                : LucideIcons.chevronRight,
                            size: 18,
                            color: (active || isRegistered) ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // Logo Container
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isRegistered
                                  ? const Color(0xFF059669).withOpacity(0.3)
                                  : cat.accentColor.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isRegistered
                                    ? const Color(0xFF059669).withOpacity(0.12)
                                    : cat.accentColor.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                cat.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(LucideIcons.store, color: cat.accentColor, size: 30),
                                  );
                                },
                              ),
                              if (isRegistered)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF059669),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.check, color: Colors.white, size: 10),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title & Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cat.title,
                                      style: TextStyle(
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.w800,
                                        color: isFull ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isRegistered)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF059669).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF059669).withOpacity(0.35)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(LucideIcons.checkCircle2, size: 11, color: Color(0xFF059669)),
                                          SizedBox(width: 4),
                                          Text(
                                            'Registered',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (isFull)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF94A3B8).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Full',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: cat.accentColor.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        cat.badgeText,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: cat.accentColor,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isRegistered && widget.registeredStoreName != null
                                    ? 'Active Store: ${widget.registeredStoreName} • Tap to open'
                                    : cat.subtitle,
                                style: TextStyle(
                                  fontSize: 12.8,
                                  color: isRegistered ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  height: 1.4,
                                  fontWeight: isRegistered ? FontWeight.w600 : FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Forward Arrow Action
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isRegistered
                                ? const Color(0xFF059669)
                                : active
                                    ? cat.accentColor
                                    : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRegistered
                                ? LucideIcons.layoutDashboard
                                : LucideIcons.chevronRight,
                            size: 18,
                            color: (active || isRegistered) ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}