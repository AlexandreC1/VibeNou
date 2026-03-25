import 'package:flutter_test/flutter_test.dart';
import 'package:vibenou/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer - Name Sanitization', () {
    test('should allow normal names', () {
      expect(InputSanitizer.sanitizeName('John Doe'), 'John Doe');
      expect(InputSanitizer.sanitizeName('Mary-Jane'), 'Mary-Jane');
      expect(InputSanitizer.sanitizeName("O'Brien"), "O'Brien");
      expect(InputSanitizer.sanitizeName('José García'), 'José García');
    });

    test('should remove HTML tags', () {
      expect(InputSanitizer.sanitizeName('<b>John</b>'), 'John');
      expect(InputSanitizer.sanitizeName('<script>alert("xss")</script>John'), 'John');
      expect(InputSanitizer.sanitizeName('John<br>Doe'), 'JohnDoe');
    });

    test('should remove script tags', () {
      expect(
        InputSanitizer.sanitizeName('<script>malicious()</script>Jane'),
        'Jane',
      );
      expect(
        InputSanitizer.sanitizeName('Name<script src="evil.js"></script>'),
        'Name',
      );
    });

    test('should normalize whitespace', () {
      expect(InputSanitizer.sanitizeName('John   Doe'), 'John Doe');
      expect(InputSanitizer.sanitizeName('  John  '), 'John');
      expect(InputSanitizer.sanitizeName('John\n\nDoe'), 'John Doe');
    });

    test('should enforce 50 character limit', () {
      final longName = 'A' * 100;
      expect(InputSanitizer.sanitizeName(longName).length, 50);
    });

    test('should remove special characters except hyphens and apostrophes', () {
      expect(InputSanitizer.sanitizeName('John@Doe'), 'JohnDoe');
      expect(InputSanitizer.sanitizeName('John#123'), 'John123');
      expect(InputSanitizer.sanitizeName('John-Mary'), 'John-Mary');
      expect(InputSanitizer.sanitizeName("O'Connor"), "O'Connor");
    });

    test('should handle empty input', () {
      expect(InputSanitizer.sanitizeName(''), '');
    });

    test('should remove null bytes', () {
      expect(InputSanitizer.sanitizeName('John\x00Doe'), 'JohnDoe');
    });
  });

  group('InputSanitizer - Bio Sanitization', () {
    test('should allow normal bio text', () {
      const bio = 'I love hiking and photography. Looking for adventure!';
      expect(InputSanitizer.sanitizeBio(bio), bio);
    });

    test('should allow emojis', () {
      const bio = 'I love ❤️ traveling 🌍 and photography 📸';
      expect(InputSanitizer.sanitizeBio(bio), bio);
    });

    test('should remove script tags', () {
      expect(
        InputSanitizer.sanitizeBio('<script>alert("xss")</script>Hello'),
        'Hello',
      );
      expect(
        InputSanitizer.sanitizeBio('Bio<script>malicious()</script>text'),
        'Biotext',
      );
    });

    test('should remove event handlers', () {
      expect(
        InputSanitizer.sanitizeBio('Click <a onclick="evil()">here</a>'),
        'Click here',
      );
      expect(
        InputSanitizer.sanitizeBio('<img onerror="steal()" src="x">'),
        '',
      );
    });

    test('should remove dangerous tags', () {
      expect(
        InputSanitizer.sanitizeBio('<iframe src="evil.com"></iframe>Hello'),
        'Hello',
      );
      expect(
        InputSanitizer.sanitizeBio('<object data="evil.swf"></object>Bio'),
        'Bio',
      );
      expect(
        InputSanitizer.sanitizeBio('<embed src="evil.mp3"></embed>Text'),
        'Text',
      );
    });

    test('should remove all HTML tags', () {
      expect(InputSanitizer.sanitizeBio('<b>Bold</b> text'), 'Bold text');
      expect(InputSanitizer.sanitizeBio('<div>Content</div>'), 'Content');
      expect(
        InputSanitizer.sanitizeBio('<p>Para 1</p><p>Para 2</p>'),
        'Para 1Para 2',
      );
    });

    test('should remove javascript: URIs', () {
      expect(
        InputSanitizer.sanitizeBio('javascript:alert(1)'),
        'alert(1)',
      );
      expect(
        InputSanitizer.sanitizeBio('Click javascript:void(0)'),
        'Click void(0)',
      );
    });

    test('should remove data: URIs and script content', () {
      expect(
        InputSanitizer.sanitizeBio('data:text/html,<script>alert(1)</script>'),
        ',', // Script tags AND content are removed, then data:text/html is removed
      );
    });

    test('should enforce 500 character limit', () {
      final longBio = 'A' * 1000;
      expect(InputSanitizer.sanitizeBio(longBio).length, 500);
    });

    test('should preserve line breaks but limit to 2 consecutive', () {
      expect(
        InputSanitizer.sanitizeBio('Line 1\n\n\n\n\nLine 2'),
        'Line 1\n\nLine 2',
      );
    });

    test('should handle empty input', () {
      expect(InputSanitizer.sanitizeBio(''), '');
    });
  });

  group('InputSanitizer - Interest Sanitization', () {
    test('should allow normal interests', () {
      expect(InputSanitizer.sanitizeInterest('Photography'), 'Photography');
      expect(InputSanitizer.sanitizeInterest('Video Games'), 'Video Games');
      expect(InputSanitizer.sanitizeInterest('Música'), 'Música');
    });

    test('should remove HTML tags', () {
      expect(InputSanitizer.sanitizeInterest('<b>Music</b>'), 'Music');
      expect(InputSanitizer.sanitizeInterest('<script>evil</script>Art'), 'Art');
    });

    test('should remove special characters', () {
      expect(InputSanitizer.sanitizeInterest('Music@#\$'), 'Music');
      expect(InputSanitizer.sanitizeInterest('Art!!!'), 'Art');
      expect(InputSanitizer.sanitizeInterest('Tech-Coding'), 'TechCoding');
    });

    test('should enforce 30 character limit', () {
      final longInterest = 'A' * 50;
      expect(InputSanitizer.sanitizeInterest(longInterest).length, 30);
    });

    test('should normalize whitespace', () {
      expect(InputSanitizer.sanitizeInterest('  Music  '), 'Music');
      expect(InputSanitizer.sanitizeInterest('Video   Games'), 'Video Games');
    });

    test('should handle empty input', () {
      expect(InputSanitizer.sanitizeInterest(''), '');
    });
  });

  group('InputSanitizer - Interest List Sanitization', () {
    test('should sanitize all interests in list', () {
      final interests = ['Music', '<b>Art</b>', 'Photography!!!'];
      final sanitized = InputSanitizer.sanitizeInterestList(interests);
      expect(sanitized, ['Music', 'Art', 'Photography']);
    });

    test('should remove empty interests', () {
      final interests = ['Music', '', '   ', 'Art'];
      final sanitized = InputSanitizer.sanitizeInterestList(interests);
      expect(sanitized, ['Music', 'Art']);
    });

    test('should remove duplicates', () {
      final interests = ['Music', 'Art', 'Music', 'Photography'];
      final sanitized = InputSanitizer.sanitizeInterestList(interests);
      expect(sanitized.length, 3);
      expect(sanitized.contains('Music'), true);
      expect(sanitized.contains('Art'), true);
      expect(sanitized.contains('Photography'), true);
    });

    test('should handle empty list', () {
      final sanitized = InputSanitizer.sanitizeInterestList([]);
      expect(sanitized, []);
    });
  });

  group('InputSanitizer - Malicious Content Detection', () {
    test('should detect script tags', () {
      expect(
        InputSanitizer.containsMaliciousContent('<script>alert(1)</script>'),
        true,
      );
      expect(
        InputSanitizer.containsMaliciousContent('<SCRIPT>evil()</SCRIPT>'),
        true,
      );
    });

    test('should detect javascript: URIs', () {
      expect(
        InputSanitizer.containsMaliciousContent('javascript:alert(1)'),
        true,
      );
      expect(
        InputSanitizer.containsMaliciousContent('JavaScript:void(0)'),
        true,
      );
    });

    test('should detect event handlers', () {
      expect(
        InputSanitizer.containsMaliciousContent('onclick="evil()"'),
        true,
      );
      expect(
        InputSanitizer.containsMaliciousContent('onerror=malicious'),
        true,
      );
      expect(
        InputSanitizer.containsMaliciousContent('onload="steal()"'),
        true,
      );
    });

    test('should detect iframe tags', () {
      expect(
        InputSanitizer.containsMaliciousContent('<iframe src="evil"></iframe>'),
        true,
      );
    });

    test('should detect object tags', () {
      expect(
        InputSanitizer.containsMaliciousContent('<object data="evil"></object>'),
        true,
      );
    });

    test('should detect eval', () {
      expect(
        InputSanitizer.containsMaliciousContent('eval(userInput)'),
        true,
      );
    });

    test('should detect vbscript', () {
      expect(
        InputSanitizer.containsMaliciousContent('vbscript:msgbox'),
        true,
      );
    });

    test('should not flag normal content', () {
      expect(
        InputSanitizer.containsMaliciousContent('I love photography'),
        false,
      );
      expect(
        InputSanitizer.containsMaliciousContent('Check out my website!'),
        false,
      );
    });

    test('should handle empty input', () {
      expect(InputSanitizer.containsMaliciousContent(''), false);
    });
  });

  group('InputSanitizer - Profile Data Sanitization', () {
    test('should sanitize all profile fields', () {
      final profileData = {
        'name': '<b>John</b> Doe',
        'bio': '<script>evil()</script>I love hiking',
        'interests': ['Music!!!', '<b>Art</b>', ''],
        'gender': 'Male<script>',
      };

      final sanitized = InputSanitizer.sanitizeProfileData(profileData);

      expect(sanitized['name'], 'John Doe');
      expect(sanitized['bio'], 'I love hiking');
      expect(sanitized['interests'], ['Music', 'Art']);
      expect(sanitized['gender'], 'Male');
    });

    test('should handle missing fields gracefully', () {
      final profileData = {'name': 'John'};
      final sanitized = InputSanitizer.sanitizeProfileData(profileData);
      expect(sanitized['name'], 'John');
    });

    test('should handle empty profile data', () {
      final sanitized = InputSanitizer.sanitizeProfileData({});
      expect(sanitized, {});
    });
  });
}
