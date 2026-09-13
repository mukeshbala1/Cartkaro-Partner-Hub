import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/web_auth_layout.dart';

enum _ResetStep { phone, otp, newPin }

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  // ── Flow Step & Loading State ─────────────────────────────────
  _ResetStep _step = _ResetStep.phone;
  bool _loading = false;
  String _errorMessage = '';

  // ── Phone & OTP Controllers ───────────────────────────────────
  late final TextEditingController _phoneController;
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  // ── PIN Controllers ───────────────────────────────────────────
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _obscurePin = true;

  // ── Firebase Auth Session State ───────────────────────────────
  String? _verificationId;
  int? _resendToken;
  Timer? _countdownTimer;
  Timer? _watchdogTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isEditingPhone = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final initialPhone = user?.phoneNumber ?? '';

    // If phone has country code +91, extract clean 10-digit number for display
    final cleanDigits = _extractTenDigits(initialPhone);
    _phoneController = TextEditingController(
      text: cleanDigits.isNotEmpty ? cleanDigits : initialPhone,
    );

    if (cleanDigits.isEmpty) {
      _isEditingPhone = true;
      _loadPhoneFromFirestore();
    }
  }

  Future<void> _loadPhoneFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('partners').doc(uid).get();
      if (doc.exists && mounted) {
        final phone = doc.data()?['phoneNumber'] as String?;
        if (phone != null && phone.isNotEmpty) {
          final digits = _extractTenDigits(phone);
          setState(() {
            _phoneController.text = digits.isNotEmpty ? digits : phone;
            _isEditingPhone = false;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _watchdogTimer?.cancel();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // ── Phone Sanitization Helpers ─────────────────────────────────
  static String _extractTenDigits(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    return digits;
  }

  String get _formattedE164Phone {
    final digits = _extractTenDigits(_phoneController.text.trim());
    return '+91$digits';
  }

  String get _displayFormattedPhone {
    final digits = _extractTenDigits(_phoneController.text.trim());
    if (digits.length == 10) {
      return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return _phoneController.text.trim();
  }

  // ── Timer Logic ────────────────────────────────────────────────
  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  // ── Firebase Error Message Mapper ──────────────────────────────
  String _authErrorMessage(FirebaseAuthException e) {
    final rawMsg = e.message ?? '';
    final code = e.code.toLowerCase();
    final msgLower = rawMsg.toLowerCase();

    if (code.contains('billing') ||
        msgLower.contains('billing_not_enabled') ||
        msgLower.contains('17499')) {
      return 'SMS service quota reached. Please try again later.';
    }

    switch (e.code) {
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'invalid-phone-number':
        return 'Please enter a valid 10-digit Indian mobile number.';
      case 'too-many-requests':
        return 'Too many OTP requests. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'SMS quota reached. Please try again later.';
      case 'operation-not-allowed':
        return 'Phone authentication is currently unavailable.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'App security verification in progress. Please try again in a moment.';
      case 'invalid-verification-code':
        return 'Wrong OTP code. Please check the code and try again.';
      case 'session-expired':
        return 'OTP has expired. Please tap "Resend OTP".';
      default:
        return rawMsg.isNotEmpty ? rawMsg : 'Could not send OTP. Please try again.';
    }
  }

  // ── Step 1: Send OTP ───────────────────────────────────────────
  Future<void> _sendOtp() async {
    final rawInput = _phoneController.text.trim();
    final digits = _extractTenDigits(rawInput);

    if (digits.length != 10) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    if (!RegExp(r'^[6-9]').hasMatch(digits) && !kDebugMode && digits != '5555555555') {
      setState(() => _errorMessage = 'Please enter a valid Indian mobile number starting with 6, 7, 8, or 9.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    for (final c in _otpControllers) {
      c.clear();
    }

    final fullPhone = _formattedE164Phone;
    debugPrint('ResetPin: Initiating verifyPhoneNumber to $fullPhone');

    // Start 35s watchdog timer so spinner NEVER runs indefinitely
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 35), () {
      if (_loading && mounted) {
        debugPrint('ResetPin: Watchdog triggered due to slow network/verification');
        setState(() {
          _loading = false;
          _errorMessage = 'OTP request is taking longer than usual. Please check your internet or tap Get OTP to try again.';
        });
      }
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhone,
        timeout: const Duration(seconds: 45),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('ResetPin: verificationCompleted (Android auto-verification)');
          _watchdogTimer?.cancel();
          try {
            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser != null) {
              try {
                await currentUser.linkWithCredential(credential);
              } catch (_) {
                await FirebaseAuth.instance.signInWithCredential(credential);
              }
            } else {
              await FirebaseAuth.instance.signInWithCredential(credential);
            }
          } catch (e) {
            debugPrint('ResetPin: Auto-verification sign in error: $e');
          }
          if (!mounted) return;
          setState(() {
            _loading = false;
            _step = _ResetStep.newPin;
            _errorMessage = '';
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('ResetPin: verificationFailed -> ${e.code}: ${e.message}');
          _watchdogTimer?.cancel();
          if (!mounted) return;
          setState(() {
            _loading = false;
            _errorMessage = _authErrorMessage(e);
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('ResetPin: codeSent -> verificationId: $verificationId');
          _watchdogTimer?.cancel();
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _loading = false;
            _step = _ResetStep.otp; // Move immediately to the OTP Page!
            _errorMessage = '';
          });
          _startResendTimer();
          Future.delayed(const Duration(milliseconds: 150), () {
            if (mounted && _otpFocusNodes.isNotEmpty) {
              _otpFocusNodes[0].requestFocus();
            }
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('ResetPin: codeAutoRetrievalTimeout -> verificationId: $verificationId');
          _watchdogTimer?.cancel();
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _loading = false;
            // Ensure UI never gets stuck on phone step if auto-retrieval times out
            if (_step == _ResetStep.phone) {
              _step = _ResetStep.otp;
            }
          });
        },
      );
    } catch (e) {
      _watchdogTimer?.cancel();
      if (!mounted) return;
      debugPrint('ResetPin: verifyPhoneNumber call failed -> $e');
      setState(() {
        _loading = false;
        _errorMessage = 'Could not initiate OTP. Please check your internet and try again.';
      });
    }
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────
  void _onOtpDigitChanged(String value, int index) {
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length == 6) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join().trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit OTP.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Please tap Resend OTP to request a new code.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await currentUser.linkWithCredential(credential);
        } catch (_) {
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _loading = false;
        _errorMessage = '';
        _step = _ResetStep.newPin; // Proceed to set new PIN!
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _authErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Invalid or expired OTP. Please check and try again.';
      });
    }
  }

  // ── Step 3: Save New PIN ───────────────────────────────────────
  Future<void> _resetPin() async {
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.length != 4) {
      setState(() => _errorMessage = 'PIN must be exactly 4 digits.');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(newPin)) {
      setState(() => _errorMessage = 'PIN must contain only numbers.');
      return;
    }
    if (newPin != confirmPin) {
      setState(() => _errorMessage = 'PINs do not match. Please re-enter.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = '';
    });

    try {
      await AuthService.savePin(newPin);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(LucideIcons.checkCircle2, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'PIN successfully reset! Login with your new PIN.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
        ),
      );

      context.go('/pin-login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Could not save new PIN: $e';
      });
    }
  }

  // ── Build Screen UI ────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WebAuthLayout(
      heroTitle: 'Reset Security PIN',
      heroSubtitle: 'Forgot your PIN? Verify your phone number to securely reset it.',
      mobileForm: Scaffold(
        backgroundColor: AppColors.kBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText),
            onPressed: () {
              if (_step == _ResetStep.otp) {
                setState(() {
                  _step = _ResetStep.phone;
                  _errorMessage = '';
                });
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  _buildHeaderIcon(),
                  const SizedBox(height: 20),

                  // Title & Subtitle
                  _buildHeaderTitles(),
                  const SizedBox(height: 28),

                  // Error Message Box
                  if (_errorMessage.isNotEmpty) _buildErrorBox(),

                  // Content based on current step
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_step) {
                      _ResetStep.phone => _buildPhoneStep(),
                      _ResetStep.otp => _buildOtpStep(),
                      _ResetStep.newPin => _buildNewPinStep(),
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header Widgets ─────────────────────────────────────────────
  Widget _buildHeaderIcon() {
    IconData iconData;
    switch (_step) {
      case _ResetStep.phone:
        iconData = LucideIcons.shieldAlert;
        break;
      case _ResetStep.otp:
        iconData = LucideIcons.messageSquareLock;
        break;
      case _ResetStep.newPin:
        iconData = LucideIcons.keyRound;
        break;
    }

    return Center(
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.kPrimary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData,
          size: 36,
          color: AppColors.kPrimary,
        ),
      ),
    );
  }

  Widget _buildHeaderTitles() {
    String title;
    String subtitle;

    switch (_step) {
      case _ResetStep.phone:
        title = "Reset Security PIN";
        subtitle = "Verify your registered mobile number to receive a verification OTP.";
        break;
      case _ResetStep.otp:
        title = "Enter Verification OTP";
        subtitle = "We sent a 6-digit verification code to\n$_displayFormattedPhone";
        break;
      case _ResetStep.newPin:
        title = "Set New Security PIN";
        subtitle = "Create a new 4-digit PIN for quick & secure store login.";
        break;
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.kDarkText,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.kLightText,
                height: 1.4,
              ),
        ),
      ],
    );
  }

  Widget _buildErrorBox() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.alertCircle, color: Color(0xFFE11D48), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Color(0xFFBE123C),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Phone Card & Get OTP Button ────────────────────────
  Widget _buildPhoneStep() {
    return Column(
      key: const ValueKey('step_phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Phone Number Card / Input
        if (!_isEditingPhone && _phoneController.text.trim().isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.phoneCall, size: 20, color: AppColors.kPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registered Mobile Number',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayFormattedPhone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.pencil, size: 18, color: AppColors.kPrimary),
                  tooltip: 'Change number',
                  onPressed: () => setState(() => _isEditingPhone = true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ] else ...[
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🇮🇳', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Text(
                        '+91',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: 1,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Enter 10-digit mobile number",
                      counterText: "",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],

        // GET OTP BUTTON
        ElevatedButton(
          onPressed: _loading ? null : _sendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.kPrimary.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: _loading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Getting OTP...",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Get OTP",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 18),
                  ],
                ),
        ),

        if (_loading) ...[
          const SizedBox(height: 14),
          const Text(
            "Verifying security session & sending SMS OTP...",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ],
      ],
    );
  }

  // ── Step 2: The Dedicated OTP Page ────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey('step_otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Number badge with Change option
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.phone, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  _displayFormattedPhone,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    _countdownTimer?.cancel();
                    setState(() {
                      _step = _ResetStep.phone;
                      _isEditingPhone = true;
                      _errorMessage = '';
                    });
                  },
                  child: const Text(
                    "Change",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 6-digit OTP input boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.kPrimary, width: 2),
                  ),
                ),
                onChanged: (val) => _onOtpDigitChanged(val, index),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),

        // Resend OTP countdown / button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_canResend) ...[
              const Icon(LucideIcons.clock, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                "Resend code in ${_secondsRemaining}s",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: _loading ? null : _sendOtp,
                icon: const Icon(LucideIcons.refreshCw, size: 14, color: AppColors.kPrimary),
                label: const Text(
                  "Resend OTP",
                  style: TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 22),

        // Verify & Continue Button
        ElevatedButton(
          onPressed: _loading ? null : _verifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.kPrimary.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: _loading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Verifying OTP...",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                )
              : const Text(
                  "Verify & Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  // ── Step 3: Set New Security PIN ──────────────────────────────
  Widget _buildNewPinStep() {
    return Column(
      key: const ValueKey('step_new_pin'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Verified Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.shieldCheck, color: Color(0xFF059669), size: 18),
              SizedBox(width: 8),
              Text(
                'Phone Verified Successfully',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // New PIN
        _buildPinInputCard(
          label: "Enter New 4-Digit PIN",
          controller: _newPinController,
        ),
        const SizedBox(height: 16),

        // Confirm PIN
        _buildPinInputCard(
          label: "Confirm New 4-Digit PIN",
          controller: _confirmPinController,
        ),
        const SizedBox(height: 12),

        // Obscure toggle
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() => _obscurePin = !_obscurePin),
            icon: Icon(
              _obscurePin ? LucideIcons.eye : LucideIcons.eyeOff,
              size: 16,
              color: const Color(0xFF64748B),
            ),
            label: Text(
              _obscurePin ? "Show PIN" : "Hide PIN",
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Save PIN Button
        ElevatedButton(
          onPressed: _loading ? null : _resetPin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.kPrimary.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.check, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Save New PIN",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPinInputCard({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: _obscurePin,
      obscuringCharacter: '●',
      maxLength: 4,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 14,
        color: AppColors.kPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.kPrimary, width: 2),
        ),
      ),
    );
  }
}
