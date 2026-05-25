import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/save/data/firebase_repository.dart';

enum SyncStatus { idle, syncing, done, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final firebaseRepositoryProvider = Provider<FirebaseRepository>((ref) {
  // Remote sync tetap disiapkan sebagai extension point, tetapi nonaktif di V1.
  return FirebaseRepository();
});
