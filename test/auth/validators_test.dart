import 'package:flutter_test/flutter_test.dart';
import 'package:jeevamitra/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('rejects null/empty', () {
      expect(Validators.phone(null), 'Phone number required');
      expect(Validators.phone(''), 'Phone number required');
      expect(Validators.phone('   '), 'Phone number required');
    });

    test('rejects too short / too long', () {
      expect(Validators.phone('98765'), isNotNull);
      expect(Validators.phone('987654321012'), isNotNull);
    });

    test('rejects numbers not starting with 6-9 (invalid Indian mobile prefix)', () {
      expect(Validators.phone('1234567890'), isNotNull);
      expect(Validators.phone('5876543210'), isNotNull);
    });

    test('accepts valid 10-digit Indian mobile numbers starting 6-9', () {
      for (final prefix in ['6', '7', '8', '9']) {
        expect(Validators.phone('${prefix}876543210'), isNull);
      }
    });

    test('strips spaces and dashes from an otherwise valid 10-digit number', () {
      expect(Validators.phone('98765-43210'), isNull);
      expect(Validators.phone('98765 43210'), isNull);
    });

    test('a country-code-prefixed number becomes too long once stripped', () {
      // '+91 98765 43210' strips to 12 digits ('919876543210'), which no
      // longer matches the 10-digit pattern — the screen itself is
      // responsible for prepending +91 to a bare 10-digit input, not this
      // validator accepting an already-prefixed one.
      expect(Validators.phone('+91 98765 43210'), isNotNull);
    });
  });

  group('Validators.otp', () {
    test('rejects null/empty', () {
      expect(Validators.otp(null), 'OTP required');
      expect(Validators.otp(''), 'OTP required');
    });

    test('rejects non-6-digit input', () {
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('1234567'), isNotNull);
      expect(Validators.otp('12a456'), isNotNull);
    });

    test('accepts a well-formed 6-digit OTP', () {
      expect(Validators.otp('123456'), isNull);
    });
  });

  group('Validators.name', () {
    test('rejects empty and single-character names', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('R'), isNotNull);
    });

    test('rejects names over 50 characters', () {
      expect(Validators.name('R' * 51), isNotNull);
    });

    test('accepts a normal name', () {
      expect(Validators.name('Ravi Kumar'), isNull);
    });
  });

  group('Validators.village / district', () {
    test('village rejects empty and single character', () {
      expect(Validators.village(''), isNotNull);
      expect(Validators.village('A'), isNotNull);
    });

    test('village accepts a valid value', () {
      expect(Validators.village('Narasaraopet'), isNull);
    });

    test('district rejects empty', () {
      expect(Validators.district(''), isNotNull);
    });

    test('district accepts a valid value', () {
      expect(Validators.district('Guntur'), isNull);
    });
  });

  group('Validators.sheepCount / price / area', () {
    test('sheepCount rejects zero, negative, non-numeric, and absurdly large values', () {
      expect(Validators.sheepCount('0'), isNotNull);
      expect(Validators.sheepCount('-5'), isNotNull);
      expect(Validators.sheepCount('abc'), isNotNull);
      expect(Validators.sheepCount('20000'), isNotNull);
    });

    test('sheepCount accepts a reasonable positive count', () {
      expect(Validators.sheepCount('150'), isNull);
    });

    test('price rejects zero/negative/non-numeric', () {
      expect(Validators.price('0'), isNotNull);
      expect(Validators.price('-1'), isNotNull);
      expect(Validators.price('free'), isNotNull);
    });

    test('price accepts a positive number', () {
      expect(Validators.price('250.50'), isNull);
    });

    test('area rejects zero/negative/non-numeric and accepts positive', () {
      expect(Validators.area('0'), isNotNull);
      expect(Validators.area('big'), isNotNull);
      expect(Validators.area('2.5'), isNull);
    });
  });
}
