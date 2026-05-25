import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Verifikasi flag dengan membandingkan SHA-256 hash.
/// Pure class — tidak ada side effects.
class FlagVerifier {
  const FlagVerifier();

  /// Verifikasi apakah [input] cocok dengan [flagHash].
  ///
  /// Input di-trim dan di-lowercase sebelum di-hash untuk toleransi typo.
  bool verify(String input, String flagHash) {
    return hashFlag(input) == flagHash.toLowerCase();
  }

  /// Return SHA-256 hex string dari [flag].
  ///
  /// Flag di-trim dan di-lowercase sebelum di-hash.
  String hashFlag(String flag) {
    final normalized = flag.trim().toLowerCase();
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
