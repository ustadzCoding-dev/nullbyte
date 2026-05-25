import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/features/save/providers/hive_repository_provider.dart';
import 'package:nullbyte/features/settings/data/settings_preferences.dart';
import 'package:nullbyte/shared/providers/audio_manager.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _masterGain = 0.85;
  double _interfaceSfxGain = 0.4;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await ref.read(settingsPreferencesProvider.future);
    if (!mounted) return;
    setState(() {
      _masterGain = prefs.masterGain;
      _interfaceSfxGain = prefs.interfaceSfxGain;
      _loaded = true;
    });
  }

  Future<void> _saveSettings() async {
    final repo = ref.read(hiveRepositoryProvider);
    await repo.saveSettings(SettingsKeys.masterGain, _masterGain);
    await repo.saveSettings(SettingsKeys.interfaceSfxGain, _interfaceSfxGain);
    await repo.saveSettings(SettingsKeys.legacyUiHaptics, _interfaceSfxGain);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '> ACTIVE_AUDIO_SETTINGS_SAVED.OK',
          style: TextStyle(fontFamily: 'JetBrainsMono'),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _updateMasterGain(double value) {
    setState(() => _masterGain = value);
    ref.read(audioManagerProvider).setBgmVolume(value);
  }

  void _updateInterfaceSfx(double value) {
    setState(() => _interfaceSfxGain = value);
    ref.read(audioManagerProvider).setSfxVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceContainerHigh,
          elevation: 0,
          title: const Text(
            'System Configuration',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: AppTheme.onSurface,
            ),
          ),
        ),
        body: _loaded
            ? _buildBody()
            : const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryContainer,
                  strokeWidth: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM CONFIGURATION',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w900,
              fontSize: 32,
              color: AppTheme.primaryContainer,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Konfigurasi global audio engine untuk mengontrol musik latar belakang (BGM) dan efek suara antarmuka (SFX).',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildActiveAudioCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActiveAudioCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.volume_up,
                color: AppTheme.primaryContainer,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'ACTIVE AUDIO CONTROLS',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Perubahan di bawah ini langsung memengaruhi BGM mission dan efek suara interface.',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 10,
              color: AppTheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildSlider(
            label: 'MISSION_MUSIC',
            value: _masterGain,
            onChanged: _updateMasterGain,
          ),
          const SizedBox(height: 20),
          _buildSlider(
            label: 'INTERFACE_SFX',
            value: _interfaceSfxGain,
            onChanged: _updateInterfaceSfx,
          ),
        ],
      ),
    );
  }


  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final pct = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            Text(
              '$pct%',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 18,
                color: AppTheme.primaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 8,
            activeTrackColor: AppTheme.primaryContainer,
            inactiveTrackColor: AppTheme.surfaceContainerHighest,
            thumbColor: AppTheme.primaryContainer,
            thumbShape: const RectangularSliderThumbShape(),
            overlayShape: SliderComponentShape.noOverlay,
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryContainer,
              foregroundColor: AppTheme.onPrimary,
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
            ),
            child: const Text(
              'SAVE_ACTIVE_SETTINGS',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryContainer,
              side: const BorderSide(color: AppTheme.primaryContainer),
              shape: const RoundedRectangleBorder(),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text(
              '> BACK_TO_PROFILE',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RectangularSliderThumbShape extends SliderComponentShape {
  const RectangularSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(16, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = sliderTheme.thumbColor ?? AppTheme.primaryContainer
      ..style = PaintingStyle.fill;
    final rect = Rect.fromCenter(center: center, width: 16, height: 24);
    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = AppTheme.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect.deflate(2), borderPaint);
  }
}

class RectangularSliderTrackShape extends SliderTrackShape {
  const RectangularSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 8;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
      offset.dx,
      trackTop,
      parentBox.size.width,
      trackHeight,
    );
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final inactivePaint = Paint()
      ..color =
          sliderTheme.inactiveTrackColor ?? AppTheme.surfaceContainerHighest;
    context.canvas.drawRect(trackRect, inactivePaint);

    final activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? AppTheme.primaryContainer;
    final activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    context.canvas.drawRect(activeRect, activePaint);
  }
}
