import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'vibenou_logo.dart';

/// Reusable branded empty state widget.
///
/// Displays a watermark logo, icon, message, and optional CTA button
/// for screens with no content to show.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  /// No nearby users
  factory EmptyState.noNearbyUsers({VoidCallback? onExpandRadius}) {
    return EmptyState(
      icon: Icons.explore_outlined,
      title: 'No one nearby yet',
      message: 'Try expanding your search radius to discover more people.',
      actionLabel: 'Expand Radius',
      onAction: onExpandRadius,
    );
  }

  /// No messages
  factory EmptyState.noMessages({VoidCallback? onDiscover}) {
    return EmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'No conversations yet',
      message: 'Start discovering people and make a connection!',
      actionLabel: 'Start Discovering',
      onAction: onDiscover,
    );
  }

  /// No favorites
  factory EmptyState.noFavorites({VoidCallback? onBrowse}) {
    return EmptyState(
      icon: Icons.favorite_border,
      title: 'No favorites yet',
      message: 'Like profiles to add them to your favorites.',
      actionLabel: 'Browse Profiles',
      onAction: onBrowse,
    );
  }

  /// No matches
  factory EmptyState.noMatches({VoidCallback? onDiscover}) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No matches yet',
      message: 'Keep swiping to find your perfect match!',
      actionLabel: 'Keep Discovering',
      onAction: onDiscover,
    );
  }

  /// No profile views
  factory EmptyState.noProfileViews() {
    return const EmptyState(
      icon: Icons.visibility_outlined,
      title: 'No views yet',
      message: 'Complete your profile to attract more visitors.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Watermark logo
            Opacity(
              opacity: 0.08,
              child: VibeNouLogoCompact(size: 100),
            ),
            const SizedBox(height: 24),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                size: 36,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),

            // CTA Button
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
