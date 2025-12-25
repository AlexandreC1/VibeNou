import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import '../utils/profile_completion_calculator.dart';
import '../utils/haptic_feedback_util.dart';

/// Profile Completion Widget
///
/// Shows profile completion percentage with visual progress indicator.
/// Creates urgency and motivation to complete profile (Zeigarnik Effect).
///
/// Display locations:
/// - Profile screen (main banner)
/// - Edit profile screen (progress tracker)
/// - Home screen (reminder if < 75%)
class ProfileCompletionWidget extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTapEdit;
  final bool showDetails;

  const ProfileCompletionWidget({
    super.key,
    required this.user,
    this.onTapEdit,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final completion = ProfileCompletionCalculator.calculateCompletion(user);
    final message = ProfileCompletionCalculator.getEncouragementMessage(completion);

    // Don't show if profile is 100% complete (optional - can keep for bragging rights)
    if (completion >= 100 && !showDetails) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        if (onTapEdit != null) {
          HapticFeedbackUtil.mediumImpact();
          onTapEdit!();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: completion >= 100
              ? AppTheme.successGradient
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRose.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Strength',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Percentage circle
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$completion%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completion / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
            ),
            if (showDetails && completion < 100) ...[
              const SizedBox(height: 16),
              // Missing items
              ...ProfileCompletionCalculator.getMissingItems(user)
                  .take(3) // Show top 3 items
                  .map((item) => _MissingItemRow(item: item)),
            ],
            if (onTapEdit != null && completion < 100) ...[
              const SizedBox(height: 12),
              // Complete profile button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedbackUtil.mediumImpact();
                    onTapEdit!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryRose,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Complete Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
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

/// Compact version for smaller spaces
class CompactProfileCompletion extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const CompactProfileCompletion({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completion = ProfileCompletionCalculator.calculateCompletion(user);

    // Don't show if 100% complete
    if (completion >= 100) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedbackUtil.lightImpact();
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.softPink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryRose.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              completion >= 75 ? Icons.star_half : Icons.star_outline,
              color: AppTheme.primaryRose,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '$completion% complete',
              style: const TextStyle(
                color: AppTheme.primaryRose,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryRose,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}

/// Missing item row widget
class _MissingItemRow extends StatelessWidget {
  final ProfileCompletionItem item;

  const _MissingItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${item.points}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
