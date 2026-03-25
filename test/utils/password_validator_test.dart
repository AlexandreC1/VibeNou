import 'package:flutter_test/flutter_test.dart';
import 'package:vibenou/utils/password_validator.dart';

void main() {
  group('PasswordValidator - Password Validation', () {
    test('should accept strong passwords', () {
      expect(PasswordValidator.validatePassword('MyP@ssw0rd123'), null);
      expect(PasswordValidator.validatePassword('Secur3P@ss!'), null);
      expect(PasswordValidator.validatePassword('C0mpl3x!Pass'), null);
    });

    test('should reject empty password', () {
      final result = PasswordValidator.validatePassword('');
      expect(result, isNotNull);
      expect(result, contains('cannot be empty'));
    });

    test('should reject password shorter than 8 characters', () {
      final result = PasswordValidator.validatePassword('Pass1!');
      expect(result, isNotNull);
      expect(result, contains('at least 8 characters'));
    });

    test('should reject password longer than 128 characters', () {
      final longPassword = 'P@ssw0rd' * 20; // 160 characters
      final result = PasswordValidator.validatePassword(longPassword);
      expect(result, isNotNull);
      expect(result, contains('less than 128 characters'));
    });

    test('should require uppercase letter', () {
      final result = PasswordValidator.validatePassword('password123!');
      expect(result, isNotNull);
      expect(result, contains('uppercase letter'));
    });

    test('should require lowercase letter', () {
      final result = PasswordValidator.validatePassword('PASSWORD123!');
      expect(result, isNotNull);
      expect(result, contains('lowercase letter'));
    });

    test('should require number', () {
      final result = PasswordValidator.validatePassword('Password!');
      expect(result, isNotNull);
      expect(result, contains('number'));
    });

    test('should require special character', () {
      final result = PasswordValidator.validatePassword('Password123');
      expect(result, isNotNull);
      expect(result, contains('special character'));
    });

    test('should reject common passwords', () {
      final commonPasswords = [
        'Password123!',
        'Qwerty123!',
        'Admin123!',
        '12345678A!',
        'Welcome1!',
      ];

      for (final password in commonPasswords) {
        final result = PasswordValidator.validatePassword(password);
        expect(result, isNotNull, reason: 'Should reject: $password');
        expect(result, contains('too common'), reason: 'Failed for: $password');
      }
    });

    test('should accept password at minimum length with all requirements', () {
      // Exactly 8 characters with all requirements
      final result = PasswordValidator.validatePassword('Pass123!');
      expect(result, null);
    });
  });

  group('PasswordValidator - Password Strength', () {
    test('should rate very weak passwords as weak', () {
      final strength = PasswordValidator.getPasswordStrength('Pass123!'); // Minimum valid
      expect(strength, lessThan(30));
      expect(PasswordValidator.getPasswordStrengthLabel(strength), 'Weak');
    });

    test('should rate medium passwords as fair', () {
      final strength = PasswordValidator.getPasswordStrength('MyPassword1!');
      expect(strength, greaterThanOrEqualTo(30));
      expect(strength, lessThan(60));
    });

    test('should rate good passwords as good', () {
      final strength = PasswordValidator.getPasswordStrength('MyStr0ng!Password');
      expect(strength, greaterThanOrEqualTo(60));
      expect(strength, lessThan(80));
    });

    test('should rate strong passwords as strong', () {
      final strength = PasswordValidator.getPasswordStrength('MyV3ry\$tr0ng!P@ssw0rd2024');
      expect(strength, greaterThanOrEqualTo(80));
      expect(PasswordValidator.getPasswordStrengthLabel(strength), 'Strong');
    });

    test('should penalize common passwords heavily', () {
      final commonStrength = PasswordValidator.getPasswordStrength('Password123!');
      final uniqueStrength = PasswordValidator.getPasswordStrength('Xk9\$mP2qL!zY');

      expect(commonStrength, lessThan(uniqueStrength));
      expect(commonStrength, lessThan(30)); // Should be weak
    });

    test('should penalize repeating characters', () {
      final repeatStrength = PasswordValidator.getPasswordStrength('Passs111!!!');
      final normalStrength = PasswordValidator.getPasswordStrength('Password1!');

      expect(repeatStrength, lessThan(normalStrength));
    });

    test('should reward longer passwords', () {
      final short = PasswordValidator.getPasswordStrength('Pass1!');
      final medium = PasswordValidator.getPasswordStrength('Password123!');
      final long = PasswordValidator.getPasswordStrength('MyVeryLongPassword123!');

      expect(medium, greaterThan(short));
      expect(long, greaterThan(medium));
    });

    test('should reward character variety', () {
      final simple = PasswordValidator.getPasswordStrength('Password1!');
      final complex = PasswordValidator.getPasswordStrength('P@ssW0rd!#123');

      expect(complex, greaterThanOrEqualTo(simple));
    });

    test('strength should be clamped between 0 and 100', () {
      // Very weak password
      final weak = PasswordValidator.getPasswordStrength('Pass123!');
      expect(weak, greaterThanOrEqualTo(0));
      expect(weak, lessThanOrEqualTo(100));

      // Very strong password
      final strong = PasswordValidator.getPasswordStrength('MySuper\$tr0ng!P@ssw0rd#2024XyZ');
      expect(strong, greaterThanOrEqualTo(0));
      expect(strong, lessThanOrEqualTo(100));
    });
  });

  group('PasswordValidator - Password Strength Labels', () {
    test('should return correct labels', () {
      expect(PasswordValidator.getPasswordStrengthLabel(10), 'Weak');
      expect(PasswordValidator.getPasswordStrengthLabel(40), 'Fair');
      expect(PasswordValidator.getPasswordStrengthLabel(70), 'Good');
      expect(PasswordValidator.getPasswordStrengthLabel(90), 'Strong');
    });

    test('should return correct colors', () {
      expect(PasswordValidator.getPasswordStrengthColor(10), 'red');
      expect(PasswordValidator.getPasswordStrengthColor(40), 'orange');
      expect(PasswordValidator.getPasswordStrengthColor(70), 'yellow');
      expect(PasswordValidator.getPasswordStrengthColor(90), 'green');
    });
  });

  group('PasswordValidator - Password Match Validation', () {
    test('should accept matching passwords', () {
      final result = PasswordValidator.validatePasswordMatch(
        'Password123!',
        'Password123!',
      );
      expect(result, null);
    });

    test('should reject non-matching passwords', () {
      final result = PasswordValidator.validatePasswordMatch(
        'Password123!',
        'Different123!',
      );
      expect(result, isNotNull);
      expect(result, contains('do not match'));
    });

    test('should be case sensitive', () {
      final result = PasswordValidator.validatePasswordMatch(
        'Password123!',
        'password123!',
      );
      expect(result, isNotNull);
      expect(result, contains('do not match'));
    });

    test('should handle empty passwords', () {
      final result = PasswordValidator.validatePasswordMatch('', '');
      expect(result, null); // Empty matches empty
    });
  });

  group('PasswordValidator - Common Password Detection', () {
    test('should detect top common passwords', () {
      final topCommon = [
        'password',
        '12345678',
        'qwerty',
        '123456789',
        'abc123',
      ];

      for (final pwd in topCommon) {
        // Need to make them valid first by adding requirements
        final validPwd = '${pwd[0].toUpperCase()}${pwd.substring(1)}1!';
        final result = PasswordValidator.validatePassword(validPwd);

        // Should be rejected as too common (case-insensitive check)
        expect(result, isNotNull, reason: 'Should reject: $pwd');
      }
    });

    test('should detect keyboard patterns', () {
      final patterns = ['qwerty', 'asdfgh', 'qweasd'];

      for (final pattern in patterns) {
        final validPwd = '${pattern[0].toUpperCase()}${pattern.substring(1)}1!';
        final result = PasswordValidator.validatePassword(validPwd);
        expect(result, isNotNull);
      }
    });

    test('should detect year-based passwords', () {
      // Years are common passwords
      final result1 = PasswordValidator.validatePassword('Password2024!');
      final result2 = PasswordValidator.validatePassword('Password2023!');

      // These might not be rejected by common password check
      // but should have lower strength scores
      final strength1 = PasswordValidator.getPasswordStrength('Password2024!');
      final strength2 = PasswordValidator.getPasswordStrength('P@ssw0rd!#XyZ');

      expect(strength2, greaterThan(strength1));
    });

    test('should be case-insensitive for common password check', () {
      final result1 = PasswordValidator.validatePassword('PASSWORD1!');
      final result2 = PasswordValidator.validatePassword('Password1!');

      // Both should be flagged as too common
      expect(result1, isNotNull);
      expect(result2, isNotNull);
    });
  });
}
