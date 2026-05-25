import 'dart:developer' as dev;

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Singleton provider untuk [AudioManager].
final audioManagerProvider = Provider<AudioManager>((ref) {
  final manager = AudioManager();
  ref.onDispose(manager.dispose);
  return manager;
});

/// Mengelola semua audio game: BGM (loop) dan SFX (one-shot).
///
/// Fitur:
/// - BGM via [FlameAudio.bgm] (auto-loop)
/// - SFX via [FlameAudio.play] (one-shot)
/// - Volume kontrol terpisah untuk BGM dan SFX
/// - Mute global
/// - Auto-pause/resume saat [AppLifecycleState] berubah
/// - Deteksi Android silent mode via [AudioSession] interruption events
class AudioManager with WidgetsBindingObserver {
  static const double _defaultBgmVolume = 0.4;
  static const double _defaultSfxVolume = 1.0;

  double _bgmVolume = _defaultBgmVolume;
  double _sfxVolume = _defaultSfxVolume;
  bool _muted = false;

  String? _currentBgmTrack;
  bool _bgmPaused = false; // true jika di-pause karena lifecycle/interruption

  // Single reusable AudioPlayer for keypress — avoids creating a new player
  // per keystroke. stop() + seek(0) + play() is instant.
  AudioPlayer? _keypressPlayer;
  String? _keypressAsset;
  bool _keypressLoading = false;

  AudioManager() {
    WidgetsBinding.instance.addObserver(this);
    // FlameAudio.audioCache defaults to 'assets/audio/' prefix,
    // but our AppConstants paths already include it — clear to avoid double prefix
    FlameAudio.audioCache.prefix = '';
    _initAudioSession();
  }

