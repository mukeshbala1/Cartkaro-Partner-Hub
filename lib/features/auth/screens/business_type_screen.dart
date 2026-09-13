import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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

  void _onCategorySelected(String categoryId) {
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, size: 13, color: AppColors.kPrimary),
                    SizedBox(width: 5),
                    Text(
                      'Step 1 of 2',
                      style: TextStyle(
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
                  const SizedBox(height: 28),
                  if (!isMobile)
                    Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat.id;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _CategoryCard(
                              category: cat,
                              isSelected: isSelected,
                              isVerticalLayout: true,
                              onTap: () => _onCategorySelected(cat.id),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategory == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _CategoryCard(
                          category: cat,
                          isSelected: isSelected,
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
  final VoidCallback onTap;
  final bool isVerticalLayout;

  const _CategoryCard({
    required this.category,
    required this.isSelected,
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
    final active = widget.isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? cat.accentColor : const Color(0xFFE2E8F0),
            width: active ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? cat.accentColor.withValues(alpha: 0.14)
                  : const Color(0x06000000),
              blurRadius: active ? 16 : 8,
              offset: Offset(0, active ? 5 : 2),
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
                        // 3D AI Logo Container
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: cat.accentColor.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cat.accentColor.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            cat.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(LucideIcons.store, color: cat.accentColor, size: 30),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title & Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                cat.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
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
                        Text(
                          cat.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12.8,
                            color: Color(0xFF64748B),
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        // Forward Arrow Action
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: active ? cat.accentColor : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: active ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        // 3D AI Logo Container
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: cat.accentColor.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cat.accentColor.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            cat.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(LucideIcons.store, color: cat.accentColor, size: 30),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title & Minimal Subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cat.title,
                                      style: const TextStyle(
                                        fontSize: 17.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
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
                                cat.subtitle,
                                style: const TextStyle(
                                  fontSize: 12.8,
                                  color: Color(0xFF64748B),
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
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
                            color: active ? cat.accentColor : const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: active ? Colors.white : const Color(0xFF64748B),
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