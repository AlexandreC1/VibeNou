import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';
import 'discover_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final ChatService _chatService = ChatService();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DiscoverScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: userId != null ? _chatService.getTotalUnreadCount(userId) : Stream.value(0),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.explore_outlined),
                activeIcon: const Icon(Icons.explore),
                label: localizations.discover,
              ),
              BottomNavigationBarItem(
                icon: _buildChatIcon(unreadCount, false),
                activeIcon: _buildChatIcon(unreadCount, true),
                label: localizations.chat,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: localizations.profile,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChatIcon(int unreadCount, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(isActive ? Icons.chat_bubble : Icons.chat_bubble_outline),
        if (unreadCount > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.coral,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
