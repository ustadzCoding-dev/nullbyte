import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:nullbyte/core/theme/app_theme.dart';
import 'package:nullbyte/game/components/node_component.dart';
import 'package:nullbyte/game/nullbyte_game.dart';
import 'package:nullbyte/shared/models/network_topology.dart';
import 'package:nullbyte/shared/models/node_state.dart';
import 'package:nullbyte/shared/widgets/scanline_overlay.dart';

/// Widget yang meng-embed [NullbyteGame] dalam Flutter widget tree.
/// Bisa di-embed dalam Column (tidak fullscreen).
class NetMapView extends StatefulWidget {
  final NetworkTopology topology;
  final Map<String, NodeState> nodeStates;
  final void Function(NetworkNode node)? onNodeSelected;

  const NetMapView({
    super.key,
    required this.topology,
    this.nodeStates = const {},
    this.onNodeSelected,
  });

  @override
  State<NetMapView> createState() => _NetMapViewState();
}

class _NetMapViewState extends State<NetMapView> {
  late final NullbyteGame _game;
  NetworkNode? _selectedNode;

  @override
  void initState() {
    super.initState();
    _game = NullbyteGame()..onNodeTapped = _handleNodeTapped;
    _loadTopologyWhenReady();
  }

  @override
  void didUpdateWidget(NetMapView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.topology != oldWidget.topology) {
      _loadTopologyWhenReady();
    } else {
      _applyNodeStates();
    }
  }

  void _loadTopologyWhenReady() {
    _game.loadReady.then((_) {
      if (mounted) {
        _game.loadTopology(widget.topology);
        _applyNodeStates();
      }
    });
  }

  void _applyNodeStates() {
    for (final entry in widget.nodeStates.entries) {
      _game.updateNodeState(entry.key, entry.value);
    }
  }

  void _handleNodeTapped(NodeComponent comp) {
    setState(() => _selectedNode = comp.data);
    widget.onNodeSelected?.call(comp.data);
  }

  void _dismissPanel() {
    setState(() => _selectedNode = null);
  }

  @override
  Widget build(BuildContext context) {
    return ScanlineOverlay(
      child: Stack(
        children: [
          GameWidget<NullbyteGame>(game: _game),
          if (_selectedNode != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _NodeInfoPanel(
                node: _selectedNode!,
                nodeState:
                    widget.nodeStates[_selectedNode!.id] ??
                    NodeState.undiscovered,
                onDismiss: _dismissPanel,
              ),
            ),
        ],
      ),
    );
  }
}

/// Info panel yang muncul saat node di-tap.
/// Styling Terminal Brutalism: 0px radius, neon green.
class _NodeInfoPanel extends StatelessWidget {
  final NetworkNode node;
  final NodeState nodeState;
  final VoidCallback onDismiss;

  const _NodeInfoPanel({
    required this.node,
    required this.nodeState,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: AppTheme.primaryContainer, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.label.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.primaryContainer,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _InfoRow(label: 'IP', value: node.ip),
          _InfoRow(
            label: 'STATE',
            value: nodeState.name.toUpperCase(),
            valueColor: _stateColor(nodeState),
          ),
          if (node.openPorts.isNotEmpty)
            _InfoRow(label: 'PORTS', value: node.openPorts.join(', ')),
          if (node.services.isNotEmpty)
            _InfoRow(label: 'SERVICES', value: node.services.join(', ')),
        ],
      ),
    );
  }

  Color _stateColor(NodeState state) {
    switch (state) {
      case NodeState.undiscovered:
        return AppTheme.outlineVariant;
      case NodeState.discovered:
        return AppTheme.primaryContainer;
      case NodeState.scanning:
        return AppTheme.tertiaryContainer;
      case NodeState.exploited:
        return AppTheme.primaryContainer;
      case NodeState.secured:
        return AppTheme.secondaryContainer;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.05,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppTheme.outlineVariant,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 10,
                color: valueColor ?? AppTheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
