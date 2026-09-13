import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';

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

class CartKaroPartnerApp extends StatelessWidget {
  const CartKaroPartnerApp({super.key});

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
