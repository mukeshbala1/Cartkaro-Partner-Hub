import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'core/services/auth_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase init is wrapped in try/catch so the app runs on macOS
  // even without a GoogleService-Info.plist (UI preview mode).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase not configured for this platform (e.g. macOS dev run).
    // The app will still launch for UI development purposes.
    debugPrint('⚠️ Firebase not initialized: $e');
  }

  runApp(const CartKaroPartnerApp());
}

class CartKaroPartnerApp extends StatefulWidget {
  const CartKaroPartnerApp({super.key});

  @override
  State<CartKaroPartnerApp> createState() => _CartKaroPartnerAppState();
}

class _CartKaroPartnerAppState extends State<CartKaroPartnerApp>
    with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedTime;
      _pausedTime = null;
      if (paused != null) {
        final diff = DateTime.now().difference(paused).inMilliseconds;
        if (diff > 300) {
          _checkAndLockApp();
        }
      }
    }
  }

  Future<void> _checkAndLockApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isPinSet = await AuthService.isPinSet();
      if (!isPinSet) return;

      final location = AppRouter.router.routerDelegate.currentConfiguration.uri.toString();
      if (location.startsWith('/login') ||
          location.startsWith('/pin-login') ||
          location.startsWith('/splash') ||
          location.startsWith('/pin-setup') ||
          location.startsWith('/reset-pin') ||
          location.startsWith('/register')) {
        return;
      }

      AppRouter.router.go('/pin-login');
    } catch (e) {
      debugPrint('App lock check note: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ScreenUtil setup for responsive typography and spacing
    return ScreenUtilInit(
      designSize: const Size(390, 844), // Base mobile design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            // Add your state management providers here later (e.g., AuthProvider, ProductProvider)
            Provider(create: (_) => ()),
          ],
          child: MaterialApp.router(
            title: 'CartKaro Partner Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          ),
        );
      },
    );
  }
}
