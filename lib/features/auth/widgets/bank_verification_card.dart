import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/razorpay_verification_service.dart';

/// Clean banner displayed directly below the IFSC Code input box showing ONLY the detected Bank Branch.
class IfscBranchBanner extends StatelessWidget {
  final IfscDetailsResult? ifscDetails;
  final bool isLoading;

  const IfscBranchBanner({
    super.key,
    required this.ifscDetails,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.kPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Fetching branch details...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (ifscDetails != null && ifscDetails!.isValid) {
      final bank = ifscDetails!.bank ?? '';
      final branch = ifscDetails!.branch ?? '';
      final branchText = [bank, branch].where((s) => s.trim().isNotEmpty).join(' — ');

      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.landmark, color: Color(0xFF16A34A), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                branchText.isNotEmpty ? branchText : 'Bank Branch Verified',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (ifscDetails != null && !ifscDetails!.isValid && ifscDetails!.errorMessage != null) {
      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ifscDetails!.errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Bank Verification Action Card: Shows "Verified" simply when valid, without clutter.
class BankVerificationCard extends StatelessWidget {
  final IfscDetailsResult? ifscDetails;
  final bool isIfscLoading;
  final BankVerificationResult? verificationResult;
  final bool isVerifyingBank;
  final int attemptCount;
  final VoidCallback onVerifyTap;

  const BankVerificationCard({
    super.key,
    this.ifscDetails,
    this.isIfscLoading = false,
    required this.verificationResult,
    required this.isVerifyingBank,
    this.attemptCount = 0,
    required this.onVerifyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // When Verified: Simple, clean "Verified" badge
        if (verificationResult != null && verificationResult!.isVerified) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 8),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          // Error alert if verification failed
          if (verificationResult != null && !verificationResult!.isVerified) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      verificationResult!.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // "Verify" Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isVerifyingBank ? null : onVerifyTap,
              icon: isVerifyingBank
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(LucideIcons.shieldCheck, size: 19),
              label: Text(
                isVerifyingBank ? 'Verifying Details...' : 'Verify Bank Details',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              attemptCount > 0
                  ? 'Attempt $attemptCount of ${RazorpayVerificationService.maxAttemptsPerAccount} • Max ${RazorpayVerificationService.maxAttemptsPerAccount} attempts allowed'
                  : 'Max ${RazorpayVerificationService.maxAttemptsPerAccount} verification attempts allowed per account number',
              style: TextStyle(
                fontSize: 11,
                color: attemptCount >= RazorpayVerificationService.maxAttemptsPerAccount
                    ? const Color(0xFFDC2626)
                    : Colors.grey.shade600,
                fontWeight: attemptCount >= RazorpayVerificationService.maxAttemptsPerAccount
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
