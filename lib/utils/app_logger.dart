import 'package:logger/logger.dart';

/// Centralized logging utility for the application.
/// Replaces print() statements with structured logging.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to be displayed
      errorMethodCount: 5, // Number of method calls for errors
      lineLength: 80, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print emojis in log output
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.info, // Change to Level.warning in production
  );

  /// Log debug messages (detailed information for diagnosing problems)
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log info messages (general informational messages)
  static void info(String message) {
    _logger.i(message);
  }

  /// Log warning messages (potentially harmful situations)
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log error messages with optional error object and stack trace
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal errors (very severe error events)
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}
