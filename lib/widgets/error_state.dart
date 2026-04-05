import 'package:flutter/material.dart';

/// Reusable branded error state widget.
///
/// Shows an error icon, message, and retry button.
/// Supports network errors with offline detection.
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool isOffline;

  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Please try again later.',
    this.onRetry,
    this.isOffline = false,
  });

  factory ErrorState.network({VoidCallback? onRetry}) {
    return ErrorState(
      title: 'No Internet Connection',
      message: 'Check your connection and try again.',
      onRetry: onRetry,
      isOffline: true,
    );
  }

  factory ErrorState.loadFailed({VoidCallback? onRetry}) {
    return ErrorState(
      title: 'Failed to load',
      message: 'Something went wrong loading this content.',
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isOffline ? Colors.orange : Colors.red).withValues(alpha: 0.1),
              ),
              child: Icon(
                isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 40,
                color: isOffline ? Colors.orange[600] : Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
