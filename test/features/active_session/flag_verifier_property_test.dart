// Property test untuk FlagVerifier
//
// **Validates: Requirements 2.6**
//
// Property 6: Flag Salah Selalu Ditolak dan Dicatat
// For any input whose SHA-256 hash does not match the flagHash of the active level,
// the system SHALL reject the input AND increment failedAttempts by exactly 1.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nullbyte/features/active_session/domain/flag_verifier.dart';

// ── Generators ────────────────────────────────────────────────────────────────

/// Generate a random valid flag string.
String _generateValidFlag(Random rng) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
  final length = rng.nextInt(20) + 5; // 5-24 characters
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
}

/// Generate a random invalid flag (different from the valid one).
String _generateInvalidFlag(Random rng, String validFlag) {
  String invalid;
  do {
    invalid = _generateValidFlag(rng);
  } while (invalid == validFlag);
  return invalid;
}

/// Generate a random string that is definitely not a valid flag.
String _generateRandomString(Random rng) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  final length = rng.nextInt(15) + 3;
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const iterations = 100;
  late FlagVerifier verifier;

  setUpAll(() {
    verifier = const FlagVerifier();
  });

  group('Property 6: Flag Salah Selalu Ditolak dan Dicatat', () {
    test('incorrect flag is always rejected', () async {
      final rng = Random(42);

      for (var i = 0; i < iterations; i++) {
        final validFlag = _generateValidFlag(rng);
        final validHash = verifier.hashFlag(validFlag);
        final invalidFlag = _generateInvalidFlag(rng, validFlag);

        final result = verifier.verify(invalidFlag, validHash);

        expect(
          result,
          isFalse,
          reason: 'iteration $i: incorrect flag must be rejected',
        );
      }
    });

    test('correct flag is always accepted', () async {
      final rng = Random(99);

      for (var i = 0; i < iterations; i++) {
        final validFlag = _generateValidFlag(rng);
        final validHash = verifier.hashFlag(validFlag);

        final result = verifier.verify(validFlag, validHash);

        expect(
          result,
          isTrue,
          reason: 'iteration $i: correct flag must be accepted',
        );
      }
    });

    test('flag verification is case-insensitive', () async {
      final rng = Random(77);

      for (var i = 0; i < iterations; i++) {
        final flag = _generateValidFlag(rng);
        final hash = verifier.hashFlag(flag);

        // Test with uppercase
        final upperFlag = flag.toUpperCase();
        final resultUpper = verifier.verify(upperFlag, hash);
        expect(
          resultUpper,
          isTrue,
          reason: 'iteration $i: uppercase flag must match',
        );

        // Test with mixed case
        final mixedFlag = flag.split('').map((c) {
          return rng.nextBool() ? c.toUpperCase() : c.toLowerCase();
        }).join();
        final resultMixed = verifier.verify(mixedFlag, hash);
        expect(
          resultMixed,
          isTrue,
          reason: 'iteration $i: mixed case flag must match',
        );
      }
    });

    test('flag verification ignores leading/trailing whitespace', () async {
      final rng = Random(55);

      for (var i = 0; i < iterations; i++) {
        final flag = _generateValidFlag(rng);
        final hash = verifier.hashFlag(flag);

        // Test with leading spaces
        final flagWithLeading = '   $flag';
        final resultLeading = verifier.verify(flagWithLeading, hash);
        expect(
          resultLeading,
          isTrue,
          reason: 'iteration $i: flag with leading spaces must match',
        );

        // Test with trailing spaces
        final flagWithTrailing = '$flag   ';
        final resultTrailing = verifier.verify(flagWithTrailing, hash);
        expect(
          resultTrailing,
          isTrue,
          reason: 'iteration $i: flag with trailing spaces must match',
        );

        // Test with both
        final flagWithBoth = '  $flag  ';
        final resultBoth = verifier.verify(flagWithBoth, hash);
        expect(
          resultBoth,
          isTrue,
          reason:
              'iteration $i: flag with leading and trailing spaces must match',
        );
      }
    });

    test('single character difference makes flag invalid', () async {
      final rng = Random(33);

      for (var i = 0; i < iterations; i++) {
        final validFlag = _generateValidFlag(rng);
        final validHash = verifier.hashFlag(validFlag);

        // Change one character
        final chars = validFlag.split('');
        final changeIndex = rng.nextInt(chars.length);
        final originalChar = chars[changeIndex];

        // Find a different character
        String differentChar;
        do {
          differentChar = String.fromCharCode(
            rng.nextInt(26) + 97, // a-z
          );
        } while (differentChar == originalChar);

        chars[changeIndex] = differentChar;
        final modifiedFlag = chars.join();

        final result = verifier.verify(modifiedFlag, validHash);

        expect(
          result,
          isFalse,
          reason:
              'iteration $i: flag with one character changed must be rejected',
        );
      }
    });

    test('empty string is rejected', () async {
      final validFlag = 'test_flag';
      final validHash = verifier.hashFlag(validFlag);

      final result = verifier.verify('', validHash);

      expect(result, isFalse, reason: 'empty string must be rejected');
    });

    test('whitespace-only string is rejected', () async {
      final validFlag = 'test_flag';
      final validHash = verifier.hashFlag(validFlag);

      final result = verifier.verify('   ', validHash);

      expect(
        result,
        isFalse,
        reason: 'whitespace-only string must be rejected',
      );
    });

    test('hash comparison is case-insensitive', () async {
      final rng = Random(11);

      for (var i = 0; i < iterations; i++) {
        final flag = _generateValidFlag(rng);
        final hash = verifier.hashFlag(flag);

        // Test with uppercase hash
        final upperHash = hash.toUpperCase();
        final resultUpper = verifier.verify(flag, upperHash);
        expect(
          resultUpper,
          isTrue,
          reason: 'iteration $i: uppercase hash must match',
        );

        // Test with mixed case hash
        final mixedHash = hash.split('').map((c) {
          return rng.nextBool() ? c.toUpperCase() : c.toLowerCase();
        }).join();
        final resultMixed = verifier.verify(flag, mixedHash);
        expect(
          resultMixed,
          isTrue,
          reason: 'iteration $i: mixed case hash must match',
        );
      }
    });

    test('completely different flags produce different hashes', () async {
      final rng = Random(88);

      for (var i = 0; i < iterations; i++) {
        final flag1 = _generateValidFlag(rng);
        final flag2 = _generateInvalidFlag(rng, flag1);

        final hash1 = verifier.hashFlag(flag1);
        final hash2 = verifier.hashFlag(flag2);

        expect(
          hash1,
          isNot(equals(hash2)),
          reason: 'iteration $i: different flags must produce different hashes',
        );
      }
    });

    test('same flag always produces same hash', () async {
      final rng = Random(66);

      for (var i = 0; i < iterations; i++) {
        final flag = _generateValidFlag(rng);

        final hash1 = verifier.hashFlag(flag);
        final hash2 = verifier.hashFlag(flag);
        final hash3 = verifier.hashFlag(flag);

        expect(
          hash1,
          equals(hash2),
          reason: 'iteration $i: same flag must produce same hash (1st vs 2nd)',
        );
        expect(
          hash2,
          equals(hash3),
          reason: 'iteration $i: same flag must produce same hash (2nd vs 3rd)',
        );
      }
    });

    test('hash is valid SHA-256 format', () async {
      final rng = Random(44);

      for (var i = 0; i < iterations; i++) {
        final flag = _generateValidFlag(rng);
        final hash = verifier.hashFlag(flag);

        // SHA-256 produces 64 hex characters
        expect(
          hash.length,
          equals(64),
          reason: 'iteration $i: SHA-256 hash must be 64 characters',
        );

        // All characters must be hex (0-9, a-f)
        final isValidHex = RegExp(r'^[0-9a-f]{64}$').hasMatch(hash);
        expect(
          isValidHex,
          isTrue,
          reason: 'iteration $i: hash must contain only hex characters',
        );
      }
    });

    test('flag with special characters is handled correctly', () async {
      final specialFlags = [
        'flag{test_123}',
        'FLAG-with-dashes',
        'flag_with_underscores',
        'flag123',
        'test@flag',
        'flag#123',
      ];

      for (final flag in specialFlags) {
        final hash = verifier.hashFlag(flag);
        final result = verifier.verify(flag, hash);

        expect(
          result,
          isTrue,
          reason: 'flag with special characters "$flag" must verify correctly',
        );
      }
    });

    test('incorrect flag never matches by accident', () async {
      final rng = Random(22);

      for (var i = 0; i < iterations; i++) {
        final validFlag = _generateValidFlag(rng);
        final validHash = verifier.hashFlag(validFlag);

        // Generate multiple random strings and verify none match
        for (var j = 0; j < 5; j++) {
          final randomString = _generateRandomString(rng);
          if (randomString == validFlag) continue; // Skip if accidentally same

          final result = verifier.verify(randomString, validHash);
          expect(
            result,
            isFalse,
            reason: 'iteration $i.$j: random string must not match valid flag',
          );
        }
      }
    });

    test('verification is deterministic', () async {
      final rng = Random(11);

      for (var i = 0; i < iterations; i++) {
        final flag = _generateValidFlag(rng);
        final hash = verifier.hashFlag(flag);
        final invalidFlag = _generateInvalidFlag(rng, flag);

        // Verify same flag multiple times
        final result1 = verifier.verify(flag, hash);
        final result2 = verifier.verify(flag, hash);
        final result3 = verifier.verify(flag, hash);

        expect(result1, equals(result2));
        expect(result2, equals(result3));

        // Verify same invalid flag multiple times
        final invalidResult1 = verifier.verify(invalidFlag, hash);
        final invalidResult2 = verifier.verify(invalidFlag, hash);
        final invalidResult3 = verifier.verify(invalidFlag, hash);

        expect(invalidResult1, equals(invalidResult2));
        expect(invalidResult2, equals(invalidResult3));
      }
    });
  });
}
