import 'package:flutter/material.dart';

/// OnboardingPage Model
///
/// Represents a single page in the onboarding flow
///
/// Last updated: 2026-03-24
class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon; // Professional Material icon
  final List<String> features; // Bullet points for this page

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    this.features = const [],
  });
}

/// Pre-defined onboarding pages for VibeNou
class OnboardingPages {
  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'Welcome to VibeNou',
      description: 'Connect with the Haitian community through meaningful relationships',
      icon: Icons.favorite_rounded,
      features: [
        'Location-based matching',
        'Secure and private',
        'Real-time chat',
      ],
    ),
    OnboardingPageModel(
      title: 'Discover Your Match',
      description: 'Find people nearby who share your interests and values',
      icon: Icons.search_rounded,
      features: [
        'Smart matching algorithm',
        'Interest-based filtering',
        'View who checked your profile',
      ],
    ),
    OnboardingPageModel(
      title: 'Chat & Connect',
      description: 'Start conversations with end-to-end encrypted messaging',
      icon: Icons.chat_bubble_rounded,
      features: [
        'Secure encrypted chat',
        'Share photos safely',
        'Real-time notifications',
      ],
    ),
    OnboardingPageModel(
      title: 'Stay Safe',
      description: 'Your privacy and security are our top priorities',
      icon: Icons.shield_rounded,
      features: [
        '2-Factor authentication',
        'Photo verification',
        'Report & block users',
      ],
    ),
    OnboardingPageModel(
      title: 'Ready to Start?',
      description: 'Create your profile and find your connection today',
      icon: Icons.celebration_rounded,
      features: [
        'Takes less than 2 minutes',
        'Add photos & interests',
        'Start matching instantly',
      ],
    ),
  ];
}
