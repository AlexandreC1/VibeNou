import 'package:flutter/material.dart';

/// Branded themed dialog that replaces AlertDialog for consistent styling.
class VibeNouDialog extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? message;
  final Widget? content;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? iconColor;

  const VibeNouDialog({
    super.key,
    this.title,
    this.titleWidget,
    this.message,
    this.content,
    this.actions,
    this.icon,
    this.iconColor,
  });

  /// Confirmation dialog with cancel/confirm actions.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => VibeNouDialog(
        icon: isDangerous ? Icons.warning_amber_rounded : Icons.help_outline,
        iconColor: isDangerous ? Colors.orange : null,
        title: title,
        message: message,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ??
                  (isDangerous ? Colors.red : Theme.of(context).colorScheme.primary),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  /// Success dialog with dismiss.
  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    return showDialog(
      context: context,
      builder: (context) => VibeNouDialog(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
        title: title,
        message: message,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (icon != null) ...[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            if (titleWidget != null)
              titleWidget!
            else if (title != null)
              Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),

            if (title != null || titleWidget != null)
              const SizedBox(height: 8),

            // Message
            if (message != null)
              Text(
                message!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

            // Custom content
            if (content != null) ...[
              const SizedBox(height: 12),
              content!,
            ],

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!
                    .map((action) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: action,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Branded bottom sheet with drag handle and rounded top.
class VibeNouBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final double? maxHeight;

  const VibeNouBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.maxHeight,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget child,
    double? maxHeight,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VibeNouBottomSheet(
        title: title,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: Text(
                title!,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Divider(color: Colors.grey[200]),
          ],

          // Content
          Flexible(child: child),
        ],
      ),
    );
  }
}
