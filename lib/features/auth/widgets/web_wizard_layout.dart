import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';

class WebWizardLayout extends StatelessWidget {
  final Widget topBar;
  final Widget? progressBar;
  final Widget formContent;
  final Color leftPanelColor;

  const WebWizardLayout({
    Key? key,
    required this.topBar,
    this.progressBar,
    required this.formContent,
    this.leftPanelColor = const Color(0xFF0F172A), // Default dark navy
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final isDesktop = constraints.maxWidth >= 1024;

        if (isDesktop) {
          // Split-Screen Layout for Desktop
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Sidebar
              Expanded(
                flex: 4,
                child: Container(
                  color: leftPanelColor,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        topBar,
                        if (progressBar != null) progressBar!,
                        const Spacer(),
                        // A beautiful decorative element for the wizard
                        Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.rocket, color: AppColors.kPrimary, size: 32),
                                const SizedBox(height: 16),
                                const Text(
                                  'Partner with us',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Complete your registration to unlock a powerful dashboard and reach thousands of new customers.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Right Form Area
              Expanded(
                flex: 6,
                child: Container(
                  color: const Color(0xFFF8FAFC), // OffWhite
                  child: Center(
                    child: SizedBox(
                      width: 720,
                      child: SafeArea(
                        bottom: false,
                        child: formContent,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // Mobile & Tablet Layout
        final contentWidth = isTablet ? constraints.maxWidth * 0.85 : constraints.maxWidth;
        return Column(
          children: [
            topBar,
            if (progressBar != null) progressBar!,
            Expanded(
              child: Center(
                child: SizedBox(
                  width: contentWidth,
                  child: formContent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
