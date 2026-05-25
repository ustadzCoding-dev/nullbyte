import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/save/data/hive_repository.dart';

/// Provides a singleton [HiveRepository] instance for the app.
final hiveRepositoryProvider = Provider<HiveRepository>((ref) {
  return HiveRepository();
});
