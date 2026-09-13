import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';

class WebAuthLayout extends StatelessWidget {
  final Widget mobileForm;
  final String heroTitle;
  final String heroSubtitle;

  const WebAuthLayout({
    Key? key,
    required this.mobileForm,
    this.heroTitle = 'Welcome to CartKaro Partner Hub',
    this.heroSubtitle = 'Manage your store, track orders, and grow your business seamlessly across multiple platforms.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Responsive(
      mobile: mobileForm,
      tablet: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: mobileForm,
            ),
          ),
        ),
      ),
      desktop: _buildSplitScreen(context),
    );
  }

  Widget _buildSplitScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side: Branding / Hero
          Expanded(
            flex: 11,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.kPrimary,
                    Color(0xFF223554), // Brand Darker
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.store,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        heroTitle,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        heroSubtitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      // Floating decorative elements could go here
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          _buildFeatureTag(LucideIcons.zap, 'Lightning Fast'),
                          _buildFeatureTag(LucideIcons.barChart3, 'Real-time Analytics'),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Right Side: Auth Form Centered
          Expanded(
            flex: 9,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: mobileForm,
                  ), // The actual form content
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
