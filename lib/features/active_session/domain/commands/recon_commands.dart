import 'package:nullbyte/features/active_session/domain/terminal_command.dart';
import 'package:nullbyte/shared/models/node_state.dart';

class NmapCommand extends TerminalCommand {
  @override
  String get name => 'nmap';

  @override
  List<String> get aliases => ['nm'];

  @override
  String get description => 'Network exploration tool and security scanner';

  @override
  String get usage => 'nmap [options] <target>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('nmap: missing target\nUsage: $usage');
    }

    final target = args.last;
    await Future.delayed(const Duration(milliseconds: 400));

    final nodes = context.levelDefinition?.topology.nodes ?? [];
    final matchedNodes = nodes.where((n) {
      if (target.endsWith('/24')) {
        final prefix = target
            .replaceAll('/24', '')
            .split('.')
            .take(3)
            .join('.');
        return n.ip.startsWith(prefix);
      }
      return n.ip == target || n.id == target;
    }).toList();

    // M3 L4: internal network hanya bisa di-scan setelah foothold ke jump host
    if (context.levelId == 'm3_l4' && target.contains('10.10.10')) {
      if (!context.isObjectiveCompleted('pivot_discovered')) {
        return TerminalOutput.output(
          'Starting Nmap 7.94 ( https://nmap.org )\nNmap scan report for $target: Host down\nNote: Cannot reach internal network from outside. Gain foothold on pivot host first.\nNmap done: 1 IP address (0 hosts up) scanned in 0.42 seconds',
        );
      }
    }

    for (final node in matchedNodes) {
      context.updateNodeState(node.id, NodeState.discovered);
    }

    if (matchedNodes.isNotEmpty) {
      context.completeObjective('hosts_discovered');
    }

    // M3 L4: granular objective tracking for pivot scenario
    if (context.levelId == 'm3_l4') {
      final discoveredIps = matchedNodes.map((n) => n.ip).toList();
      if (discoveredIps.contains('192.168.100.40')) {
        context.completeObjective('pivot_discovered');
      }
      if (discoveredIps.contains('10.10.10.20')) {
        context.completeObjective('internal_discovered');
      }
    }

    // Jika tidak ada node yang cocok, host tidak reachable
    if (matchedNodes.isEmpty) {
      return TerminalOutput.output(
        'Starting Nmap 7.94 ( https://nmap.org )\nNmap scan report for $target: Host down\nNmap done: 1 IP address (0 hosts up) scanned in 0.42 seconds',
      );
    }

    final ip = _resolveIp(target);
    final scanTarget = matchedNodes.first;
    final ports = scanTarget.openPorts;
    final services = scanTarget.services;

    if (args.contains('-sV') || args.contains('-A') || args.contains('-p') || !target.endsWith('/24')) {
      context.completeObjective('service_fingerprinted');
    }

    final portLines = List.generate(ports.length, (i) {
      final svc = i < services.length ? services[i] : 'unknown';
      return '${ports[i].toString().padLeft(5)}/tcp   open  $svc';
    }).join('\n');

    final hostCount = matchedNodes.isNotEmpty ? matchedNodes.length : 1;
    if (target.endsWith('/24') && matchedNodes.length > 1) {
      final hostReports = matchedNodes
          .map(
            (node) => '''Nmap scan report for ${node.label} (${node.ip})
Host is up (0.0038s latency).''',
          )
          .join('\n\n');
      final clue = _generateClue(context.levelId, matchedNodes, services, args);
      final summary =
          '''Starting Nmap 7.94 ( https://nmap.org )
$hostReports

Nmap done: $hostCount IP addresses ($hostCount hosts up) scanned in 0.42 seconds''';
      if (clue == null) {
        return TerminalOutput.success(summary);
      }
      return TerminalOutput.success('$summary\n\n[tip] $clue');
    }

    final output =
        '''Starting Nmap 7.94 ( https://nmap.org )
Nmap scan report for $target ($ip)
Host is up (0.0042s latency).
PORT     STATE SERVICE
$portLines

Nmap done: $hostCount IP address${hostCount > 1 ? 'es' : ''} ($hostCount host${hostCount > 1 ? 's' : ''} up) scanned in 0.42 seconds''';

    final clue = _generateClue(context.levelId, matchedNodes, services, args);
    if (clue != null) {
      return TerminalOutput.success('$output\n\n[tip] $clue');
    }

    return TerminalOutput.success(output);
  }

  String? _generateClue(
    String levelId,
    List<dynamic> matchedNodes,
    List<String> services,
    List<String> args,
  ) {
    final hasFingerprint = args.contains('-sV') || args.contains('-A');
    final hasHttp = services.any((s) => s.toLowerCase().contains('http'));
    final hasAltHttp = services.any((s) => s.toLowerCase().contains('8080'));
    final hasSsh = services.any((s) => s.toLowerCase().contains('ssh'));
    final hostList = matchedNodes
        .map((node) => node.ip as String)
        .where((ip) => ip != '10.0.0.5')
        .toList();

    switch (levelId) {
      case 'm1_l1':
        if (hostList.isNotEmpty && targetLooksLikeSubnet(args.last)) {
          return 'Beberapa host aktif ditemukan. Lakukan port scan ke target utama 192.168.1.10 dengan perintah: "nmap 192.168.1.10"';
        }
        if (hasHttp) {
          return 'HTTP (port 80) terbuka di 192.168.1.10. Jalankan perintah "curl http://192.168.1.10" untuk melihat halaman web portal.';
        }
      case 'm1_l2':
        if (targetLooksLikeSubnet(args.last)) {
          return 'Host discovery selesai. Scan seluruh port target 192.168.2.11 dengan perintah: "nmap -p- 192.168.2.11"';
        }
        if (hasHttp || hasAltHttp) {
          return 'Service web alternatif ditemukan di port 8080. Coba akses halaman utama service tersebut dengan: "curl http://192.168.2.11:8080"';
        }
      case 'm1_l3':
        if (!hasFingerprint && hasHttp) {
          return 'Service web ditemukan di 172.16.0.10. Jalankan port scan dengan pendeteksian versi: "nmap -sV -p 80,443,8080 172.16.0.10"';
        }
        if (hasFingerprint) {
          return 'Versi Apache/2.4.49 terdeteksi! Apache versi ini memiliki celah path traversal (CVE-2021-41773). Gunakan curl untuk mengakses: "curl http://172.16.0.10/cgi-bin/.%2e/%2e%2e/%2e%2e/flag.txt"';
        }
      case 'm1_l4':
        if (hasHttp) {
          return 'Target File Server (192.168.10.50) terdeteksi. Gunakan "curl http://192.168.10.50:8080" untuk melihat direktori backup.';
        }
      case 'm1_l5':
        if (hasHttp || hasSsh) {
          return 'Data Export Service terdeteksi di 192.168.20.100. Gunakan "curl http://192.168.20.100:8080" untuk mengakses endpoint export.';
        }
      case 'm2_l1':
        if (hasHttp) {
          return 'Web app terlihat aktif. Buka halaman utamanya lalu catat endpoint mana yang layak diuji lebih lanjut.';
        }
      case 'm2_l2':
        if (hasHttp) {
          return 'Perhatikan endpoint yang menerima input pengguna. Uji perilakunya sebelum memakai alat yang lebih otomatis.';
        }
      case 'm2_l3':
        if (hasHttp) {
          return 'Portal login ditemukan. Amati bagaimana input username dan password diproses.';
        }
      case 'm2_l4':
        if (hasHttp) {
          return 'Upload endpoint aktif. Cari kelemahan validasi file, bukan hanya nama filenya.';
        }
      case 'm2_l5':
        if (hasHttp) {
          return 'Saat foothold web sudah ada, pikirkan bagaimana mengubahnya menjadi akses command execution yang stabil.';
        }
      case 'm3_l1':
        if (hasSsh) {
          return 'SSH tersedia. Gunakan foothold yang paling langsung lalu lanjut ke enumerasi dasar sistem.';
        }
      case 'm3_l2':
        if (hasSsh) {
          return 'Masuk dulu, lalu kumpulkan identitas user, grup, dan file sensitif yang bisa dibaca.';
        }
      case 'm3_l3':
        if (hasSsh) {
          return 'Setelah login, cek apakah ada misconfiguration di sudo atau binary berbahaya yang bisa dieksekusi lebih tinggi.';
        }
      case 'm3_l4':
        if (hasSsh) {
          return 'Gunakan host ini sebagai titik pivot sebelum melihat jaringan internal.';
        }
      case 'm3_l5':
        if (hasSsh) {
          return 'Fokus pada jalur escalation yang disediakan sistem. Cari command yang diizinkan untuk naik privilege.';
        }
    }

    return null;
  }

  bool targetLooksLikeSubnet(String target) => target.endsWith('/24');

  String _resolveIp(String target) {
    if (target.contains('.')) return target;
    final hash = target.hashCode.abs() % 254 + 1;
    return '192.168.1.$hash';
  }
}

