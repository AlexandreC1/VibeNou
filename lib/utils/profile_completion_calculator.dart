import '../models/user_model.dart';

/// Profile Completion Calculator
///
/// Calculates profile completion percentage to drive user engagement.
///
/// Psychology (Zeigarnik Effect):
/// People feel compelled to complete unfinished tasks. Showing "87% complete"
/// creates an irresistible urge to reach 100%.
///
/// Impact:
/// - 3x higher match rates for complete profiles
/// - Users with 100% profiles get 5x more views
/// - Incomplete profiles reduce trust and engagement
class ProfileCompletionCalculator {
  /// Calculate profile completion percentage (0-100)
  static int calculateCompletion(UserModel user) {
    int totalPoints = 0;
    int earnedPoints = 0;

    // Photo (25 points) - Most important for dating!
    totalPoints += 25;
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      earnedPoints += 25;
    }

    // Name (10 points) - Required
    totalPoints += 10;
    if (user.name.isNotEmpty) {
      earnedPoints += 10;
    }

    // Age (10 points) - Required
    totalPoints += 10;
    if (user.age >= 18 && user.age <= 100) {
      earnedPoints += 10;
    }

    // Bio (15 points) - Very important for matches
    totalPoints += 15;
    if (user.bio.isNotEmpty && user.bio.length >= 50) {
      earnedPoints += 15;
    } else if (user.bio.isNotEmpty) {
      earnedPoints += 7; // Partial credit for short bio
    }

    // Interests (15 points) - Used for matching algorithm
    totalPoints += 15;
    if (user.interests.length >= 5) {
      earnedPoints += 15;
    } else if (user.interests.isNotEmpty) {
      earnedPoints += (user.interests.length * 3); // 3 points per interest
    }

    // Additional photos (10 points) - Shows effort
    totalPoints += 10;
    if (user.photos.length >= 3) {
      earnedPoints += 10;
    } else if (user.photos.isNotEmpty) {
      earnedPoints += (user.photos.length * 3); // 3 points per photo
    }

    // Location (10 points) - Enables nearby matches
    totalPoints += 10;
    if (user.location != null) {
      earnedPoints += 10;
    }

    // Gender & preferences (5 points) - Better matching
    totalPoints += 5;
    if (user.gender != null && user.preferredGender != null) {
      earnedPoints += 5;
    }

    return ((earnedPoints / totalPoints) * 100).round();
  }

  /// Get missing items that would improve profile
  static List<ProfileCompletionItem> getMissingItems(UserModel user) {
    final List<ProfileCompletionItem> missing = [];

    if (user.photoUrl == null || user.photoUrl!.isEmpty) {
      missing.add(ProfileCompletionItem(
        title: 'Add profile photo',
        description: 'Profiles with photos get 10x more matches',
        points: 25,
        priority: 1,
      ));
    }

    if (user.bio.isEmpty) {
      missing.add(ProfileCompletionItem(
        title: 'Write a bio',
        description: 'Tell others about yourself (50+ characters)',
        points: 15,
        priority: 2,
      ));
    } else if (user.bio.length < 50) {
      missing.add(ProfileCompletionItem(
        title: 'Expand your bio',
        description: 'Add more details (${50 - user.bio.length} characters needed)',
        points: 8,
        priority: 3,
      ));
    }

    if (user.interests.length < 5) {
      missing.add(ProfileCompletionItem(
        title: 'Add more interests',
        description: 'Select ${5 - user.interests.length} more interests to improve matches',
        points: 15 - (user.interests.length * 3),
        priority: 2,
      ));
    }

    if (user.photos.length < 3) {
      missing.add(ProfileCompletionItem(
        title: 'Add more photos',
        description: 'Upload ${3 - user.photos.length} more photos',
        points: 10 - (user.photos.length * 3),
        priority: 3,
      ));
    }

    if (user.location == null) {
      missing.add(ProfileCompletionItem(
        title: 'Enable location',
        description: 'Find matches near you',
        points: 10,
        priority: 4,
      ));
    }

    if (user.gender == null || user.preferredGender == null) {
      missing.add(ProfileCompletionItem(
        title: 'Set preferences',
        description: 'Help us find better matches',
        points: 5,
        priority: 5,
      ));
    }

    // Sort by priority
    missing.sort((a, b) => a.priority.compareTo(b.priority));

    return missing;
  }

  /// Get encouragement message based on completion percentage
  static String getEncouragementMessage(int percentage) {
    if (percentage >= 100) {
      return '🎉 Perfect profile! You\'re getting maximum visibility!';
    } else if (percentage >= 90) {
      return '🔥 Almost there! Just a few more touches...';
    } else if (percentage >= 75) {
      return '⭐ Great progress! Keep going...';
    } else if (percentage >= 50) {
      return '💪 Halfway there! Complete profiles get 5x more matches.';
    } else if (percentage >= 25) {
      return '🚀 Good start! Add more details to stand out.';
    } else {
      return '👋 Welcome! Let\'s create your amazing profile!';
    }
  }
}

/// Represents a missing profile item
class ProfileCompletionItem {
  final String title;
  final String description;
  final int points;
  final int priority; // Lower = more important

  ProfileCompletionItem({
    required this.title,
    required this.description,
    required this.points,
    required this.priority,
  });
}
