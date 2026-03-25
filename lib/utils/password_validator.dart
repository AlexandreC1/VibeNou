/// Password validation utilities
class PasswordValidator {
  /// Minimum password length
  static const int minLength = 8;

  /// Maximum password length
  static const int maxLength = 128;

  /// Validate password strength
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password cannot be empty';
    }

    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }

    if (password.length > maxLength) {
      return 'Password must be less than $maxLength characters';
    }

    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*...)';
    }

    // Check for common weak passwords
    if (_isCommonPassword(password.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }

    return null; // Password is valid
  }

  /// Get password strength (0-100)
  static int getPasswordStrength(String password) {
    int strength = 0;

    // Length score (0-30 points)
    if (password.length >= minLength) {
      strength += 10;
    }
    if (password.length >= 12) {
      strength += 10;
    }
    if (password.length >= 16) {
      strength += 10;
    }

    // Character variety (0-40 points)
    if (password.contains(RegExp(r'[a-z]'))) strength += 10;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 10;
    if (password.contains(RegExp(r'[0-9]'))) strength += 10;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 10;

    // Complexity score (0-30 points)
    // Check for multiple character types mixed
    final hasMultipleTypes = [
      password.contains(RegExp(r'[a-z]')),
      password.contains(RegExp(r'[A-Z]')),
      password.contains(RegExp(r'[0-9]')),
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    ].where((has) => has).length;

    strength += hasMultipleTypes * 7;

    // Penalize common passwords
    if (_isCommonPassword(password.toLowerCase())) {
      strength -= 50;
    }

    // Penalize repetitive characters
    if (_hasRepeatingChars(password)) {
      strength -= 20;
    }

    return strength.clamp(0, 100);
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    if (strength < 30) return 'Weak';
    if (strength < 60) return 'Fair';
    if (strength < 80) return 'Good';
    return 'Strong';
  }

  /// Get password strength color
  static String getPasswordStrengthColor(int strength) {
    if (strength < 30) return 'red';
    if (strength < 60) return 'orange';
    if (strength < 80) return 'yellow';
    return 'green';
  }

  /// Check if password is in common password list
  ///
  /// Expanded list based on most commonly breached passwords
  /// Source: Compilation of top leaked passwords from security breaches
  static bool _isCommonPassword(String password) {
    const commonPasswords = [
      // Top 10 most common
      'password',
      '12345678',
      'qwerty',
      '123456789',
      '12345',
      '1234567',
      'password1',
      '123456',
      'qwerty123',
      '1q2w3e4r',

      // Common patterns
      'abc123',
      'password123',
      'qwertyuiop',
      'asdfghjkl',
      '1234567890',
      '123123',
      '000000',
      '1111111',
      'zxcvbnm',
      'asdfgh',

      // Common words
      'letmein',
      'welcome',
      'monkey',
      'dragon',
      'master',
      'sunshine',
      'princess',
      'football',
      'baseball',
      'superman',
      'batman',
      'trustno1',
      'freedom',
      'whatever',
      'starwars',

      // Admin/system defaults
      'admin',
      'root',
      'user',
      'pass',
      'test',
      'admin123',
      'administrator',
      'password!',
      'pass123',
      'changeme',
      'default',
      'guest',

      // Keyboard patterns
      'qweasd',
      'asdzxc',
      'zxcasd',
      '1qaz2wsx',
      'qazwsx',
      'qwaszx',
      'zaq12wsx',

      // Years and dates
      '2024',
      '2023',
      '2022',
      '2021',
      '2020',
      '1234',
      '0000',

      // Simple variations
      'password!',
      'password@',
      'password#',
      'p@ssword',
      'p@ssw0rd',
      'passw0rd',
      'passw@rd',

      // Social media related
      'iloveyou',
      'loveyou',
      'fuckyou',
      'fuckoff',
      'asshole',

      // Sports teams (common)
      'lakers',
      'yankees',
      'patriots',

      // Simple sequences
      'abcdef',
      'fedcba',
      '654321',
      'abcd1234',

      // Tech related
      'computer',
      'internet',
      'samsung',
      'android',
      'google',
      'microsoft',
      'windows',
      'linux',

      // Names (very common)
      'michael',
      'jennifer',
      'jordan',
      'thomas',
      'robert',
    ];

    return commonPasswords.contains(password);
  }

  /// Check for repeating characters (e.g., "aaa", "111")
  static bool _hasRepeatingChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i] == password[i + 2]) {
        return true;
      }
    }
    return false;
  }

  /// Validate password match
  static String? validatePasswordMatch(String password, String confirmPassword) {
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
