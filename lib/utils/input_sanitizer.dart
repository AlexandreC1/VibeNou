/// Input Sanitization Utilities
///
/// Provides comprehensive sanitization for user-generated content
/// to prevent XSS, injection attacks, and malicious input.
///
/// Security Features:
/// - HTML/Script tag removal
/// - Special character escaping
/// - Whitespace normalization
/// - Length validation
/// - Unicode character filtering
///
/// Last updated: 2026-03-24
library;

/// InputSanitizer - Sanitizes user input to prevent security vulnerabilities
class InputSanitizer {
  /// Sanitize user profile name
  ///
  /// Removes:
  /// - HTML tags
  /// - Script tags
  /// - Special characters that could be used for injection
  /// - Excessive whitespace
  ///
  /// Preserves:
  /// - Letters (all languages)
  /// - Numbers
  /// - Spaces, hyphens, apostrophes (for names like "Mary-Jane" or "O'Brien")
  ///
  /// Max length: 50 characters
  static String sanitizeName(String input) {
    if (input.isEmpty) return input;

    String sanitized = input
        // Remove script tags and their content first
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        // Remove all other HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Remove null bytes
        .replaceAll('\x00', '')
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Only allow letters, numbers, spaces, hyphens, apostrophes
    // This regex allows Unicode letters from any language
    sanitized = sanitized.replaceAll(
      RegExp(r"[^\p{L}\p{N}\s\-']", unicode: true),
      '',
    );

    // Limit length
    if (sanitized.length > 50) {
      sanitized = sanitized.substring(0, 50);
    }

    return sanitized.trim();
  }

  /// Sanitize user bio/description
  ///
  /// More permissive than name sanitization, but still secure.
  ///
  /// Removes:
  /// - Script tags and JavaScript
  /// - Dangerous HTML tags (iframe, object, embed, etc.)
  /// - Event handlers (onclick, onerror, etc.)
  ///
  /// Preserves:
  /// - Basic text and punctuation
  /// - Emojis
  /// - Line breaks
  ///
  /// Max length: 500 characters
  static String sanitizeBio(String input) {
    if (input.isEmpty) return input;

    String sanitized = input
        // Remove script tags (case insensitive)
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        // Remove event handlers (onclick, onerror, etc.)
        .replaceAll(RegExp(r'on\w+\s*=\s*"[^"]*"', caseSensitive: false), '')
        .replaceAll(RegExp(r"on\w+\s*=\s*'[^']*'", caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=\s*\S+', caseSensitive: false), '')
        // Remove dangerous tags
        .replaceAll(RegExp(r'<(iframe|object|embed|applet|meta|link|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true), '')
        // Remove all remaining HTML tags
        .replaceAll(RegExp(r'<[^>]+>'), '')
        // Remove null bytes
        .replaceAll('\x00', '')
        // Remove javascript: and data: URIs
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'data:text/html', caseSensitive: false), '')
        // Normalize excessive whitespace (but preserve single line breaks)
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    // Limit length
    if (sanitized.length > 500) {
      sanitized = sanitized.substring(0, 500);
    }

    return sanitized.trim();
  }

  /// Sanitize interest tag
  ///
  /// Very strict - only alphanumeric and spaces
  ///
  /// Max length: 30 characters
  static String sanitizeInterest(String input) {
    if (input.isEmpty) return input;

    String sanitized = input
        // Remove script tags and their content first
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        // Remove all other HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Only allow letters, numbers, and spaces
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Limit length
    if (sanitized.length > 30) {
      sanitized = sanitized.substring(0, 30);
    }

    return sanitized.trim();
  }

  /// Sanitize a list of interests
  ///
  /// Applies sanitizeInterest to each item and removes empty/duplicate values
  static List<String> sanitizeInterestList(List<String> interests) {
    final sanitized = interests
        .map((interest) => sanitizeInterest(interest))
        .where((interest) => interest.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();

    return sanitized;
  }

  /// Sanitize generic text field
  ///
  /// Use this for any user input that will be displayed
  ///
  /// Max length: customizable (default 1000)
  static String sanitizeText(String input, {int maxLength = 1000}) {
    if (input.isEmpty) return input;

    String sanitized = input
        // Remove script tags
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true), '')
        // Remove all HTML tags
        .replaceAll(RegExp(r'<[^>]+>'), '')
        // Remove null bytes
        .replaceAll('\x00', '')
        // Normalize whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Limit length
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return sanitized;
  }

  /// Check if input contains potentially malicious content
  ///
  /// Returns true if suspicious patterns are detected
  static bool containsMaliciousContent(String input) {
    if (input.isEmpty) return false;

    final maliciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // Event handlers
      RegExp(r'<iframe', caseSensitive: false),
      RegExp(r'<object', caseSensitive: false),
      RegExp(r'<embed', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
      RegExp(r'expression\s*\(', caseSensitive: false), // CSS expressions
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
    ];

    return maliciousPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Validate and sanitize all profile fields at once
  ///
  /// Returns sanitized map of profile data
  static Map<String, dynamic> sanitizeProfileData(Map<String, dynamic> profileData) {
    final sanitized = Map<String, dynamic>.from(profileData);

    // Sanitize name
    if (sanitized.containsKey('name')) {
      sanitized['name'] = sanitizeName(sanitized['name'].toString());
    }

    // Sanitize bio
    if (sanitized.containsKey('bio')) {
      sanitized['bio'] = sanitizeBio(sanitized['bio'].toString());
    }

    // Sanitize interests
    if (sanitized.containsKey('interests') && sanitized['interests'] is List) {
      sanitized['interests'] = sanitizeInterestList(
        List<String>.from(sanitized['interests']),
      );
    }

    // Sanitize gender (if it's a free text field)
    if (sanitized.containsKey('gender') && sanitized['gender'] is String) {
      sanitized['gender'] = sanitizeText(sanitized['gender'].toString(), maxLength: 20);
    }

    return sanitized;
  }
}
