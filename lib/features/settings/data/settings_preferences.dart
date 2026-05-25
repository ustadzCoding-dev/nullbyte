import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';

class SettingsPreferences {
  final double masterGain;
  final double interfaceSfxGain;

  const SettingsPreferences({
    this.masterGain = 0.85,
    this.interfaceSfxGain = 0.4,
  });
}

abstract final class SettingsKeys {
  SettingsKeys._();

  static const masterGain = 'settings_master_gain';
  static const interfaceSfxGain = 'settings_interface_sfx_gain';

  // Backward compatibility for values saved before the V1 cleanup.
  static const legacyUiHaptics = 'settings_ui_haptics';
}

final settingsPreferencesProvider = FutureProvider<SettingsPreferences>((
  ref,
) async {
  final repo = ref.watch(hiveRepositoryProvider);
  final masterGain =
      (await repo.loadSettingsAsync(SettingsKeys.masterGain) as double?) ??
      0.85;
  final interfaceSfxGain =
      (await repo.loadSettingsAsync(SettingsKeys.interfaceSfxGain) as double?) ??
      (await repo.loadSettingsAsync(SettingsKeys.legacyUiHaptics) as double?) ??
      0.4;

  return SettingsPreferences(
    masterGain: masterGain,
    interfaceSfxGain: interfaceSfxGain,
  );
});
