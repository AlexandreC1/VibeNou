import 'package:share_plus/share_plus.dart';
import '../models/user_model.dart';

class ShareHelper {
  // Share a user profile
  static Future<void> shareProfile(UserModel user) async {
    try {
      final String text = '''
Check out ${user.name}'s profile on VibeNou!

${user.name}, ${user.age}
${user.city ?? 'Location not shared'}

${user.bio.isNotEmpty ? '"${user.bio}"' : ''}

${user.interests.isNotEmpty ? 'Interests: ${user.interests.take(3).join(", ")}' : ''}

Download VibeNou to connect!
''';

      await Share.share(
        text,
        subject: 'Check out ${user.name} on VibeNou',
      );
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  // Share the app
  static Future<void> shareApp() async {
    try {
      const String text = '''
Join me on VibeNou - The Haitian Community Dating App! 🇭🇹

Find meaningful connections with people nearby who share your interests and values.

Download now and start your journey!
''';

      await Share.share(
        text,
        subject: 'Join VibeNou',
      );
    } catch (e) {
      // Handle error silently
    }
  }

  // Share success story
  static Future<void> shareSuccessStory({
    required String user1Name,
    required String user2Name,
    required String story,
  }) async {
    try {
      final String text = '''
Love Story on VibeNou 💕

$user1Name & $user2Name found love through VibeNou!

"$story"

Find your match on VibeNou!
''';

      await Share.share(
        text,
        subject: 'Love Story from VibeNou',
      );
    } catch (e) {
      // Handle error silently
    }
  }
}
