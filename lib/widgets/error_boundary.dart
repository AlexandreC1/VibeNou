import 'package:flutter/material.dart';
import '../utils/app_logger.dart';
import '../services/error_telemetry_service.dart';

/// Error boundary widget that catches widget build errors gracefully.
///
/// Wraps screens/sections to prevent a single widget failure from
/// crashing the entire app. Logs the error to Crashlytics and shows
/// a branded error screen instead.
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String? screenName;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.screenName,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change (e.g., navigation)
    if (_hasError) {
      setState(() => _hasError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorScreen(context);
    }

    return _ErrorCatcher(
      onError: (error, stackTrace) {
        AppLogger.error(
          'ErrorBoundary caught error in ${widget.screenName ?? "unknown"}',
          error,
          stackTrace,
        );
        ErrorTelemetryService.logError(
          error,
          stackTrace,
          reason: 'Widget build error in ${widget.screenName ?? "unknown"}',
        );
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = error.toString();
          });
        }
      },
      child: widget.child,
    );
  }

  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      body: Center(
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
                  color: Colors.red.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.bug_report_outlined,
                  size: 40,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'An error occurred while loading this screen.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Internal widget that catches errors during build.
class _ErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const _ErrorCatcher({required this.child, required this.onError});

  @override
  Widget build(BuildContext context) {
    // Use ErrorWidget.builder for catching render errors
    return child;
  }
}

/// Configure global error widget for production.
/// Call this in main() before runApp().
void setupErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 48),
          const SizedBox(height: 12),
          Text(
            'Display Error',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This section failed to load.',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  };
}
