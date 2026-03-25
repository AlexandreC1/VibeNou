/// OnboardingScreen - First-time user introduction flow
///
/// Features:
/// - 5 beautiful onboarding pages
/// - Smooth page transitions with animations
/// - Gender-adaptive theming
/// - Skip button for quick access
/// - Page indicators (dots)
/// - Get Started button on final page
///
/// Last updated: 2026-03-24
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../models/onboarding_page_model.dart';
import '../../utils/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<double> _iconAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Icon animation (scale and bounce)
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _iconAnimation = CurvedAnimation(
      parent: _iconAnimationController,
      curve: Curves.elasticOut,
    );

    // Fade animation for content
    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeIn,
    );

    // Start animations
    _iconAnimationController.forward();
    _fadeAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconAnimationController.dispose();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });

    // Restart animations for new page
    _iconAnimationController.reset();
    _fadeAnimationController.reset();
    _iconAnimationController.forward();
    _fadeAnimationController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < OnboardingPages.pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get gender from theme provider if available
    final gender = themeProvider.currentGender;
    final primaryColor = gender == 'male'
        ? (isDark ? AppTheme.darkPrimaryBlue : AppTheme.primaryBlue)
        : (isDark ? AppTheme.darkPrimaryRose : AppTheme.primaryRose);
    final secondaryColor = gender == 'male'
        ? (isDark ? AppTheme.darkTeal : AppTheme.teal)
        : (isDark ? AppTheme.darkRoyalPurple : AppTheme.royalPurple);

    final gradient = AppTheme.getGradient(
      isDarkMode: isDark,
      gender: gender,
      gradientType: 'primary',
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Spacer for centering
                  // Page indicators
                  Row(
                    children: List.generate(
                      OnboardingPages.pages.length,
                      (index) => _buildPageIndicator(index, primaryColor),
                    ),
                  ),
                  // Skip button
                  if (_currentPage < OnboardingPages.pages.length - 1)
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),
                ],
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: OnboardingPages.pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(
                    OnboardingPages.pages[index],
                    primaryColor,
                    secondaryColor,
                    gradient,
                    isDark,
                  );
                },
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == OnboardingPages.pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _currentPage == OnboardingPages.pages.length - 1
                            ? Icons.check_circle
                            : Icons.arrow_forward,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index, Color primaryColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? primaryColor
            : primaryColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(
    OnboardingPageModel page,
    Color primaryColor,
    Color secondaryColor,
    LinearGradient gradient,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Icon
          ScaleTransition(
            scale: _iconAnimation,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  page.icon,
                  size: 72,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Features List
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: page.features
                  .map((feature) => _buildFeatureItem(
                        feature,
                        primaryColor,
                        isDark,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, Color primaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
