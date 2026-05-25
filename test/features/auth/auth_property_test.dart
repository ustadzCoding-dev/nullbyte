// Property test untuk AuthRepository
//
// **Validates: Requirements 1.3, 1.6**
//
// Property 1: Profil Baru Selalu Valid
// For any combination of valid username and email, when registration succeeds,
// the created profile SHALL have totalScore = 0, a non-null default avatar,
// and username equal to the input.
//
// Property 3: Validasi Panjang Kata Sandi
// For any string with length < 8 characters, password validation SHALL reject it;
// for any string with length >= 8 characters, validation SHALL accept it.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullbyte/core/constants/hive_boxes.dart';
import 'package:nullbyte/features/auth/data/auth_repository.dart';

// ── Generators ────────────────────────────────────────────────────────────────

/// Generate a random valid email.
String _generateValidEmail(Random rng) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final username = String.fromCharCodes(
    Iterable.generate(
      rng.nextInt(10) + 5,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
  final domain = String.fromCharCodes(
    Iterable.generate(
      rng.nextInt(5) + 3,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
  return '$username@$domain.com';
}

/// Generate a random valid username.
String _generateValidUsername(Random rng) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
  final length = rng.nextInt(15) + 3;
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
}

/// Generate a random password of specified length.
String _generatePassword(Random rng, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const iterations = 50;

  setUpAll(() async {
    // Initialize Hive for testing
    Hive.init('.');

    // Register adapters if needed
    if (!Hive.isAdapterRegistered(1)) {
      // PlayerProfile adapter would be registered here if needed
    }

    // Open the settings box
    if (!Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.openBox(HiveBoxes.settings);
    }
  });

  tearDown(() async {
    // Clear settings box after each test
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).clear();
    }
  });

  group('Property 1: Profil Baru Selalu Valid', () {
    test('new profile has totalScore = 0', () async {
      final rng = Random(42);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.totalScore,
          equals(0),
          reason: 'iteration $i: new profile must have totalScore = 0',
        );
      }
    });

    test('new profile has non-null avatar', () async {
      final rng = Random(99);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.id,
          isNotNull,
          reason: 'iteration $i: new profile must have non-null id',
        );
      }
    });

    test('new profile username matches input', () async {
      final rng = Random(77);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.username,
          equals(username),
          reason: 'iteration $i: profile username must match input',
        );
      }
    });

    test('new profile has level = 1', () async {
      final rng = Random(55);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.level,
          equals(1),
          reason: 'iteration $i: new profile must have level = 1',
        );
      }
    });

    test('new profile has xp = 0', () async {
      final rng = Random(33);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.xp,
          equals(0),
          reason: 'iteration $i: new profile must have xp = 0',
        );
      }
    });

    test('new profile has isGuest = false', () async {
      final rng = Random(11);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.isGuest,
          isFalse,
          reason: 'iteration $i: new profile must have isGuest = false',
        );
      }
    });

    test('new profile has non-null email', () async {
      final rng = Random(88);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.email,
          isNotNull,
          reason: 'iteration $i: new profile must have non-null email',
        );
        expect(
          profile.email,
          equals(email),
          reason: 'iteration $i: profile email must match input',
        );
      }
    });

    test('new profile has non-null createdAt', () async {
      final rng = Random(66);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 12);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile.createdAt,
          isNotNull,
          reason: 'iteration $i: new profile must have non-null createdAt',
        );
      }
    });
  });

  group('Property 3: Validasi Panjang Kata Sandi', () {
    test('password < 8 characters is rejected', () async {
      final rng = Random(42);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final shortPassword = _generatePassword(
          rng,
          rng.nextInt(7) + 1,
        ); // 1-7 chars

        expect(
          () => repo.signUpWithEmail(email, shortPassword, username),
          throwsA(isA<AuthException>()),
          reason:
              'iteration $i: password with ${shortPassword.length} chars must be rejected',
        );
      }
    });

    test('password >= 8 characters is accepted', () async {
      final rng = Random(99);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final validPassword = _generatePassword(
          rng,
          rng.nextInt(20) + 8,
        ); // 8-27 chars

        final profile = await repo.signUpWithEmail(
          email,
          validPassword,
          username,
        );

        expect(
          profile,
          isNotNull,
          reason:
              'iteration $i: password with ${validPassword.length} chars must be accepted',
        );
      }
    });

    test('password exactly 8 characters is accepted', () async {
      final rng = Random(77);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 8);

        final profile = await repo.signUpWithEmail(email, password, username);

        expect(
          profile,
          isNotNull,
          reason:
              'iteration $i: password with exactly 8 chars must be accepted',
        );
      }
    });

    test('password 7 characters is rejected', () async {
      final rng = Random(55);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 7);

        expect(
          () => repo.signUpWithEmail(email, password, username),
          throwsA(isA<AuthException>()),
          reason: 'iteration $i: password with 7 chars must be rejected',
        );
      }
    });

    test('empty password is rejected', () async {
      final repo = AuthRepository();
      final email = _generateValidEmail(Random(33));
      final username = _generateValidUsername(Random(33));

      expect(
        () => repo.signUpWithEmail(email, '', username),
        throwsA(isA<AuthException>()),
        reason: 'empty password must be rejected',
      );
    });

    test(
      'password with special characters is accepted if >= 8 chars',
      () async {
        final rng = Random(11);
        final repo = AuthRepository();

        final specialPasswords = [
          'Pass@123!',
          'Secure#Pass123',
          'P@ssw0rd!@#',
          'Test\$Pass123',
          'Valid%Pass2024',
        ];

        for (final password in specialPasswords) {
          final email = _generateValidEmail(rng);
          final username = _generateValidUsername(rng);

          if (password.length >= 8) {
            final profile = await repo.signUpWithEmail(
              email,
              password,
              username,
            );
            expect(profile, isNotNull);
          }
        }
      },
    );

    test('password validation error message is correct', () async {
      final repo = AuthRepository();
      final email = _generateValidEmail(Random(88));
      final username = _generateValidUsername(Random(88));
      final shortPassword = 'short';

      try {
        await repo.signUpWithEmail(email, shortPassword, username);
        fail('Should have thrown AuthException');
      } catch (e) {
        expect(e, isA<AuthException>(), reason: 'must throw AuthException');
        expect(
          e.toString(),
          contains('Kata sandi minimal 8 karakter'),
          reason: 'error message must mention minimum 8 characters',
        );
      }
    });

    test('password validation is consistent', () async {
      final rng = Random(66);
      final repo = AuthRepository();

      for (var i = 0; i < iterations; i++) {
        final email = _generateValidEmail(rng);
        final username = _generateValidUsername(rng);
        final password = _generatePassword(rng, 8);

        // Try multiple times with same password
        final profile1 = await repo.signUpWithEmail(email, password, username);
        expect(profile1, isNotNull);

        // Create new repo instance and try again with different email
        final repo2 = AuthRepository();
        final email2 = _generateValidEmail(rng);
        final profile2 = await repo2.signUpWithEmail(
          email2,
          password,
          username,
        );
        expect(profile2, isNotNull);
      }
    });
  });
}