  // ── AudioSession (Android silent mode) ────────────────────────────────────

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          // Interruption mulai — pause BGM
          if (event.type == AudioInterruptionType.pause ||
              event.type == AudioInterruptionType.duck) {
            _pauseBgmInternal();
          }
        } else {
          // Interruption selesai — resume BGM jika sebelumnya aktif
          if (event.type == AudioInterruptionType.pause ||
              event.type == AudioInterruptionType.duck) {
            _resumeBgmInternal();
          }
        }
      });
    } catch (e) {
      dev.log(
        '[AudioManager] Failed to init AudioSession: $e',
        name: 'AudioManager',
      );
    }
  }

  // ── AppLifecycle ───────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseBgmInternal();
    } else if (state == AppLifecycleState.resumed) {
      _resumeBgmInternal();
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  void _pauseBgmInternal() {
    if (!_bgmPaused) {
      _bgmPaused = true;
      try {
        FlameAudio.bgm.pause();
      } catch (e) {
        dev.log('[AudioManager] pauseBgm error: $e', name: 'AudioManager');
      }
    }
  }

  void _resumeBgmInternal() {
    if (_bgmPaused && _currentBgmTrack != null && !_muted) {
      _bgmPaused = false;
      try {
        FlameAudio.bgm.resume();
      } catch (e) {
        dev.log('[AudioManager] resumeBgm error: $e', name: 'AudioManager');
      }
    }
  }

  double get _effectiveBgmVolume => _muted ? 0.0 : _bgmVolume;
  double get _effectiveSfxVolume => _muted ? 0.0 : _sfxVolume;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Play BGM dengan loop. Jika track sama sudah berjalan, tidak restart.
  Future<void> playBgm(String trackPath) async {
    try {
      if (_currentBgmTrack == trackPath && FlameAudio.bgm.isPlaying) return;
      _currentBgmTrack = trackPath;
      _bgmPaused = false;
      // Ensure seamless loop — ReleaseMode.loop prevents gap between replays
      FlameAudio.bgm.audioPlayer.setReleaseMode(ReleaseMode.loop);
      await FlameAudio.bgm.play(trackPath, volume: _effectiveBgmVolume);
    } catch (e) {
      dev.log(
        '[AudioManager] playBgm("$trackPath") error: $e',
        name: 'AudioManager',
      );
    }
  }

  /// Stop BGM dan reset track saat ini.
  Future<void> stopBgm() async {
    try {
      _currentBgmTrack = null;
      _bgmPaused = false;
      await FlameAudio.bgm.stop();
    } catch (e) {
      dev.log('[AudioManager] stopBgm error: $e', name: 'AudioManager');
    }
  }

  /// Pause BGM secara manual.
  Future<void> pauseBgm() async {
    _pauseBgmInternal();
  }

  /// Resume BGM secara manual.
  Future<void> resumeBgm() async {
    _resumeBgmInternal();
  }

  /// Play SFX sekali (one-shot).
  Future<void> playSfx(String sfxPath) async {
    if (_muted || _effectiveSfxVolume == 0.0) return;
    try {
      await FlameAudio.play(sfxPath, volume: _effectiveSfxVolume);
    } catch (e) {
      dev.log(
        '[AudioManager] playSfx("$sfxPath") error: $e',
        name: 'AudioManager',
      );
    }
  }

  /// Play keypress SFX using a single reusable AudioPlayer.
  /// stop() + seek(0) + play() is instant — no new player allocation per keystroke.
  /// Result: satu ketikan = satu klik, bunyi sebelumnya dipotong.
  Future<void> playSfxCut(String sfxPath) async {
    if (_muted || _effectiveSfxVolume == 0.0) return;
    try {
      // If same asset is already loaded, just stop-seek-resume (instant)
      if (_keypressPlayer != null && _keypressAsset == sfxPath) {
        await _keypressPlayer!.stop();
        await _keypressPlayer!.seek(Duration.zero);
        await _keypressPlayer!.resume();
        return;
      }
      // Different asset or first play — load into reusable player
      if (_keypressLoading) return; // debounce rapid calls during load
      _keypressLoading = true;
      await _keypressPlayer?.stop();
      _keypressPlayer?.dispose();
      _keypressPlayer = AudioPlayer();
      _keypressAsset = sfxPath;
      _keypressPlayer!.setVolume(_effectiveSfxVolume);
      _keypressPlayer!.setReleaseMode(ReleaseMode.stop);
      
      // Prevent SFX from stealing audio focus and stopping BGM
      _keypressPlayer!.setAudioContext(
        ap.AudioContext(
          android: ap.AudioContextAndroid(
            audioFocus: ap.AndroidAudioFocus.none,
          ),
          iOS: ap.AudioContextIOS(
            category: ap.AVAudioSessionCategory.ambient,
            options: {
              ap.AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      await _keypressPlayer!.play(
        AssetSource(sfxPath.replaceFirst('assets/', '')),
      );
      _keypressLoading = false;
    } catch (e) {
      _keypressLoading = false;
      dev.log(
        '[AudioManager] playSfxCut("$sfxPath") error: $e',
        name: 'AudioManager',
      );
    }
  }

  /// Set volume BGM (0.0 – 1.0).
  void setBgmVolume(double volume) {
    _bgmVolume = volume.clamp(0.0, 1.0);
    if (!_muted) {
      try {
        FlameAudio.bgm.audioPlayer.setVolume(_bgmVolume);
      } catch (e) {
        dev.log('[AudioManager] setBgmVolume error: $e', name: 'AudioManager');
      }
    }
  }

  /// Set volume SFX (0.0 – 1.0).
  void setSfxVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
  }

  /// Mute atau unmute semua audio.
  void setMuted(bool muted) {
    _muted = muted;
    try {
      FlameAudio.bgm.audioPlayer.setVolume(_effectiveBgmVolume);
    } catch (e) {
      dev.log('[AudioManager] setMuted error: $e', name: 'AudioManager');
    }
  }

  /// Bersihkan resources saat provider di-dispose.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _keypressPlayer?.stop();
    _keypressPlayer?.dispose();
    _keypressPlayer = null;
    _keypressAsset = null;
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }
}
