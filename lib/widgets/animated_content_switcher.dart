import 'package:flutter/material.dart';

/// Smoothly cross-fades + slides between loading, empty, error and content states.
///
/// Usage:
/// ```dart
/// AnimatedContentSwitcher(
///   state: isLoading ? ContentState.loading : ContentState.content,
///   loading: SkeletonList(),
///   content: MyList(),
/// )
/// ```
enum ContentState { loading, empty, error, content }

class AnimatedContentSwitcher extends StatelessWidget {
  final ContentState state;
  final Widget loading;
  final Widget content;
  final Widget? empty;
  final Widget? error;
  final Duration duration;

  const AnimatedContentSwitcher({
    super.key,
    required this.state,
    required this.loading,
    required this.content,
    this.empty,
    this.error,
    this.duration = const Duration(milliseconds: 320),
  });

  Widget _childForState() {
    switch (state) {
      case ContentState.loading:
        return KeyedSubtree(key: const ValueKey('loading'), child: loading);
      case ContentState.empty:
        return KeyedSubtree(
          key: const ValueKey('empty'),
          child: empty ?? const SizedBox.shrink(),
        );
      case ContentState.error:
        return KeyedSubtree(
          key: const ValueKey('error'),
          child: error ?? const SizedBox.shrink(),
        );
      case ContentState.content:
        return KeyedSubtree(key: const ValueKey('content'), child: content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: _childForState(),
    );
  }
}
