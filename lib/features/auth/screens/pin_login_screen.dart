import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({Key? key}) : super(key: key);

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.kDarkText, size: 22),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0), // Reduced from 24.0
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320), // Reduced from 400
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16), // Reduced from 20
                  child: Image.asset(
                    'assets/logo.png',
                    height: 80, // Reduced from 100
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(LucideIcons.shoppingBag, size: 48, color: AppColors.kPrimary), // Size reduced from 64
                  ),
                ),
                const SizedBox(height: 24), // Reduced from 32
                Text(
                  "Welcome Back!",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.kDarkText,
                        fontSize: 24, // Explicitly slightly smaller
                      ),
                ),
                const SizedBox(height: 6), // Reduced from 8
                Text(
                  "Enter your 4-digit PIN to access your dashboard.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.kLightText,
                        fontSize: 14, // Explicitly slightly smaller
                      ),
                ),
                const SizedBox(height: 32), // Reduced from 48
                
                // PIN Input Field
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  obscuringCharacter: '●',
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 16, color: AppColors.kPrimary), // Reduced fontSize from 32, letterSpacing from 24
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "••••",
                    hintStyle: const TextStyle(color: AppColors.kBorder, letterSpacing: 16), // Reduced letterSpacing from 24
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), // Reduced from 16
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.kPrimary, width: 2),
                      borderRadius: BorderRadius.circular(12), // Reduced from 16
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Reduced from 24

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Demo verification
                      if (_pinController.text == '1234') {
                        context.go('/dashboard');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 16
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Reduced from 12
                    ),
                    child: const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), // Reduced fontSize from 18
                  ),
                ),
                const SizedBox(height: 12), // Reduced from 16
                
                TextButton(
                  onPressed: () {
                    // Yahan Forgot PIN / OTP verify ka bottom sheet ya screen khulega
                    _showForgotPinBottomSheet(context);
                  },
                  child: const Text("Forgot PIN?", style: TextStyle(color: AppColors.kPrimary, fontWeight: FontWeight.bold, fontSize: 13)), // Slightly smaller
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPinBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), // Reduced from 24
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0), // Reduced from 24.0
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Reset PIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Reduced fontSize from 20
              const SizedBox(height: 12), // Reduced from 16
              const Text("We will send an OTP to your registered mobile number to reset your PIN.", style: TextStyle(fontSize: 14)), // Slightly smaller
              const SizedBox(height: 16), // Reduced from 24
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimary, padding: const EdgeInsets.symmetric(vertical: 12)), // Reduced from 16
                  onPressed: () {
                    Navigator.pop(context); // Pehle Bottom Sheet band karo
                    context.push('/reset-pin'); // Fir naye page par bhej do
                  }, // Aage OTP screen pe bhejenge
                  child: const Text("Send OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), // Slightly smaller
                ),
              ),
              const SizedBox(height: 16), // Reduced from 24
            ],
          ),
        );
      },
    );
  }
}