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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final ChatService _chatService = ChatService();
  late final AnimationController _navAnimController;

  // Lazy tab loading: each slot is null until first visited, then kept alive.
  final List<Widget?> _lazyScreens = [null, null, null];

  @override
  void initState() {
    super.initState();
    // Eagerly build the first tab only.
    _lazyScreens[0] = const DiscoverScreen();

    _navAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
  }

  Widget _buildTab(int index) {
    if (_lazyScreens[index] != null) return _lazyScreens[index]!;
    return const SizedBox.shrink();
  }

  void _ensureTabBuilt(int index) {
    if (_lazyScreens[index] != null) return;
    switch (index) {
      case 0:
        _lazyScreens[0] = const DiscoverScreen();
        break;
      case 1:
        _lazyScreens[1] = const ChatListScreen();
        break;
      case 2:
        _lazyScreens[2] = const ProfileScreen();
        break;
    }
  }

  @override
  void dispose() {
    _navAnimController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _ensureTabBuilt(index);
      _currentIndex = index;
    });
    _navAnimController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildTab(0),
          _buildTab(1),
          _buildTab(2),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: userId != null ? _chatService.getTotalUnreadCount(userId) : Stream.value(0),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      index: 0,
                      currentIndex: _currentIndex,
                      icon: Icons.explore_outlined,
                      activeIcon: Icons.explore,
                      label: localizations.discover,
                      onTap: () => _onTabTapped(0),
                    ),
                    _NavItem(
                      index: 1,
                      currentIndex: _currentIndex,
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble,
                      label: localizations.chat,
                      badge: unreadCount,
                      onTap: () => _onTabTapped(1),
                    ),
                    _NavItem(
                      index: 2,
                      currentIndex: _currentIndex,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: localizations.profile,
                      onTap: () => _onTabTapped(2),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Individual navigation bar item with animated indicator and badge.
class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge = 0,
    required this.onTap,
  });

  bool get isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated indicator bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: isActive ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive
                        ? primaryColor
                        : Colors.grey[500],
                    size: 26,
                  ),
                ),

                // Badge
                if (badge > 0)
                  Positioned(
                    right: -10,
                    top: -4,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.coral,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            badge > 99 ? '99+' : badge.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? primaryColor : Colors.grey[500],
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
