import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../l10n/app_localizations.dart';
import '../../models/chat_message.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import '../chat/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();

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
        title: Text(localizations.chat),
      ),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getChatRooms(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final chatRooms = snapshot.data ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation by discovering new people',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final otherUserId = chatRoom.participants.firstWhere(
                (id) => id != authService.currentUser!.uid,
              );

              return FutureBuilder<UserModel?>(
                future: authService.getUserData(otherUserId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final otherUser = userSnapshot.data!;
                  final unreadCount =
                      chatRoom.unreadCount[authService.currentUser!.uid] ?? 0;

                  // Animate each chat tile with staggered delay
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(chatRoom.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 80)),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(-30 * (1 - value), 0),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: _ChatListTile(
                      chatRoom: chatRoom,
                      otherUser: otherUser,
                      unreadCount: unreadCount,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final currentUser = await authService
                            .getUserData(authService.currentUser!.uid);
                        if (currentUser != null && mounted) {
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                otherUser: otherUser,
                                currentUser: currentUser,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final UserModel otherUser;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatListTile({
    required this.chatRoom,
    required this.otherUser,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryBlue,
        child: Text(
          otherUser.name[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        otherUser.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        chatRoom.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
          color: unreadCount > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timeago.format(chatRoom.lastMessageTime),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.coral,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unreadCount.toString(),
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
      onTap: onTap,
    );
  }
}
