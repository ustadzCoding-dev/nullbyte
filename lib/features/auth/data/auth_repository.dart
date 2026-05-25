import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nullbyte/core/constants/hive_boxes.dart';
import 'package:nullbyte/shared/models/player_profile.dart';

/// Exception khusus untuk error autentikasi dengan pesan yang user-friendly.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Local-only auth repository menggunakan Hive.
/// Firebase dapat ditambahkan nanti sebagai backend opsional.
class AuthRepository {
  static const _profileKey = 'current_profile';
  static const _emailKey = 'registered_email';
  static const _passwordKey = 'registered_password';

  Box<dynamic> get _box => Hive.box<dynamic>(HiveBoxes.settings);

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<PlayerProfile> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    _validatePassword(password);

    // Cek apakah email sudah terdaftar
    final existingEmail = _box.get(_emailKey) as String?;
    if (existingEmail != null && existingEmail == email) {
      throw const AuthException('Email sudah digunakan');
    }

    final existingProfile = getCurrentUser();
    final isGuestUpgrade = existingProfile?.isGuest ?? false;

    final profile = isGuestUpgrade
        ? existingProfile!.copyWith(
            username: username.trim(),
            email: email,
            isGuest: false,
            lastSyncAt: DateTime.now(),
          )
        : _createProfile(
            id: _generateId(),
            username: username,
            email: email,
            isGuest: false,
          );

    await _box.put(_emailKey, email);
    await _box.put(_passwordKey, password);
    await _box.put(_profileKey, profile.toJson());
    _currentProfile = profile;
    _authController.add(profile);
    return profile;
  }

  Future<PlayerProfile> signInWithEmail(String email, String password) async {
    final storedEmail = _box.get(_emailKey) as String?;
    final storedPassword = _box.get(_passwordKey) as String?;

    if (storedEmail == null || storedEmail != email) {
      throw const AuthException('Akun tidak ditemukan');
    }
    if (storedPassword != password) {
      throw const AuthException('Email atau kata sandi salah');
    }

    final savedJson = _box.get(_profileKey);
    final profile = savedJson != null
        ? PlayerProfile.fromJson(Map<String, dynamic>.from(savedJson as Map))
        : _createProfile(
            id: _generateId(),
            username: email.split('@').first,
            email: email,
            isGuest: false,
          );

    _currentProfile = profile;
    _authController.add(profile);
    return profile;
  }

  Future<PlayerProfile> signInAsGuest() async {
    final profile = _createProfile(
      id: 'guest_${_generateId()}',
      username: 'Ghost_${_generateId().substring(0, 6).toUpperCase()}',
      email: null,
      isGuest: true,
    );
    await _box.put(_profileKey, profile.toJson());
    _currentProfile = profile;
    _authController.add(profile);
    return profile;
  }

  Future<void> updateUsername(String newUsername) async {
    if (newUsername.trim().isEmpty) {
      throw const AuthException('Username tidak boleh kosong');
    }
    final current = _currentProfile;
    if (current == null) throw const AuthException('Tidak ada sesi aktif');

    final updated = PlayerProfile(
      id: current.id,
      username: newUsername.trim(),
      email: current.email,
      isGuest: current.isGuest,
      totalScore: current.totalScore,
      level: current.level,
      xp: current.xp,
      createdAt: current.createdAt,
      lastSyncAt: DateTime.now(),
    );
    await _box.put(_profileKey, updated.toJson());
    _currentProfile = updated;
    _authController.add(updated);
    return;
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final storedPassword = _box.get(_passwordKey) as String?;
    if (storedPassword != oldPassword) {
      throw const AuthException('Kata sandi lama tidak sesuai');
    }
    _validatePassword(newPassword);
    await _box.put(_passwordKey, newPassword);
  }

  Future<void> signOut() async {
    await _box.delete(_profileKey);
    _currentProfile = null;
    _authController.add(null);
  }

  PlayerProfile? getCurrentUser() {
    if (_currentProfile != null) return _currentProfile;

    final savedJson = _box.get(_profileKey);
    if (savedJson is Map) {
      _currentProfile = PlayerProfile.fromJson(
        Map<String, dynamic>.from(savedJson),
      );
    }
    return _currentProfile;
  }

  Stream<PlayerProfile?> get authStateChanges => _authController.stream;

  Future<PlayerProfile?> updateProgressStats({
    required int totalScore,
    required int level,
    required int xp,
  }) async {
    final current = getCurrentUser();
    if (current == null) return null;

    final updated = current.copyWith(
      totalScore: totalScore,
      level: level,
      xp: xp,
      lastSyncAt: DateTime.now(),
    );

    await _box.put(_profileKey, updated.toJson());
    _currentProfile = updated;
    _authController.add(updated);
    return updated;
  }

  PlayerProfile? _currentProfile;
  // BUG-03 FIX: ganti polling stream dengan StreamController yang proper
  final _authController = StreamController<PlayerProfile?>.broadcast();

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw const AuthException('Kata sandi minimal 8 karakter');
    }
  }

  PlayerProfile _createProfile({
    required String id,
    required String username,
    String? email,
    required bool isGuest,
  }) {
    final now = DateTime.now();
    return PlayerProfile(
      id: id,
      username: username,
      email: email,
      isGuest: isGuest,
      totalScore: 0,
      level: 1,
      xp: 0,
      createdAt: now,
      lastSyncAt: now,
    );
  }

  String _generateId() {
    final rng = Random();
    return List.generate(12, (_) => rng.nextInt(16).toRadixString(16)).join();
  }
}
