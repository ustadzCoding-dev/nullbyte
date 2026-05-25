import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/auth/data/auth_repository.dart';
import 'package:nullbyte/shared/models/player_profile.dart';

/// Provider untuk [AuthRepository] — singleton selama app hidup.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repo = AuthRepository();
  ref.onDispose(() {});
  return repo;
});

/// StateNotifier untuk auth state (local-only, tanpa Firebase stream).
class AuthNotifier extends StateNotifier<PlayerProfile?> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(_repo.getCurrentUser());

  Future<void> signUpWithEmail(
    String email,
    String password,
    String username,
  ) async {
    final profile = await _repo.signUpWithEmail(email, password, username);
    state = profile;
  }

  Future<void> signInWithEmail(String email, String password) async {
    final profile = await _repo.signInWithEmail(email, password);
    state = profile;
  }

  Future<void> signInAsGuest() async {
    final profile = await _repo.signInAsGuest();
    state = profile;
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = null;
  }

  Future<void> updateUsername(String newUsername) async {
    await _repo.updateUsername(newUsername);
    state = _repo.getCurrentUser();
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    await _repo.updatePassword(oldPassword, newPassword);
  }

  Future<void> applyProgressStats({
    required int totalScore,
    required int level,
    required int xp,
  }) async {
    state = await _repo.updateProgressStats(
          totalScore: totalScore,
          level: level,
          xp: xp,
        ) ??
        state;
  }

  void refreshCurrentUser() {
    state = _repo.getCurrentUser();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, PlayerProfile?>((ref) {
      return AuthNotifier(ref.read(authRepositoryProvider));
    });

/// Convenience provider — current user profile or null.
final currentUserProvider = Provider<PlayerProfile?>((ref) {
  return ref.watch(authNotifierProvider);
});

/// Provider boolean — true jika user sudah terautentikasi.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
