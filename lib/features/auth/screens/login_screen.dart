import 'dart:async';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/web_auth_layout.dart';

// ── Brand tokens ────────────────────────────────────────────────
const Color kBrand = Color(0xFF223554);
const Color kBrandDark = Color(0xFF0F1923);
const Color kBrandMid = Color(0xFF1A2D47);
const Color kAccentBlue = Color(0xFF4A9EFF);
const Color kWhite = Colors.white;
const Color kBodyText = Color(0xFF0F1923);
const Color kSubText = Color(0xFF7A8FA6);
const Color kInputBg = Color(0xFFF8FAFC);
const Color kBorder = Color(0xFFE8EDF2);

// ── Country model ───────────────────────────────────────────────
class Country {
  final String flag, name, code;
  const Country(this.flag, this.name, this.code);
}

const List<Country> kCountries = [
  Country('🇮🇳', 'India', '+91'),
  Country('🇺🇸', 'USA', '+1'),
  Country('🇬🇧', 'UK', '+44'),
  Country('🇦🇺', 'Australia', '+61'),
  Country('🇦🇪', 'UAE', '+971'),
  Country('🇧🇩', 'Bangladesh', '+880'),
  Country('🇵🇰', 'Pakistan', '+92'),
];

// ── Floating rectangle data ─────────────────────────────────────
class FloatRect {
  final double w, h, x, y, radius, opacity;
  final Duration delay;
  const FloatRect({
    required this.w,
    required this.h,
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.delay,
  });
}

const List<FloatRect> kFloatRects = [
  FloatRect(
    w: 280,
    h: 340,
    x: -60,
    y: -60,
    radius: 40,
    opacity: 0.70,
    delay: Duration.zero,
  ),
  FloatRect(
    w: 200,
    h: 250,
    x: -80,
    y: 80,
    radius: 50,
    opacity: 0.45,
    delay: Duration(seconds: 3),
  ),
  FloatRect(
    w: 140,
    h: 180,
    x: 20,
    y: 300,
    radius: 30,
    opacity: 0.30,
    delay: Duration(seconds: 5),
  ),
  FloatRect(
    w: 100,
    h: 120,
    x: -30,
    y: -80,
    radius: 22,
    opacity: 0.25,
    delay: Duration(seconds: 2),
  ),
];

