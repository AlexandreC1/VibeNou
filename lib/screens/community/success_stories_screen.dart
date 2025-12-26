import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/success_story_model.dart';
import '../../utils/app_theme.dart';

class SuccessStoriesScreen extends StatefulWidget {
  const SuccessStoriesScreen({super.key});

  @override
  State<SuccessStoriesScreen> createState() => _SuccessStoriesScreenState();
}

class _SuccessStoriesScreenState extends State<SuccessStoriesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Success Stories'),
        backgroundColor: AppTheme.coral,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showSubmitStoryDialog(context);
            },
            tooltip: 'Share your story',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('successStories')
            .where('isVerified', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final stories = snapshot.data?.docs.map((doc) {
                return SuccessStory.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              }).toList() ??
              [];

          if (stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No success stories yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share your love story!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showSubmitStoryDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Share Your Story'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.coral,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stories.length,
            itemBuilder: (context, index) {
              final story = stories[index];
              return _buildStoryCard(story);
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCard(SuccessStory story) {
    final timeAgo = _getTimeAgo(story.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Couple photos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCoupleAvatar(story.user1Photo, story.user1Name),
                const SizedBox(width: 16),
                const Icon(Icons.favorite, color: AppTheme.coral, size: 32),
                const SizedBox(width: 16),
                _buildCoupleAvatar(story.user2Photo, story.user2Name),
              ],
            ),
            const SizedBox(height: 16),
            // Names
            Text(
              '${story.user1Name} & ${story.user2Name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Met date
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Met ${_formatDate(story.metDate)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Story
            Text(
              story.story,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border,
                        size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${story.likes}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoupleAvatar(String photoUrl, String name) {
    return CircleAvatar(
      radius: 40,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 24),
            )
          : null,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? "month" : "months"} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? "year" : "years"} ago';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _showSubmitStoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Your Success Story'),
        content: const Text(
          'Feature coming soon! Contact support to share your love story and inspire others in the VibeNou community.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
