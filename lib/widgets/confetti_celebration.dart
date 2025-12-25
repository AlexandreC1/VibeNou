import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import '../utils/app_theme.dart';

/// Confetti Celebration Widget
///
/// Creates a delightful confetti animation for special moments.
/// Psychology: Creates memorable "dopamine hits" that make the app feel magical.
///
/// Use for:
/// - New matches (most important!)
/// - Achievement unlocks
/// - Daily reward streaks
/// - Profile completion milestones
class ConfettiCelebration extends StatefulWidget {
  final Widget child;
  final bool showConfetti;
  final VoidCallback? onComplete;

  const ConfettiCelebration({
    super.key,
    required this.child,
    this.showConfetti = false,
    this.onComplete,
  });

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration> {
  late ConfettiController _controllerCenter;
  late ConfettiController _controllerLeft;
  late ConfettiController _controllerRight;

  @override
  void initState() {
    super.initState();

    _controllerCenter = ConfettiController(duration: const Duration(seconds: 2));
    _controllerLeft = ConfettiController(duration: const Duration(seconds: 2));
    _controllerRight = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(ConfettiCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showConfetti && !oldWidget.showConfetti) {
      _playConfetti();
    }
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    _controllerLeft.dispose();
    _controllerRight.dispose();
    super.dispose();
  }

  void _playConfetti() {
    // Play all three confetti streams with slight delays for dramatic effect
    _controllerCenter.play();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _controllerLeft.play();
      }
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _controllerRight.play();
      }
    });

    // Notify completion
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  Path _createStarPath(Size size) {
    // Create a star shape for confetti
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w * 0.6, h * 0.35);
    path.lineTo(w, h * 0.35);
    path.lineTo(w * 0.7, h * 0.6);
    path.lineTo(w * 0.8, h);
    path.lineTo(w * 0.5, h * 0.75);
    path.lineTo(w * 0.2, h);
    path.lineTo(w * 0.3, h * 0.6);
    path.lineTo(0, h * 0.35);
    path.lineTo(w * 0.4, h * 0.35);
    path.close();

    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Center confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controllerCenter,
            blastDirection: pi / 2, // Down
            emissionFrequency: 0.03,
            numberOfParticles: 20,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [
              AppTheme.primaryRose,
              AppTheme.royalPurple,
              AppTheme.coral,
              Color(0xFFFFD700), // Gold
              Color(0xFF00D4FF), // Cyan
              Color(0xFFFF1493), // Deep pink
            ],
            createParticlePath: _createStarPath,
          ),
        ),
        // Left confetti
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: _controllerLeft,
            blastDirection: pi / 2 + pi / 6, // Slight angle right
            emissionFrequency: 0.05,
            numberOfParticles: 15,
            gravity: 0.25,
            shouldLoop: false,
            colors: const [
              AppTheme.primaryRose,
              AppTheme.royalPurple,
              AppTheme.coral,
            ],
          ),
        ),
        // Right confetti
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: _controllerRight,
            blastDirection: pi / 2 - pi / 6, // Slight angle left
            emissionFrequency: 0.05,
            numberOfParticles: 15,
            gravity: 0.25,
            shouldLoop: false,
            colors: const [
              AppTheme.primaryRose,
              AppTheme.royalPurple,
              AppTheme.coral,
            ],
          ),
        ),
      ],
    );
  }
}

/// Match Celebration Dialog
///
/// Shows a beautiful dialog with confetti when users match.
/// This is the MOST IMPORTANT moment in a dating app - make it magical!
class MatchCelebrationDialog extends StatelessWidget {
  final String matchedUserName;
  final String? matchedUserPhotoUrl;
  final VoidCallback onSendMessage;
  final VoidCallback onKeepSwiping;

  const MatchCelebrationDialog({
    super.key,
    required this.matchedUserName,
    this.matchedUserPhotoUrl,
    required this.onSendMessage,
    required this.onKeepSwiping,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConfettiCelebration(
        showConfetti: true,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryRose.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated heart icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // "It's a Match!" text
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
                child: const Text(
                  "It's a Match!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Matched user info
              Text(
                'You and $matchedUserName liked each other',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onKeepSwiping,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: AppTheme.primaryRose,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Keep Swiping',
                        style: TextStyle(
                          color: AppTheme.primaryRose,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSendMessage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryRose,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: AppTheme.primaryRose.withValues(alpha: 0.5),
                      ),
                      child: const Text(
                        'Send Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick confetti celebration helper
/// Use this to trigger confetti from anywhere in the app
class ConfettiHelper {
  static void celebrate(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SimpleConfettiDialog(),
    );

    // Auto-dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

/// Simple confetti dialog for achievements
class SimpleConfettiDialog extends StatelessWidget {
  const SimpleConfettiDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConfettiCelebration(
        showConfetti: true,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: const Icon(
            Icons.celebration,
            size: 64,
            color: AppTheme.primaryRose,
          ),
        ),
      ),
    );
  }
}
