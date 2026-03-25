/// Skeleton Loader Widgets - Beautiful loading placeholders
///
/// Provides shimmer-animated skeleton loaders for various UI components
/// to create a smooth loading experience instead of spinners.
///
/// Features:
/// - Shimmer animation effect
/// - Theme-aware (light/dark mode)
/// - Pre-built components for common use cases
/// - Customizable shapes and sizes
///
/// Last updated: 2026-03-24
library;

import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Base Skeleton Widget with shimmer animation
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkSurface : Colors.grey[300]!;
    final highlightColor = isDark ? AppTheme.darkSurfaceElevated : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton Circle (for avatars)
class SkeletonCircle extends StatelessWidget {
  final double size;
  final EdgeInsets? margin;

  const SkeletonCircle({
    super.key,
    this.size = 50,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2),
      margin: margin,
    );
  }
}

/// Skeleton Line (for text)
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final EdgeInsets? margin;

  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(height / 2),
      margin: margin,
    );
  }
}

/// Skeleton Card - Profile card placeholder
class SkeletonProfileCard extends StatelessWidget {
  const SkeletonProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile image
            const Skeleton(
              height: 350,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            // Name
            const SkeletonLine(width: 150, height: 20),
            const SizedBox(height: 8),
            // Age and location
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonLine(width: 40, height: 14),
                SizedBox(width: 8),
                SkeletonLine(width: 100, height: 14),
              ],
            ),
            const SizedBox(height: 12),
            // Bio
            const SkeletonLine(width: double.infinity, height: 12),
            const SizedBox(height: 4),
            const SkeletonLine(width: double.infinity, height: 12),
            const SizedBox(height: 4),
            const SkeletonLine(width: 200, height: 12),
            const SizedBox(height: 16),
            // Interest chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(
                5,
                (index) => const Skeleton(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton List Item - Chat/Match list item placeholder
class SkeletonListItem extends StatelessWidget {
  final bool showTrailing;

  const SkeletonListItem({
    super.key,
    this.showTrailing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          const SkeletonCircle(size: 60),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLine(width: 120, height: 16),
                SizedBox(height: 8),
                SkeletonLine(width: double.infinity, height: 12),
              ],
            ),
          ),
          // Trailing
          if (showTrailing) ...[
            const SizedBox(width: 8),
            const SkeletonLine(width: 40, height: 12),
          ],
        ],
      ),
    );
  }
}

/// Skeleton Grid Item - Photo grid placeholder
class SkeletonGridItem extends StatelessWidget {
  final double aspectRatio;

  const SkeletonGridItem({
    super.key,
    this.aspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: const Skeleton(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}

/// Skeleton Discover Screen - Full loading state for discover screen
class SkeletonDiscoverScreen extends StatelessWidget {
  const SkeletonDiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 350,
        child: SkeletonProfileCard(),
      ),
    );
  }
}

/// Skeleton Chat List - Loading state for chat list
class SkeletonChatList extends StatelessWidget {
  final int itemCount;

  const SkeletonChatList({
    super.key,
    this.itemCount = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonListItem(),
    );
  }
}

/// Skeleton Match List - Loading state for matches
class SkeletonMatchList extends StatelessWidget {
  final int itemCount;

  const SkeletonMatchList({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonGridItem(aspectRatio: 0.75),
    );
  }
}

/// Skeleton Message - Chat message placeholder
class SkeletonMessage extends StatelessWidget {
  final bool isMe;

  const SkeletonMessage({
    super.key,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const SkeletonCircle(size: 32),
            const SizedBox(width: 8),
          ],
          SkeletonLine(
            width: isMe ? 180 : 220,
            height: 40,
            margin: EdgeInsets.only(
              left: isMe ? 48 : 0,
              right: isMe ? 0 : 48,
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Skeleton Profile View Item - Who viewed me placeholder
class SkeletonProfileViewItem extends StatelessWidget {
  const SkeletonProfileViewItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const SkeletonCircle(size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 100, height: 16),
                  SizedBox(height: 6),
                  SkeletonLine(width: 140, height: 12),
                  SizedBox(height: 6),
                  SkeletonLine(width: 80, height: 10),
                ],
              ),
            ),
            const Skeleton(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton Success Story - Success stories placeholder
class SkeletonSuccessStory extends StatelessWidget {
  const SkeletonSuccessStory({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Images
          const Skeleton(
            height: 200,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Names
                SkeletonLine(width: 180, height: 18),
                SizedBox(height: 8),
                // Date
                SkeletonLine(width: 100, height: 12),
                SizedBox(height: 12),
                // Story text
                SkeletonLine(width: double.infinity, height: 12),
                SizedBox(height: 4),
                SkeletonLine(width: double.infinity, height: 12),
                SizedBox(height: 4),
                SkeletonLine(width: 200, height: 12),
                SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    SkeletonLine(width: 60, height: 30),
                    SizedBox(width: 16),
                    SkeletonLine(width: 60, height: 30),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
