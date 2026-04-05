import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../utils/fix_user_profile.dart';
import '../utils/app_logger.dart';
import '../widgets/vibenou_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();

    if (authService.currentUser != null) {
      try {
        await fixCurrentUserProfile();
      } catch (e) {
        AppLogger.info('Note: Profile fix attempted: $e');
      }

      final userData = await authService.getUserData(authService.currentUser!.uid);
      if (userData != null) {
        themeProvider.updateTheme(userData);

        if (userData.preferredLanguage.isNotEmpty) {
          await languageProvider.setLocale(userData.preferredLanguage);
        }
      }
      if (mounted) {
        context.go('/main');
      }
    } else {
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

      if (mounted) {
        if (onboardingComplete) {
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      }
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  VibeNouLogo(
                    size: 160,
                    animate: true,
                    showWordmark: true,
                  ),
                  SizedBox(height: 50),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
