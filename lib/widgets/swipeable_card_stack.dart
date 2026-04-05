import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Tinder-style swipeable card stack for user discovery.
///
/// Displays users as stacked cards that can be swiped:
/// - Right: Like
/// - Left: Pass
/// - Tap: View profile
class SwipeableCardStack extends StatefulWidget {
  final List<UserModel> users;
  final Function(UserModel) onLike;
  final Function(UserModel) onPass;
  final Function(UserModel) onTap;

  const SwipeableCardStack({
    super.key,
    required this.users,
    required this.onLike,
    required this.onPass,
    required this.onTap,
  });

  @override
  State<SwipeableCardStack> createState() => _SwipeableCardStackState();
}

class _SwipeableCardStackState extends State<SwipeableCardStack>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  late AnimationController _snapBackController;
  late Animation<Offset> _snapBackAnimation;
  late Animation<double> _snapBackAngleAnimation;
  bool _isDragging = false;

  static const double _swipeThreshold = 120.0;
  static const double _rotationFactor = 0.0008;

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _snapBackAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOutBack,
    ));
    _snapBackAngleAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.easeOutBack,
    ));
    _snapBackController.addListener(() {
      setState(() {
        _dragOffset = _snapBackAnimation.value;
        _dragAngle = _snapBackAngleAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(SwipeableCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.users.length != oldWidget.users.length) {
      _currentIndex = 0;
      _dragOffset = Offset.zero;
      _dragAngle = 0;
    }
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _isDragging = true;
    _snapBackController.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx * _rotationFactor;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
    final dx = _dragOffset.dx;

    if (dx.abs() > _swipeThreshold && _currentIndex < widget.users.length) {
      // Swipe completed
      final user = widget.users[_currentIndex];
      if (dx > 0) {
        widget.onLike(user);
      } else {
        widget.onPass(user);
      }
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
        _dragAngle = 0;
      });
    } else {
      // Snap back
      _snapBackAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _snapBackController,
        curve: Curves.easeOutBack,
      ));
      _snapBackAngleAnimation = Tween<double>(
        begin: _dragAngle,
        end: 0,
      ).animate(CurvedAnimation(
        parent: _snapBackController,
        curve: Curves.easeOutBack,
      ));
      _snapBackController.forward(from: 0);
    }
  }

  void _onLikePressed() {
    if (_currentIndex >= widget.users.length) return;
    widget.onLike(widget.users[_currentIndex]);
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
      _dragAngle = 0;
    });
  }

  void _onPassPressed() {
    if (_currentIndex >= widget.users.length) return;
    widget.onPass(widget.users[_currentIndex]);
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
      _dragAngle = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.users.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No more profiles nearby',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later or expand your search radius',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background card (next card peek)
              if (_currentIndex + 1 < widget.users.length)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Transform.scale(
                      scale: 0.95,
                      child: _buildCard(widget.users[_currentIndex + 1], isBackground: true),
                    ),
                  ),
                ),

              // Active card
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    onTap: () => widget.onTap(widget.users[_currentIndex]),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(_dragOffset.dx, _dragOffset.dy)
                        ..rotateZ(_dragAngle),
                      child: Stack(
                        children: [
                          _buildCard(widget.users[_currentIndex]),

                          // Like indicator
                          if (_dragOffset.dx > 30)
                            Positioned(
                              top: 40,
                              left: 30,
                              child: Transform.rotate(
                                angle: -0.3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green, width: 3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'LIKE',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Pass indicator
                          if (_dragOffset.dx < -30)
                            Positioned(
                              top: 40,
                              right: 30,
                              child: Transform.rotate(
                                angle: 0.3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'NOPE',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.close,
                color: AppTheme.coral,
                size: 56,
                onTap: _onPassPressed,
              ),
              _buildActionButton(
                icon: Icons.favorite,
                color: AppTheme.primaryRose,
                size: 64,
                onTap: _onLikePressed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCard(UserModel user, {bool isBackground = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: isBackground
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: user.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => _buildAvatarFallback(user),
              )
            else
              _buildAvatarFallback(user),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // User info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user.name}, ${user.age}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (user.city != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.city!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (user.interests.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: user.interests.take(4).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(UserModel user) {
    return Container(
      color: AppTheme.primaryRose.withValues(alpha: 0.3),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
