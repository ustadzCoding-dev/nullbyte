import 'package:flutter/material.dart';

/// Represents a single node in the network map.
class NetworkNode {
  final String id;
  final String label;
  final String type; // server | router | workstation | firewall
  final String ip;
  final List<int> openPorts;
  final List<String> services;
  final Offset position;

  const NetworkNode({
    required this.id,
    required this.label,
    required this.type,
    required this.ip,
    required this.openPorts,
    required this.services,
    required this.position,
  });

  factory NetworkNode.fromJson(Map<String, dynamic> json) {
    final pos = json['position'] as Map<String, dynamic>?;
    return NetworkNode(
      id: json['id'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      ip: json['ip'] as String,
      openPorts: (json['openPorts'] as List<dynamic>? ?? [])
          .map((e) => e as int)
          .toList(),
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      position: pos != null
          ? Offset((pos['x'] as num).toDouble(), (pos['y'] as num).toDouble())
          : Offset.zero,
    );
  }
}

/// Represents a directed connection between two nodes.
class NetworkConnection {
  final String sourceId;
  final String targetId;

  const NetworkConnection({required this.sourceId, required this.targetId});

  factory NetworkConnection.fromJson(Map<String, dynamic> json) {
    return NetworkConnection(
      sourceId: json['sourceId'] as String,
      targetId: json['targetId'] as String,
    );
  }
}

/// The full network topology for a level.
class NetworkTopology {
  final List<NetworkNode> nodes;
  final List<NetworkConnection> connections;

  const NetworkTopology({required this.nodes, required this.connections});

  factory NetworkTopology.fromJson(Map<String, dynamic> json) {
    return NetworkTopology(
      nodes: (json['nodes'] as List<dynamic>? ?? [])
          .map((e) => NetworkNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      connections: (json['connections'] as List<dynamic>? ?? [])
          .map((e) => NetworkConnection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
