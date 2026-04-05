import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verify_email_screen.dart';
import '../screens/auth/two_factor_verify_screen.dart';
import '../screens/home/main_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/settings/settings_screen.dart';

/// App router configuration with auth-guarded routes and animated transitions.
GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: _guardRoute,
    routes: [
      // Splash / root
      GoRoute(
        path: '/',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SplashScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SignupScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const VerifyEmailScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
      GoRoute(
        path: '/two-factor',
        name: 'two-factor',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const TwoFactorVerifyScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // Main app (authenticated)
      GoRoute(
        path: '/main',
        name: 'main',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const MainScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const SettingsScreen(),
          transitionsBuilder: _slideRightTransition,
        ),
      ),
    ],
  );
}

/// Route guard: redirect unauthenticated users to login.
String? _guardRoute(BuildContext context, GoRouterState state) {
  final user = FirebaseAuth.instance.currentUser;
  final isAuthenticated = user != null;
  final isAuthRoute = state.matchedLocation == '/login' ||
      state.matchedLocation == '/signup' ||
      state.matchedLocation == '/verify-email' ||
      state.matchedLocation == '/two-factor';
  final isSplash = state.matchedLocation == '/';

  // Let splash handle its own routing
  if (isSplash) return null;

  // Redirect authenticated users away from auth pages
  if (isAuthenticated && isAuthRoute) return '/main';

  // Redirect unauthenticated users to login (except auth routes)
  if (!isAuthenticated && !isAuthRoute) return '/login';

  return null;
}

// --- Transition Builders ---

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideRightTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    )),
    child: child,
  );
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOut,
    )),
    child: child,
  );
}
