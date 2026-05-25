import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Monitors frame rate and manages app lifecycle for adaptive quality.
class PerformanceManager with WidgetsBindingObserver {
  static const int _lowFpsThreshold = 30;
  static const int _sampleWindow = 60; // frames

  bool _animationsDisabled = false;
  bool _isLowPerformanceMode = false;
  final List<Duration> _frameTimes = [];
  Ticker? _ticker;

  // Callbacks
  VoidCallback? onLowPerformanceDetected;
  VoidCallback? onPerformanceRestored;
  VoidCallback? onAppPaused;
  VoidCallback? onAppResumed;

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
  }

  // ── AppLifecycle ──────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onAppPaused?.call();
    } else if (state == AppLifecycleState.resumed) {
      onAppResumed?.call();
    }
  }

  // ── FPS Monitoring ────────────────────────────────────────────────────────

  void startMonitoring(TickerProvider vsync) {
    _ticker?.dispose();
    _ticker = vsync.createTicker(_onTick)..start();
  }

  void stopMonitoring() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _frameTimes.clear();
  }

  Duration _lastElapsed = Duration.zero;

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;
    if (delta.inMilliseconds <= 0) return;

    _frameTimes.add(delta);
    if (_frameTimes.length > _sampleWindow) {
      _frameTimes.removeAt(0);
    }

    if (_frameTimes.length >= _sampleWindow) {
      final avgMs =
          _frameTimes.map((d) => d.inMilliseconds).reduce((a, b) => a + b) /
          _sampleWindow;
      final fps = 1000 / avgMs;

      if (fps < _lowFpsThreshold && !_isLowPerformanceMode) {
        _isLowPerformanceMode = true;
        onLowPerformanceDetected?.call();
      } else if (fps >= _lowFpsThreshold && _isLowPerformanceMode) {
        _isLowPerformanceMode = false;
        onPerformanceRestored?.call();
      }
    }
  }

  // ── Animation Control ─────────────────────────────────────────────────────

  bool get animationsDisabled => _animationsDisabled;
  bool get isLowPerformanceMode => _isLowPerformanceMode;

  void setAnimationsDisabled(bool disabled) {
    _animationsDisabled = disabled;
  }
}
