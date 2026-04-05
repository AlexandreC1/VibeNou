import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_cache_service.dart';
import '../../services/online_presence_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/haptic_feedback_util.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../chat/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final UserCacheService _userCache = UserCacheService();
  final OnlinePresenceService _presenceService = OnlinePresenceService();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.chat)),
        body: const Center(child: Text('Please log in to view chats')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.chat,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getChatRooms(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonChatList();
          }

          if (snapshot.hasError) {
            return ErrorState.loadFailed(
              onRetry: () => setState(() {}),
            );
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return EmptyState.noMessages();
          }

          final otherUserIds = chatRooms
              .map((room) => room.participants.firstWhere(
                    (id) => id != authService.currentUser!.uid,
                  ))
              .toList();

          final allUserIds = [authService.currentUser!.uid, ...otherUserIds];

          return FutureBuilder<Map<String, UserModel>>(
            future: _userCache.batchGetUsers(allUserIds),
            builder: (context, userMapSnapshot) {
              if (userMapSnapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonChatList();
              }

              if (userMapSnapshot.hasError) {
                return ErrorState.loadFailed(
                  onRetry: () => setState(() {}),
                );
              }

              final userMap = userMapSnapshot.data ?? {};
              final currentUser = userMap[authService.currentUser!.uid];

              if (currentUser == null) {
                return const ErrorState(
                  title: 'Profile not found',
                  message: 'Please try logging in again.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedbackUtil.mediumImpact();
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: chatRooms.length,
                  itemBuilder: (context, index) {
                    final chatRoom = chatRooms[index];
                    final otherUserId = chatRoom.participants.firstWhere(
                      (id) => id != authService.currentUser!.uid,
                    );

                    final otherUser = userMap[otherUserId];

                    if (otherUser == null) {
                      return const SizedBox.shrink();
                    }

                    final unreadCount =
                        chatRoom.unreadCount[authService.currentUser!.uid] ?? 0;

                    return TweenAnimationBuilder<double>(
                      key: ValueKey(chatRoom.id),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 60)),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: child,
                          ),
                        );
                      },
                      child: _ModernChatTile(
                        chatRoom: chatRoom,
                        otherUser: otherUser,
                        unreadCount: unreadCount,
                        onTap: () {
                          if (mounted) {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    ChatScreen(
                                  otherUser: otherUser,
                                  currentUser: currentUser,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeInOut,
                                    )),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Modern chat list tile with online indicator, avatar, and unread badge.
class _ModernChatTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final UserModel otherUser;
  final int unreadCount;
  final VoidCallback onTap;

  const _ModernChatTile({
    required this.chatRoom,
    required this.otherUser,
    required this.unreadCount,
    required this.onTap,
  });

  bool get _isRecentlyActive {
    final threshold = DateTime.now().subtract(const Duration(minutes: 5));
    return otherUser.lastActive.isAfter(threshold);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: hasUnread
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: CircleAvatar(
                    radius: hasUnread ? 25 : 28,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    backgroundImage: otherUser.photoUrl != null
                        ? CachedNetworkImageProvider(otherUser.photoUrl!)
                        : null,
                    child: otherUser.photoUrl == null
                        ? Text(
                            otherUser.name.isNotEmpty
                                ? otherUser.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                ),
                // Online dot
                if (_isRecentlyActive)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Name + message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.name,
                    style: TextStyle(
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    chatRoom.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      color: hasUnread ? Colors.grey[800] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Time + unread badge
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeago.format(chatRoom.lastMessageTime, locale: 'en_short'),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasUnread
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[400],
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (hasUnread) ...[
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