// ══════════════════════════════════════════════════════════════════
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { phone, otp, success }

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  _Step _step = _Step.phone;
  bool _loading = false;
  String _error = '';
  Country _country = kCountries[0];
  String? _verificationId;
  int? _forceResendingToken;

  final _phoneCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrl = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  // Animations
  late AnimationController _heroCtrl;
  late AnimationController _formCtrl;
  late AnimationController _stepCtrl;

  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;
  late Animation<double> _stepFade;

  Timer? _resendTimer;
  int _resendSec = 30;

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _formCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic));
    _formFade = CurvedAnimation(parent: _formCtrl, curve: Curves.easeOut);

    _stepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 120), () {
      _formCtrl.forward();
      _stepCtrl.forward();
    });
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _formCtrl.dispose();
    _stepCtrl.dispose();
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    for (final c in _otpCtrl) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  // ── OTP logic ─────────────────────────────────────────────────
  String get _phoneNumber => '${_country.code}${_phoneCtrl.text.trim()}';

  String? _phoneValidationError(String phone) {
    if (phone.length != 10) {
      return 'Enter a valid 10-digit number';
    }
    if (_country.code == '+91' &&
        !RegExp(r'^[6-9]').hasMatch(phone) &&
        !kDebugMode &&
        phone != '5555555555') {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  Future<String?> _networkReadinessError() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasNetwork = connectivity.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!hasNetwork) {
        return 'No internet connection. Please try again.';
      }
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
    }
    return null;
  }

  String _authErrorMessage(FirebaseAuthException e) {
    final rawMsg = e.message ?? '';
    final code = e.code.toLowerCase();
    final msgLower = rawMsg.toLowerCase();

    // Clear feedback when on Firebase free Spark plan
    if (code.contains('billing') ||
        msgLower.contains('billing_not_enabled') ||
        msgLower.contains('17499')) {
      return 'Please upgrade your plan .';
    }

    late final String message;
    switch (e.code) {
      case 'network-request-failed':
        message = 'Network connection failed. Please check internet and try again.';
        break;
      case 'invalid-phone-number':
        message = 'Enter a valid phone number with country code.';
        break;
      case 'too-many-requests':
        message = 'Too many OTP requests. Please wait and try again later.';
        break;
      case 'quota-exceeded':
        message = 'SMS quota reached. Upgrade and try again later.';
        break;
      case 'operation-not-allowed':
        message = 'Phone login is not enabled Authentication.';
        break;
      case 'app-not-authorized':
      case 'missing-client-identifier':
        message =
            'App verification failed. Add debug/release SHA-1 & SHA-256 in Firebase Console.';
        break;
      case 'invalid-verification-code':
        message = 'Wrong OTP. Please check the code and try again.';
        break;
      case 'session-expired':
        message = 'OTP expired. Please request a new code.';
        break;
      default:
        message = rawMsg.isNotEmpty ? rawMsg : 'Could not send OTP. Please try again.';
    }
    return kDebugMode ? '$message (${e.code})' : message;
  }

  void _setAuthError(FirebaseAuthException e) {
    debugPrint('Phone auth failed: ${e.code} - ${e.message}');
    setState(() {
      _loading = false;
      _error = _authErrorMessage(e);
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isEmpty && index > 0) {
      _otpFocus[index - 1].requestFocus();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _otpFocus[index + 1].requestFocus();
    }
    final full = _otpCtrl.map((c) => c.text).join();
    if (full.length == 6) {
      _verifyOtp();
    }
  }

  // ── Actions ───────────────────────────────────────────────────
  Future<void> _sendOtp({bool forceResend = false}) async {
    final phone = _phoneCtrl.text.trim();
    final validationError = _phoneValidationError(phone);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    final networkError = await _networkReadinessError();
    if (networkError != null) {
      setState(() => _error = networkError);
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    for (final controller in _otpCtrl) {
      controller.clear();
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneNumber,
        forceResendingToken: forceResend ? _forceResendingToken : null,
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (!mounted) return;
            _resendTimer?.cancel();
            await _handlePostAuthNavigation();
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;
            _setAuthError(e);
          } catch (e) {
            if (!mounted) return;
            debugPrint('Auto verification failed: $e');
            setState(() {
              _loading = false;
              _error = 'Auto verification failed. Please enter OTP manually.';
            });
          }
        },
        verificationFailed: (e) {
          if (!mounted) return;
          _setAuthError(e);
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          debugPrint('Phone auth code sent to $_phoneNumber');
          _verificationId = verificationId;
          _forceResendingToken = resendToken;
          _transitionTo(_Step.otp);
          setState(() => _loading = false);
          _startResend();
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) _otpFocus[0].requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _setAuthError(e);
    } catch (e) {
      if (!mounted) return;
      debugPrint('phone auth request failed: $e');
      setState(() {
        _loading = false;
        _error = 'Could not send OTP. Please try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.map((c) => c.text).join();
    if (otp.length < 6) {
      setState(() => _error = 'Enter all 6 digits');
      return;
    }
    final verificationId = _verificationId;
    if (verificationId == null) {
      setState(() => _error = 'Please request OTP again');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      _resendTimer?.cancel();
      await _handlePostAuthNavigation();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _authErrorMessage(e));
    } catch (e) {
      if (!mounted) return;
      debugPrint(' OTP verification failed: $e');
      setState(() => _error = 'Could not verify OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handlePostAuthNavigation() async {
    final hasPin = await AuthService.isPinSet();
    if (!mounted) return;
    if (!hasPin) {
      context.go('/pin-setup');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('businesses')
            .where('ownerUid', isEqualTo: user.uid)
            .get();

        if (!mounted) return;

        if (querySnapshot.docs.isEmpty) {
          _transitionTo(_Step.success);
          return;
        } else if (querySnapshot.docs.length == 1) {
          context.go('/dashboard', extra: querySnapshot.docs.first.id);
          return;
        } else {
          context.go('/business-selector');
          return;
        }
      } catch (e) {
        debugPrint('Error checking businesses: $e');
      }
    }

    if (!mounted) return;
    _transitionTo(_Step.success);
  }

  void _transitionTo(_Step next) {
    _stepCtrl.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _step = next;
        _error = '';
      });
      _stepCtrl.forward();
    });
  }

  void _goBack() {
    _resendTimer?.cancel();
    for (final c in _otpCtrl) {
      c.clear();
    }
    _verificationId = null;
    _transitionTo(_Step.phone);
  }

  void _startResend() {
    _resendTimer?.cancel();
    setState(() => _resendSec = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendSec <= 0) {
        _resendTimer?.cancel();
        return;
      }
      setState(() => _resendSec--);
    });
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // KEY FIX: Use Scaffold with resizeToAvoidBottomInset: true (default)
    // and let the Column use Expanded for hero + intrinsic for form card.
    // No fixed height SizedBox — that's what caused the overflow.
    return WebAuthLayout(
      heroTitle: 'Partner Hub Login',
      heroSubtitle: 'Access your dashboard, manage orders, and grow your business with CartKaro.',
      mobileForm: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: kBrandDark,
        body: Stack(
          children: [
            // Floating bg rects — purely decorative, don't affect layout
            ..._buildFloatingRects(size),

            // Main layout: full screen column inside SafeArea
            SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // Hero section — takes all available space above the card
                  Expanded(child: _buildHeroSection()),

                  // Form card — slides up, hugs content, keyboard pushes it up
                  // naturally because Scaffold resizes its body
                  SlideTransition(
                    position: _formSlide,
                    child: FadeTransition(
                      opacity: _formFade,
                      child: _buildFormCard(size),
                    ),
                  ),
                      ],
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

  // ── Floating background rectangles ────────────────────────────
  List<Widget> _buildFloatingRects(Size size) {
    return kFloatRects.asMap().entries.map((e) {
      final r = e.value;
      final phase = (e.key * 2.5) % (2 * math.pi);
      return AnimatedBuilder(
        animation: _heroCtrl,
        builder: (context, _) {
          final t = _heroCtrl.value;
          final dy = math.sin((t * math.pi * 2) + phase) * 14.0;
          final rot = math.sin((t * math.pi * 2) + phase) * 0.02;
          final dx = r.x < 0 ? size.width + r.x : r.x;
          return Positioned(
            left: dx,
            top: r.y < 0 ? null : r.y,
            bottom: r.y < 0 ? -r.y : null,
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: rot,
                child: Opacity(
                  opacity: r.opacity,
                  child: Container(
                    width: r.w,
                    height: r.h,
                    decoration: BoxDecoration(
                      color: kBrandMid,
                      borderRadius: BorderRadius.circular(r.radius),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  // ── Hero top ──────────────────────────────────────────────────
  Widget _buildHeroSection() {
    return SingleChildScrollView(
      // Hero scrolls if needed on very small screens
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo row
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    "assets/logo.png",
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CartKaro',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Partner Hub',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Headline
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.07,
                ),
                children: [
                  TextSpan(
                    text: 'Sell more,\nstress ',
                    style: TextStyle(color: kWhite),
                  ),
                  TextSpan(
                    text: 'less.',
                    style: TextStyle(color: kAccentBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your store. Your rules.\nStart selling in minutes.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.52),
                fontSize: 14.5,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Trust pills
            Row(
              children: [
                _trustPill(LucideIcons.zap, '10k+ Sellers'),
                const SizedBox(width: 10),
                _trustPill(LucideIcons.shieldCheck, 'Secure Login'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kAccentBlue, size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: kWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ─────────────────────────────────────────────────
  // KEY FIX: No SingleChildScrollView here — Scaffold already resizes
  // the body when keyboard appears. The card just sizes to its content.
  Widget _buildFormCard(Size size) {
    return Container(
      width: size.width,
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      // KEY FIX: Bottom padding accounts for safe area (home indicator)
      // but NOT for keyboard — Scaffold handles that via resizeToAvoidBottomInset
      padding: EdgeInsets.fromLTRB(
        28,
        28,
        28,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: FadeTransition(
        opacity: _stepFade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_step != _Step.success) _buildStepBar(),
            if (_step != _Step.success) const SizedBox(height: 20),
            if (_error.isNotEmpty) _buildError(),
            if (_step == _Step.phone) _buildPhoneStep(),
            if (_step == _Step.otp) _buildOtpStep(),
            if (_step == _Step.success) _buildSuccessStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBar() {
    return Row(
      children: [
        Expanded(flex: 2, child: _stepSegment(true)),
        const SizedBox(width: 6),
        Expanded(
          flex: _step == _Step.otp ? 2 : 1,
          child: _stepSegment(_step == _Step.otp),
        ),
      ],
    );
  }

  Widget _stepSegment(bool active) => AnimatedContainer(
    duration: const Duration(milliseconds: 350),
    height: 4,
    decoration: BoxDecoration(
      color: active ? kBrand : kBorder,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertCircle,
            color: Color(0xFFE53E3E),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error,
              style: const TextStyle(
                color: Color(0xFFC53030),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone step ────────────────────────────────────────────────
  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Enter your\nmobile number',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: kBodyText,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          "We'll send a one-time code to verify",
          style: TextStyle(fontSize: 13.5, color: kSubText, height: 1.5),
        ),
        const SizedBox(height: 22),
        _fieldLabel('Mobile Number'),
        const SizedBox(height: 7),
        _buildPhoneField(),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.info, size: 13, color: kSubText.withOpacity(0.7)),
            const SizedBox(width: 5),
            Text(
              'Works with any Indian mobile number',
              style: TextStyle(
                fontSize: 11.5,
                color: kSubText.withOpacity(0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _buildCtaButton(
          label: 'Get OTP',
          icon: LucideIcons.arrowRight,
          onTap: _sendOtp,
        ),
        const SizedBox(height: 12),
        _buildStatsRow(),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: kInputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 1.5),
      ),
      child: Row(
        children: [
          // Country picker
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: kBorder, width: 1.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_country.flag, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 6),
                  Text(
                    _country.code,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kBodyText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    LucideIcons.chevronDown,
                    size: 13,
                    color: kSubText,
                  ),
                ],
              ),
            ),
          ),
          // Phone input
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: kBodyText,
                letterSpacing: 0.4,
              ),
              decoration: InputDecoration(
                hintText: '10-digit number',
                hintStyle: TextStyle(
                  color: kSubText.withOpacity(0.5),
                  fontWeight: FontWeight.w400,
                  fontSize: 14.5,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _stat('10K+', 'Sellers'),
        _vertDivider(),
        _stat('₹2Cr+', 'Orders'),
        _vertDivider(),
        _stat('4.9★', 'Rating'),
      ],
    );
  }

  Widget _stat(String val, String label) => Expanded(
    child: Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: kBodyText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: kSubText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _vertDivider() => Container(
    width: 1,
    height: 32,
    color: kBorder,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );

  // ── OTP step ─────────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: kBodyText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Code sent to ${_country.code} ${_phoneCtrl.text}',
          style: const TextStyle(fontSize: 13.5, color: kSubText),
        ),
        const SizedBox(height: 22),
        _fieldLabel('6-Digit Code'),
        const SizedBox(height: 8),
        _buildOtpBoxes(),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(LucideIcons.clock, size: 13, color: kSubText.withOpacity(0.7)),
            const SizedBox(width: 5),
            TextButton(
              onPressed: _resendSec > 0 || _loading
                  ? null
                  : () => _sendOtp(forceResend: true),
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _resendSec > 0 ? 'Resend in ${_resendSec}s' : 'Resend OTP',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _resendSec > 0 ? kSubText.withOpacity(0.8) : kBrand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _buildCtaButton(
          label: 'Verify & Continue',
          icon: LucideIcons.checkCircle,
          onTap: _verifyOtp,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _goBack,
          icon: const Icon(LucideIcons.arrowLeft, size: 15, color: kSubText),
          label: const Text(
            'Change number',
            style: TextStyle(
              fontSize: 13.5,
              color: kSubText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      children: List.generate(
        6,
        (i) => Expanded(
          child: Container(
            height: 52,
            margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
            decoration: BoxDecoration(
              color: kInputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder, width: 1.5),
            ),
            child: TextField(
              controller: _otpCtrl[i],
              focusNode: _otpFocus[i],
              keyboardType: TextInputType.number,
              maxLength: 1,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => _onOtpChanged(v, i),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kBrand,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Success step ──────────────────────────────────────────────
  Widget _buildSuccessStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.elasticOut,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF0FFF4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              size: 32,
              color: Color(0xFF22C55E),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "You're in!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: kBodyText,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Welcome back to CartKaro',
          style: TextStyle(fontSize: 14, color: kSubText),
        ),
        const SizedBox(height: 28),
        _buildCtaButton(
          label: 'Continue',
          icon: LucideIcons.arrowRight,
          onTap: () async {
            final hasPin = await AuthService.isPinSet();
            if (!mounted) return;
            if (!hasPin) {
              context.go('/pin-setup');
              return;
            }
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              try {
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
                return;
              } catch (e) {
                debugPrint('Error navigating from success step: $e');
              }
            }
            if (mounted) context.go('/business-type');
          },
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/business-type'),
          child: const Text('Register New Business', style: TextStyle(color: kBrand, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // ── Shared widgets ───────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: kBodyText,
      letterSpacing: 0.3,
    ),
  );

  Widget _buildCtaButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 54,
        decoration: BoxDecoration(
          color: _loading ? kBrand.withOpacity(0.8) : kBrand,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: kBrand.withOpacity(0.32),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(kWhite),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: kWhite,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(icon, size: 17, color: Colors.white.withOpacity(0.8)),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Country picker bottom sheet ───────────────────────────────
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select country',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kBodyText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...kCountries.map((c) {
              final isSel = c.code == _country.code;
              return InkWell(
                onTap: () {
                  setState(() => _country = c);
                  Navigator.pop(context);
                },
                child: Container(
                  color: isSel ? const Color(0xFFF0F5FF) : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Text(c.flag, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSel
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: kBodyText,
                          ),
                        ),
                      ),
                      Text(
                        c.code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSel ? kBrand : kSubText,
                        ),
                      ),
                      if (isSel) ...[
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.check, size: 16, color: kBrand),
                      ],
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}
