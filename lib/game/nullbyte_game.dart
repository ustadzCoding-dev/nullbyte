import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/game/components/connection_component.dart';
import 'package:nullbyte/game/components/node_component.dart';
import 'package:nullbyte/game/components/scan_particle_component.dart';
import 'package:nullbyte/shared/models/network_topology.dart';
import 'package:nullbyte/shared/models/node_state.dart';

/// Root FlameGame untuk NetworkMap.
/// Mengelola nodes, connections, kamera, dan gesture zoom/pan.
class NullbyteGame extends FlameGame
    with ScaleDetector, PanDetector, TapCallbacks {
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static final Vector2 _viewportSize = Vector2(600, 400);

  List<NetworkNode> nodes = [];
  List<NetworkConnection> connections = [];

  /// Callback saat node di-tap — dihubungkan ke Flutter widget.
  void Function(NodeComponent)? onNodeTapped;

  final Map<String, NodeComponent> _nodeComponents = {};
  final Completer<void> _loadCompleter = Completer<void>();

  /// Future yang selesai saat onLoad() sudah dipanggil.
  Future<void> get loadReady => _loadCompleter.future;

  double _currentZoom = 1.0;
  double _startZoom = 1.0;
  Vector2 _panOffset = Vector2.zero();

  late final CameraComponent _cam;
  late final World _world;

  @override
  Color backgroundColor() => AppTheme.surfaceContainerLowest;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _world = World();
    _cam = CameraComponent.withFixedResolution(
      world: _world,
      width: _viewportSize.x,
      height: _viewportSize.y,
    );
    _cam.viewfinder.zoom = _currentZoom;

    await addAll([_world, _cam]);

    // Sinyal bahwa game sudah siap
    _loadCompleter.complete();
  }

  /// Load topology ke game — buat NodeComponent dan ConnectionComponent.
  void loadTopology(NetworkTopology topology) {
    // Bersihkan komponen lama
    _world.removeAll(_world.children.toList());
    _nodeComponents.clear();
    nodes = topology.nodes;
    connections = topology.connections;

    // Buat node components
    for (final node in nodes) {
      // Node attacker (milik player) selalu discovered dari awal
      final initialState = _isAttackerNode(node)
          ? NodeState.discovered
          : NodeState.undiscovered;
      final comp = NodeComponent(
        data: node,
        state: initialState,
        onTapped: _handleNodeTapped,
      )..position = Vector2(node.position.dx, node.position.dy);
      _nodeComponents[node.id] = comp;
      _world.add(comp);
    }

    // Buat connection components setelah semua node ada
    for (final conn in connections) {
      final src = _nodeComponents[conn.sourceId];
      final tgt = _nodeComponents[conn.targetId];
      if (src != null && tgt != null) {
        _world.add(ConnectionComponent(source: src, target: tgt));
      }
    }

    // Center kamera ke tengah semua node
    _centerCamera();
  }

  /// Update visual state sebuah node berdasarkan ID.
  void updateNodeState(String nodeId, NodeState state) {
    final comp = _nodeComponents[nodeId];
    if (comp == null) return;
    comp.updateState(state);

    // Spawn particle effect saat scanning
    if (state == NodeState.scanning) {
      _world.add(
        ScanParticleComponent(nodeCenter: comp.position + comp.size / 2),
      );
    }

    // Update connection states — aktifkan koneksi ke node yang sudah discovered+
    _updateConnectionStates();
  }

  void _handleNodeTapped(NodeComponent node) {
    onNodeTapped?.call(node);
  }

  /// Node attacker adalah node milik player — selalu visible dari awal.
  bool _isAttackerNode(NetworkNode node) {
    final id = node.id.toLowerCase();
    final label = node.label.toLowerCase();
    final type = node.type.toLowerCase();
    return id.contains('attacker') ||
        label.contains('kali') ||
        label.contains('attacker') ||
        (type == 'workstation' && id == 'node_attacker');
  }

  void _updateConnectionStates() {
    for (final child in _world.children) {
      if (child is ConnectionComponent) {
        final srcState = _nodeComponents[child.source.data.id]?.state;
        final tgtState = _nodeComponents[child.target.data.id]?.state;
        final isActive =
            srcState != null &&
            tgtState != null &&
            srcState != NodeState.undiscovered &&
            tgtState != NodeState.undiscovered;
        child.connectionState = isActive
            ? NodeConnectionState.active
            : NodeConnectionState.inactive;
      }
    }
  }

  void _centerCamera() {
    if (nodes.isEmpty) return;

    double minX = double.infinity, maxX = double.negativeInfinity;
    double minY = double.infinity, maxY = double.negativeInfinity;

    for (final n in nodes) {
      if (n.position.dx < minX) minX = n.position.dx;
      if (n.position.dx > maxX) maxX = n.position.dx;
      if (n.position.dy < minY) minY = n.position.dy;
      if (n.position.dy > maxY) maxY = n.position.dy;
    }

    final cx = (minX + maxX) / 2;
    final cy = (minY + maxY) / 2;

    // Hitung zoom agar semua node muat dalam viewport dengan padding
    const padding = 100.0; // lebih besar karena ada label di bawah node
    final contentW = (maxX - minX) + NodeComponent.nodeSize + padding;
    final contentH =
        (maxY - minY) +
        NodeComponent.nodeSize +
        padding +
        20; // +20 untuk label
    final zoomX = _viewportSize.x / contentW;
    final zoomY = _viewportSize.y / contentH;
    _currentZoom = (zoomX < zoomY ? zoomX : zoomY).clamp(_minZoom, _maxZoom);

    _cam.viewfinder.zoom = _currentZoom;
    _cam.viewfinder.position = Vector2(cx, cy);
    _panOffset = Vector2(cx, cy);
  }

  // ── Gesture Handlers ──────────────────────────────────────────────────────

  @override
  void onScaleStart(ScaleStartInfo info) {
    _startZoom = _currentZoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    final newZoom = (_startZoom * info.scale.global.x).clamp(
      _minZoom,
      _maxZoom,
    );
    _currentZoom = newZoom;
    _cam.viewfinder.zoom = _currentZoom;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final delta = info.delta.global / _currentZoom;
    _panOffset -= delta;
    _cam.viewfinder.position = _panOffset;
  }
}
