import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    
    _controller.forward();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final results = await Future.wait([
        Future.delayed(const Duration(milliseconds: 2200)),
        AuthService.isPinSet(),
      ]);
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;

      // No Firebase session → go to login
      if (user == null) {
        context.go('/login');
        return;
      }

      final pinSet = results[1] as bool? ?? false;
      if (!pinSet) {
        context.go('/pin-setup');
      } else {
        context.go('/pin-login');
      }
    } catch (e) {
      debugPrint('Error during splash check: $e');
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24), 
                child: Image.asset(
                  'assets/logo.png',
                  height: 120, 
                  width: 120,
                  fit: BoxFit.contain, 
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "CartKaro Partner",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.kDarkText,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "One platform to grow your business",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.kLightText,
                    ),
              ),
              const SizedBox(height: 48),
              
              // Loading Spinner - Color updated to App brand color
              const SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(
                  color: AppColors.kPrimary,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