class PingCommand extends TerminalCommand {
  @override
  String get name => 'ping';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Send ICMP ECHO_REQUEST to network hosts';

  @override
  String get usage => 'ping <target>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('ping: missing target\nUsage: $usage');
    }

    final target = args.last;
    await Future.delayed(const Duration(milliseconds: 200));

    final ip = _resolveIp(target);
    final output =
        '''PING $target ($ip): 56 data bytes
64 bytes from $ip: icmp_seq=1 ttl=64 time=0.42 ms
64 bytes from $ip: icmp_seq=2 ttl=64 time=0.38 ms
64 bytes from $ip: icmp_seq=3 ttl=64 time=0.51 ms
64 bytes from $ip: icmp_seq=4 ttl=64 time=0.44 ms

--- $target ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3003ms
rtt min/avg/max/mdev = 0.380/0.437/0.510/0.048 ms''';

    // M1: ping confirms host is alive, guide toward nmap
    final levelId = context.levelId;
    if (levelId.startsWith('m1')) {
      return TerminalOutput.output(
        '$output\n\n[tip] Host aktif. Lanjutkan dengan nmap untuk menemukan port dan service yang terbuka.',
      );
    }

    return TerminalOutput.output(output);
  }

  String _resolveIp(String target) {
    if (target.contains('.')) return target;
    final hash = target.hashCode.abs() % 254 + 1;
    return '192.168.1.$hash';
  }
}

