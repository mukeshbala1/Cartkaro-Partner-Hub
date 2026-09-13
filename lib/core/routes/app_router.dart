import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/pin_login_screen.dart';
import '../../features/auth/screens/business_type_screen.dart';

import '../../features/auth/screens/grocery_registration_screen.dart';
import '../../features/auth/screens/restaurant_registration_screen.dart';
import '../../features/auth/screens/medical_registration_screen.dart';

import '../../features/auth/screens/business_selector_screen.dart'; // NEW
import '../../features/dashboard/screens/dashboard_layout.dart';

import '../../features/auth/screens/reset_pin_screen.dart';
import '../../features/auth/screens/pin_setup_screen.dart';

// Routes that do NOT require authentication
const _publicRoutes = [
  '/',
  '/splash',
  '/login',
  '/pin-login',
  '/reset-pin',
  '/pin-setup',
];

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',

    // ── Auth Guard ────────────────────────────────────────────
    // If the user is not logged in and tries to access a protected
    // route (dashboard, registration, business-type), redirect to /login.
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isPublic = _publicRoutes.contains(location);

      if (isPublic) {
        return null; // allow public routes (including splash)
      }

      final loggedIn = FirebaseAuth.instance.currentUser != null;
      if (!loggedIn) {
        return '/login';
      }
      return null; // allow navigation
    },

    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/splash'),

      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Mobile OTP Login
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Existing Partner PIN Login
      GoRoute(
        path: '/pin-login',
        builder: (context, state) => const PinLoginScreen(),
      ),

      // Choose Grocery / Restaurant / Medical  [Auth required]
      GoRoute(
        path: '/business-type',
        builder: (context, state) => const BusinessTypeScreen(),
      ),

      // Grocery Registration  [Auth required]
      GoRoute(
        path: '/register/grocery',
        builder: (context, state) => const GroceryRegistrationScreen(),
      ),

      // Restaurant Registration  [Auth required]
      GoRoute(
        path: '/register/restaurant',
        builder: (context, state) => const RestaurantRegistrationScreen(),
      ),

      // Medical Registration  [Auth required]
      GoRoute(
        path: '/register/medical',
        builder: (context, state) => const MedicalRegistrationScreen(),
      ),

      // Business Selector [Auth required]
      GoRoute(
        path: '/business-selector',
        builder: (context, state) => const BusinessSelectorScreen(),
      ),

      // Default Dashboard  [Auth required]
      GoRoute(
        path: '/dashboard',
        builder: (context, state) {
          final businessId = state.extra as String?;
          return DashboardLayout(businessId: businessId);
        },
      ),

      // Reset PIN
      GoRoute(
        path: '/reset-pin',
        builder: (context, state) => const ResetPinScreen(),
      ),

      // Set PIN
      GoRoute(
        path: '/pin-setup',
        builder: (context, state) => const PinSetupScreen(),
      ),
    ],
  );
}
