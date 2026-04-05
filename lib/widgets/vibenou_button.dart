import 'package:flutter/material.dart';

/// Branded button with built-in loading and success states.
///
/// States: idle → loading (spinner) → success (checkmark) → idle
class VibeNouButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final IconData? icon;
  final bool isOutlined;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const VibeNouButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
    this.isOutlined = false,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<VibeNouButton> createState() => _VibeNouButtonState();
}

class _VibeNouButtonState extends State<VibeNouButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(VibeNouButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSuccess && !oldWidget.isSuccess) {
      _successController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final fgColor = widget.foregroundColor ?? Colors.white;

    Widget child;
    if (widget.isSuccess) {
      child = AnimatedBuilder(
        animation: _successScale,
        builder: (context, child) => Transform.scale(
          scale: _successScale.value,
          child: Icon(Icons.check, color: fgColor, size: 24),
        ),
      );
    } else if (widget.isLoading) {
      child = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isOutlined ? bgColor : fgColor,
          ),
        ),
      );
    } else {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    if (widget.isOutlined) {
      return SizedBox(
        width: widget.width,
        height: 52,
        child: OutlinedButton(
          onPressed: (widget.isLoading || widget.isSuccess) ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            side: BorderSide(color: bgColor.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        ),
      );
    }

    return SizedBox(
      width: widget.width,
      height: 52,
      child: ElevatedButton(
        onPressed: (widget.isLoading || widget.isSuccess) ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.7),
          disabledForegroundColor: fgColor,
          elevation: 2,
          shadowColor: bgColor.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: child,
        ),
      ),
    );
  }
}
