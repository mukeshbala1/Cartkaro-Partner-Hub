import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/web_auth_layout.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────
  String _pin = '';
  String _errorMsg = '';
  bool _loading = false;
  String _userName = 'Partner';
  DeviceBiometricInfo? _bioInfo;

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

    _fetchUserName();
    _initBiometric();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Check FirebaseAuth displayName
      final authName = user.displayName?.trim();
      if (authName != null && authName.isNotEmpty) {
        if (mounted) {
          setState(() {
            _userName = authName.split(' ').first;
          });
        }
        return;
      }

      // 2. Query Firestore businesses collection
      final businessSnap = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (businessSnap.docs.isNotEmpty) {
        final data = businessSnap.docs.first.data();
        final ownerName = (data['ownerName'] as String?)?.trim();
        if (ownerName != null && ownerName.isNotEmpty) {
          if (mounted) {
            setState(() {
              _userName = ownerName.split(' ').first;
            });
          }
          return;
        }
      }

      // 3. Query Firestore users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final name = (data?['name'] ?? data?['fullName']) as String?;
        if (name != null && name.trim().isNotEmpty) {
          if (mounted) {
            setState(() {
              _userName = name.trim().split(' ').first;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
  }

  Future<void> _initBiometric() async {
    final info = await AuthService.getDeviceBiometricInfo();
    if (mounted) {
      setState(() {
        _bioInfo = info;
      });
      // Auto-trigger biometric on screen load ONLY if enrolled & enabled by user
      if (info.isEnabledByUser && info.isEnrolled) {
        Future.delayed(const Duration(milliseconds: 600), () => _tryBiometric(isAuto: true));
      }
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────

  void _onDigit(String digit) {
    HapticFeedback.lightImpact();
    if (_pin.length >= 4 || _loading) return;
    setState(() {
      _errorMsg = '';
      _pin += digit;
    });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 180), _verifyPin);
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_pin.isEmpty || _loading) return;
    setState(() {
      _errorMsg = '';
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _onClearAll() {
    HapticFeedback.mediumImpact();
    if (_pin.isEmpty || _loading) return;
    setState(() {
      _errorMsg = '';
      _pin = '';
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _loading = true);
    final isValid = await AuthService.verifyPin(_pin);
    if (!mounted) return;

    if (isValid) {
      HapticFeedback.mediumImpact();
      _navigateToDashboard();
    } else {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _errorMsg = 'Incorrect PIN. Please try again.';
        _pin = '';
        _loading = false;
      });
    }
  }

  Future<void> _tryBiometric({bool isAuto = false}) async {
    if (_loading) return;
    HapticFeedback.lightImpact();
    if (!isAuto) {
      setState(() {
        _loading = true;
        _errorMsg = '';
      });
    }

    final result = await AuthService.authenticateWithBiometricsDetailed(
      customReason: _bioInfo?.promptReason,
    );
    if (!mounted) return;
    if (!isAuto) {
      setState(() => _loading = false);
    }

    if (result.success) {
      HapticFeedback.mediumImpact();
      _navigateToDashboard();
      return;
    }

    // Do NOT show error messages for background auto-prompts
    if (isAuto) return;

    if (result.isNotEnrolled || result.isNotAvailable) {
      _showBiometricNotEnrolledDialog();
    } else if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
      setState(() {
        _errorMsg = result.errorMessage!;
      });
    }
  }

  void _showBiometricNotEnrolledDialog() {
    final label = _bioInfo?.label ?? 'Biometrics';
    final icon = _bioInfo?.icon ?? LucideIcons.fingerprint;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.kPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$label Not Set',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kDarkText,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '$label is supported by this device, but no credentials are registered in device Settings.\n\nYou can enter your 4-digit PIN, or tap below to test the unlock flow.',
          style: const TextStyle(fontSize: 14, color: AppColors.kLightText, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Enter PIN Instead',
              style: TextStyle(color: AppColors.kLightText, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateToDashboard();
            },
            child: const Text(
              'Test Unlock (Emulator)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToDashboard() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('businesses')
          .where('ownerUid', isEqualTo: user.uid)
          .get();
      if (!mounted) return;
      if (snap.docs.isEmpty) {
        context.go('/business-type');
      } else if (snap.docs.length == 1) {
        context.go('/dashboard', extra: snap.docs.first.id);
      } else {
        context.go('/business-selector');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bioLabel = _bioInfo?.label ?? 'Biometrics';
    final bioIcon = _bioInfo?.icon ?? LucideIcons.fingerprint;
    final isBioAvailable = _bioInfo?.isSupported ?? false;

    return WebAuthLayout(
      heroTitle: 'Welcome Back',
      heroSubtitle: 'Enter your secure PIN to access your dashboard quickly.',
      mobileForm: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFF0F172A)),
              SizedBox(width: 6),
              Text(
                'CartKaro Secure Entry',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // ── App Logo at Top Right Corner ───────────────────
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.shoppingBag, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  const SizedBox(height: 28),

            // ── Greeting & Comment (Deep Dark High-Contrast) ───
            Text(
              'Hi, $_userName',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.6,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter your CartKaro PIN',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),

            const SizedBox(height: 36),

            // ── 4-Digit PIN Card Boxes ────────────────────────
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
                  final isFilled = i < _pin.length;
                  final isFocused = i == _pin.length;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 56,
                    height: 62,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? Colors.white
                          : (isFocused ? Colors.white : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isFocused
                            ? const Color(0xFF0F172A)
                            : (isFilled ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
                        width: isFocused ? 2.4 : 1.8,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.14),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : (isFilled
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                  width: 15,
                                  height: 15,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0F172A),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            )
                          : (isFocused
                              ? Container(
                                  width: 2.2,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
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

            // ── Prominent Dark Biometric Button ───────────────
            if (isBioAvailable) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _tryBiometric(isAuto: false),
                icon: Icon(bioIcon, size: 19, color: Colors.white),
                label: Text(
                  'Use $bioLabel',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 2,
                  shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Error Banner ──────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 38,
              child: _errorMsg.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 36),
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
                          Flexible(
                            child: Text(
                              _errorMsg,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFC53030),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const Spacer(),

            // ── Standard System Numpad ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(36, 0, 36, 12),
              child: _loading
                  ? const SizedBox(
                      height: 240,
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        children: [
                        for (final row in [
                          [
                            {'d': '1', 'sub': ''},
                            {'d': '2', 'sub': 'ABC'},
                            {'d': '3', 'sub': 'DEF'},
                          ],
                          [
                            {'d': '4', 'sub': 'GHI'},
                            {'d': '5', 'sub': 'JKL'},
                            {'d': '6', 'sub': 'MNO'},
                          ],
                          [
                            {'d': '7', 'sub': 'PQRS'},
                            {'d': '8', 'sub': 'TUV'},
                            {'d': '9', 'sub': 'WXYZ'},
                          ],
                          [
                            {'d': '', 'sub': ''},
                            {'d': '0', 'sub': '+'},
                            {'d': '⌫', 'sub': ''},
                          ],
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: row.map((k) {
                                return _buildNumpadKey(
                                  digit: k['d']!,
                                  sub: k['sub']!,
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
            ),

            // ── Minimal Footer (High Contrast) ────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: () async {
                  final router = GoRouter.of(context);
                  await FirebaseAuth.instance.signOut();
                  await AuthService.clearPin();
                  if (mounted) router.go('/login');
                },
                icon: const Icon(LucideIcons.logOut, size: 15, color: Color(0xFF0F172A)),
                label: const Text(
                  'Switch Account',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
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

  Widget _buildNumpadKey({
    required String digit,
    required String sub,
  }) {
    // ── Blank Corner Spacer ───────────────────────────────────
    if (digit.isEmpty) {
      return const SizedBox(width: 76, height: 64);
    }

    // ── Backspace Key (Bottom-Right) ──────────────────────────
    final isBackspace = digit == '⌫';
    if (isBackspace) {
      return GestureDetector(
        onTap: _onBackspace,
        onLongPress: _onClearAll,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 76,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Center(
            child: Icon(
              LucideIcons.delete,
              color: Color(0xFF0F172A),
              size: 24,
            ),
          ),
        ),
      );
    }

    // ── Standard System Numeric Keys ──────────────────────────
    return GestureDetector(
      onTap: () => _onDigit(digit),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 76,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
              if (sub.isNotEmpty)
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF334155),
                    letterSpacing: 1.2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