class NetstatCommand extends TerminalCommand {
  @override
  String get name => 'netstat';

  @override
  List<String> get aliases => ['ss'];

  @override
  String get description =>
      'Print network connections, routing tables, interface statistics';

  @override
  String get usage => 'netstat [options]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 150));

    const output = '''Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State
tcp        0      0 192.168.1.10:22         192.168.1.1:54321       ESTABLISHED
tcp        0      0 192.168.1.10:80         10.0.0.5:43210          TIME_WAIT
tcp        0      0 192.168.1.10:443        10.0.0.7:51234          ESTABLISHED
tcp        0      0 192.168.1.10:3306       127.0.0.1:52100         ESTABLISHED
tcp6       0      0 :::8080                 :::*                    LISTEN
udp        0      0 0.0.0.0:68             0.0.0.0:*
udp        0      0 0.0.0.0:5353           0.0.0.0:*''';

    // M1: netstat reveals connections, guide toward nmap/curl
    final levelId = context.levelId;
    if (levelId.startsWith('m1')) {
      return TerminalOutput.output(
        '$output\n\n[tip] Koneksi aktif terlihat. Gunakan nmap untuk scan lengkap dan curl untuk memeriksa service web.',
      );
    }
    // M3: netstat shows internal pivot targets
    if (levelId == 'm3_l4') {
      return TerminalOutput.output(
        '$output\n\n[tip] Koneksi internal terdeteksi. Gunakan nmap untuk scan jaringan internal dari host ini.',
      );
    }

    return TerminalOutput.output(output);
  }
}
