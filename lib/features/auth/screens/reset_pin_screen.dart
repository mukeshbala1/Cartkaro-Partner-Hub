import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/web_auth_layout.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  // ── State ──────────────────────────────────────────────────────
  bool _isOtpVerified = false;
  bool _loading = false;
  String _errorMessage = '';

  // Phone & OTP
  late final TextEditingController _phoneController;
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  String? _verificationId;
  int? _resendToken;
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isAutoSending = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    final initialPhone = user?.phoneNumber ?? '';
    _phoneController = TextEditingController(text: initialPhone);

    // If already logged in with a phone number, auto-send OTP
    if (initialPhone.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendOtp();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid phone number.');
      return;
    }

    final formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+91$rawPhone';

    setState(() {
      _loading = true;
      _errorMessage = '';
      _isAutoSending = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          if (!mounted) return;
          setState(() {
            _isOtpVerified = true;
            _loading = false;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _loading = false;
            _isAutoSending = false;
            _errorMessage = e.message ?? 'Verification failed. Please try again.';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _loading = false;
            _isAutoSending = false;
          });
          _startTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isAutoSending = false;
        _errorMessage = 'Failed to send OTP: $e';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP.');
      return;
    }

    if (_verificationId == null) {
      setState(() => _errorMessage = 'Please request an OTP first.');
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

      // Verify credential by reauthenticating or signing in
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.linkWithCredential(credential).catchError((_) async {
          // If already linked or fails, check sign in
          await FirebaseAuth.instance.signInWithCredential(credential);
        });
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _isOtpVerified = true;
        _loading = false;
        _errorMessage = '';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = e.message ?? 'Invalid OTP. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Verification error. Please try again.';
      });
    }
  }

  Future<void> _resetPin() async {
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (newPin.length != 4) {
      setState(() => _errorMessage = 'PIN must be exactly 4 digits.');
      return;
    }
    if (newPin != confirmPin) {
      setState(() => _errorMessage = 'PINs do not match.');
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
          content: Text('PIN successfully reset! Please login with your new PIN.'),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    return WebAuthLayout(
      heroTitle: 'Reset Your PIN',
      heroSubtitle: 'Forgot your PIN? Verify your phone number to securely reset it.',
      mobileForm: Scaffold(
        backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shieldCheck,
                    size: 38,
                    color: AppColors.kPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isOtpVerified ? "Set New PIN" : "Reset Security PIN",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kDarkText,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isOtpVerified
                      ? "Create a new 4-digit security PIN for this device."
                      : "Verify your phone number with OTP to reset your PIN.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.kLightText,
                      ),
                ),
                const SizedBox(height: 28),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Color(0xFFE53E3E), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Color(0xFFC53030),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // STEP 1: OTP Verification
                if (!_isOtpVerified) ...[
                  if (_phoneController.text.isEmpty) ...[
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone Number",
                        hintText: "+91 9876543210",
                        prefixIcon: const Icon(LucideIcons.phone, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _loading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading && _isAutoSending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text("Send OTP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 18),
                  ],

                  if (_verificationId != null || _phoneController.text.isNotEmpty) ...[
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: "000000",
                        counterText: "",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.kPrimary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_canResend)
                          Text(
                            "Resend OTP in ${_secondsRemaining}s",
                            style: const TextStyle(color: AppColors.kLightText, fontSize: 13),
                          )
                        else
                          TextButton(
                            onPressed: _loading ? null : _sendOtp,
                            child: const Text(
                              "Resend OTP",
                              style: TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _loading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Verify & Continue",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ],
                ],

                // STEP 2: Set New PIN
                if (_isOtpVerified) ...[
                  _buildPinField("Enter New 4-Digit PIN", _newPinController),
                  const SizedBox(height: 16),
                  _buildPinField("Confirm New 4-Digit PIN", _confirmPinController),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _resetPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Save New PIN",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _buildPinField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      obscuringCharacter: '●',
      maxLength: 4,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 14,
        color: AppColors.kPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.kPrimary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
