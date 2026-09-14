import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/web_auth_layout.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────
  String _pin = '';
  String _confirmedPin = '';
  bool _isConfirmStep = false;
  String _errorMsg = '';
  bool _loading = false;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────

  void _onDigit(String digit) {
    HapticFeedback.lightImpact();
    final current = _isConfirmStep ? _confirmedPin : _pin;
    if (current.length >= 4 || _loading) return;

    setState(() {
      _errorMsg = '';
      if (_isConfirmStep) {
        _confirmedPin += digit;
      } else {
        _pin += digit;
      }
    });

    final updated = _isConfirmStep ? _confirmedPin : _pin;
    if (updated.length == 4) {
      Future.delayed(const Duration(milliseconds: 180), _onPinComplete);
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      _errorMsg = '';
      if (_isConfirmStep) {
        if (_confirmedPin.isNotEmpty) {
          _confirmedPin = _confirmedPin.substring(0, _confirmedPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  void _onClearAll() {
    HapticFeedback.mediumImpact();
    setState(() {
      _errorMsg = '';
      if (_isConfirmStep) {
        _confirmedPin = '';
      } else {
        _pin = '';
      }
    });
  }

  void _backToStepOne() {
    HapticFeedback.lightImpact();
    setState(() {
      _isConfirmStep = false;
      _confirmedPin = '';
      _errorMsg = '';
    });
  }

  Future<void> _onPinComplete() async {
    if (!_isConfirmStep) {
      // Transition smoothly to confirm step
      setState(() {
        _isConfirmStep = true;
        _confirmedPin = '';
        _errorMsg = '';
      });
    } else {
      // Verify match
      if (_pin != _confirmedPin) {
        HapticFeedback.heavyImpact();
        _shakeCtrl.forward(from: 0);
        setState(() {
          _errorMsg = 'PINs do not match. Please try again.';
          _confirmedPin = '';
        });
        return;
      }

      // Match confirmed → Save & offer biometrics
      HapticFeedback.mediumImpact();
      setState(() => _loading = true);

      try {
        await AuthService.savePin(_pin);
        if (!mounted) return;

        final bioInfo = await AuthService.getDeviceBiometricInfo();
        if (!mounted) return;

        if (bioInfo.isSupported) {
          setState(() => _loading = false);
          _showBiometricOptInBottomSheet(bioInfo);
        } else {
          _navigateAfterSetup();
        }
      } catch (e) {
        debugPrint('Error saving PIN: $e');
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMsg = 'Could not save PIN. Please try again.';
          });
        }
      }
    }
  }

  void _showBiometricOptInBottomSheet(DeviceBiometricInfo bioInfo) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(bioInfo.icon, size: 36, color: AppColors.kPrimary),
            ),
            const SizedBox(height: 18),
            Text(
              'Enable ${bioInfo.label}?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.kDarkText,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to your partner hub instantly with ${bioInfo.label}. Your 4-digit PIN is always saved as a secure backup.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.kLightText,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: Icon(bioInfo.icon, color: Colors.white, size: 20),
                label: Text(
                  'Enable ${bioInfo.label}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await AuthService.setBiometricEnabled(true);
                  if (bioInfo.isEnrolled) {
                    await AuthService.authenticateWithBiometric();
                  }
                  if (mounted) _navigateAfterSetup();
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await AuthService.setBiometricEnabled(false);
                if (mounted) _navigateAfterSetup();
              },
              child: Text(
                'Skip (Use PIN Only)',
                style: TextStyle(
                  color: AppColors.kLightText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateAfterSetup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      final savedBusinessId = await AuthService.getActiveBusinessId();

      try {
        final snap = await FirebaseFirestore.instance
            .collection('businesses')
            .where('ownerUid', isEqualTo: user.uid)
            .get()
            .timeout(const Duration(seconds: 4));

        if (!mounted) return;
        if (snap.docs.isEmpty) {
          if (savedBusinessId != null && savedBusinessId.isNotEmpty) {
            context.go('/dashboard', extra: savedBusinessId);
          } else {
            context.go('/business-type');
          }
        } else if (snap.docs.length == 1) {
          final bId = snap.docs.first.id;
          await AuthService.saveActiveBusinessId(bId);
          if (!mounted) return;
          context.go('/dashboard', extra: bId);
        } else {
          context.go('/business-selector');
        }
      } catch (firestoreError) {
        debugPrint('Firestore query in PIN setup handled: $firestoreError');
        if (!mounted) return;
        if (savedBusinessId != null && savedBusinessId.isNotEmpty) {
          context.go('/dashboard', extra: savedBusinessId);
        } else {
          context.go('/business-type');
        }
      }
    } catch (e) {
      debugPrint('Error after PIN setup: $e');
      if (mounted) context.go('/business-type');
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirmStep ? _confirmedPin : _pin;

    return WebAuthLayout(
      heroTitle: 'Set Up Your PIN',
      heroSubtitle: 'Create a secure 4-digit PIN to keep your store dashboard safe.',
      mobileForm: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isConfirmStep
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText, size: 22),
                tooltip: 'Back to PIN creation',
                onPressed: _backToStepOne,
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, size: 13, color: AppColors.kPrimary),
                  const SizedBox(width: 5),
                  Text(
                    _isConfirmStep ? 'Step 2 of 2' : 'Step 1 of 2',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // ── Step Progress Line ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: _isConfirmStep ? AppColors.kPrimary : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Icon & Header (Animated Transition) ───────────
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.kPrimary.withValues(alpha: 0.15)),
              ),
              child: Icon(
                _isConfirmStep ? LucideIcons.keyRound : LucideIcons.lock,
                color: AppColors.kPrimary,
                size: 26,
              ),
            ),

            const SizedBox(height: 18),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _isConfirmStep ? 'Confirm your PIN' : 'Create a 4-Digit PIN',
                key: ValueKey<bool>(_isConfirmStep),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kDarkText,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _isConfirmStep
                      ? 'Re-enter your 4-digit PIN to ensure it matches.'
                      : 'Set a memorable PIN to protect your partner account on this device.',
                  key: ValueKey<bool>(_isConfirmStep),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── PIN Boxes (Fintech Standard) ──────────────────
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) => Transform.translate(
                offset: Offset(_shakeAnim.value * (_shakeCtrl.value < 0.5 ? 1 : -1), 0),
                child: child,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                  final isFilled = i < currentPin.length;
                  final isFocused = i == currentPin.length;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 54,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? Colors.white
                          : (isFocused ? Colors.white : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFocused
                            ? AppColors.kPrimary
                            : (isFilled ? AppColors.kPrimary.withValues(alpha: 0.6) : const Color(0xFFE2E8F0)),
                        width: isFocused ? 2.2 : 1.5,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: AppColors.kPrimary.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : (isFilled
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null),
                    ),
                    child: Center(
                      child: isFilled
                          ? TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutBack,
                              builder: (_, val, child) => Transform.scale(
                                scale: val,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: AppColors.kPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )
                          : (isFocused
                              ? Container(
                                  width: 2,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.kPrimary,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                )
                              : null),
                    ),
                  );
                }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Error Banner or Helper Message ────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 38,
              child: _errorMsg.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.alertCircle, color: Color(0xFFE53E3E), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _errorMsg,
                            style: const TextStyle(
                              color: Color(0xFFC53030),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : (_isConfirmStep
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _backToStepOne,
                              icon: const Icon(LucideIcons.edit2, size: 13, color: AppColors.kPrimary),
                              label: const Text(
                                'Change initial PIN',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.kPrimary,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Avoid simple patterns like 1234 or your birth year',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.kLightText.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        )),
            ),

            const Spacer(),

            // ── Numeric Keypad (Tactile & Clean) ──────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 18),
              child: _loading
                  ? const SizedBox(
                      height: 240,
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.kPrimary),
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        children: [
                          for (final row in [
                            ['1', '2', '3'],
                            ['4', '5', '6'],
                            ['7', '8', '9'],
                            ['', '0', '⌫'],
                          ])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildNumpadKey(row[0]),
                                  const SizedBox(width: 18),
                                  _buildNumpadKey(row[1]),
                                  const SizedBox(width: 18),
                                  _buildNumpadKey(row[2]),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      ],
      ),
      ),
    ));
  }

  Widget _buildNumpadKey(String digit) {
    if (digit.isEmpty) {
      return const SizedBox(width: 76, height: 64);
    }

    final isBackspace = digit == '⌫';

    return GestureDetector(
      onTap: () => isBackspace ? _onBackspace() : _onDigit(digit),
      onLongPress: isBackspace ? _onClearAll : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 76,
        height: 64,
        decoration: BoxDecoration(
          color: isBackspace ? Colors.transparent : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: isBackspace ? null : Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Center(
          child: isBackspace
              ? const Icon(
                  LucideIcons.delete,
                  color: Color(0xFF0F172A),
                  size: 24,
                )
              : Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
        ),
      ),
    );
  }
}
