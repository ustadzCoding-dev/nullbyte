import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'performance_manager.dart';

final performanceManagerProvider = Provider<PerformanceManager>((ref) {
  final manager = PerformanceManager()..init();
  ref.onDispose(manager.dispose);
  return manager;
});

/// Provider untuk status animasi disabled (dari settings atau auto-detect).
final animationsDisabledProvider = StateProvider<bool>((ref) => false);
