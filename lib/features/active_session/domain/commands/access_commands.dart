import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

/// Simulasi ssh untuk membuka foothold user-level pada target.
class SshCommand extends TerminalCommand {
  @override
  String get name => 'ssh';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'OpenSSH remote login client';

  @override
  String get usage => 'ssh <user>@<host>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('ssh: missing destination\nUsage: $usage');
    }

    await Future.delayed(const Duration(milliseconds: 220));

    final destination = args.last;

    // Gate: untuk Mission 1 levels, SSH butuh hosts_discovered dulu
    if (context.levelId.startsWith('m1') &&
        !context.isObjectiveCompleted('hosts_discovered')) {
      return TerminalOutput.error(
        'ssh: connect to host $destination: Connection refused — host not reachable yet. Try scanning first.',
      );
    }
    final atIndex = destination.indexOf('@');
    final user = atIndex > 0 ? destination.substring(0, atIndex) : 'user';
    final host = atIndex > 0 ? destination.substring(atIndex + 1) : destination;

    // Validasi host: harus ada di topology level ini
    if (context.isHostInTopology(host) && !context.isHostDiscovered(host)) {
      return TerminalOutput.error(
        'ssh: connect to host $host port 22: Connection refused\n[tip] Host belum reachable. Scan jaringan dulu dengan nmap.',
      );
    }
    if (!context.isHostInTopology(host)) {
      return TerminalOutput.error(
        'ssh: connect to host $host port 22: No route to host',
      );
    }

    // Level-aware SSH gating:
    // - M3: SSH is the intended foothold → mark exploit_successful, grant user access
    // - M2: SSH is NOT the intended path (web exploitation is) → reject entirely
    // - M1: SSH provides access but exploit_successful not needed (gating uses hosts_discovered)
    final isM3 = context.levelId.startsWith('m3');
    final isM2 = context.levelId.startsWith('m2');

    if (isM2) {
      return TerminalOutput.error(
        'ssh: connect to host $host port 22: Connection refused\n[tip] SSH tidak tersedia di mission ini. Fokus ke service web dan endpoint yang terekspos.',
      );
    }

    context.currentUser = user;
    context.currentDirectory = user == 'root' ? '/root' : '/home/$user';
    context.currentHost = host;
    context.markHostExploited(host);
    // Only grant root via SSH on M3 levels where it's the intended path
    context.hasRootPrivilege = isM3 && user == 'root';

    // Mark exploit_successful only on M3, with special handling for M3 L4:
    // - M3 L4: only trigger when SSH to internal host (10.10.10.20), not jump host
    // - Other M3 levels: SSH to any valid host triggers exploit_successful
    if (isM3) {
      if (context.levelId == 'm3_l4') {
        if (host == '10.10.10.20') {
          context.completeObjective('exploit_successful');
        }
      } else {
        context.completeObjective('exploit_successful');
      }
    }

    // Clue: untuk Mission 3, arahkan ke enumerasi atau privilege escalation
    String? clue;
    if (context.levelId.startsWith('m3') && user != 'root') {
      if (context.levelId == 'm3_l1' || context.levelId == 'm3_l2') {
        clue =
            '[tip] Foothold aktif. Lanjutkan enumerasi dengan whoami, id, cat /etc/passwd, dan cari file flag.';
      } else if (context.levelId == 'm3_l3' || context.levelId == 'm3_l5') {
        clue =
            '[tip] Cek permission sudo dengan sudo -l untuk menemukan jalur escalation.';
      } else if (context.levelId == 'm3_l4') {
        if (host != '10.10.10.20') {
          clue =
              '[tip] Foothold ke jump host aktif. Scan jaringan internal dengan nmap untuk menemukan node tersembunyi.';
        } else {
          clue =
              '[tip] Pivot berhasil. Anda sekarang di internal host. Cari file flag di sini.';
        }
      }
    }

    final output =
        'Connected to $host as $user\n$user@$host:${context.currentDirectory}${user == 'root' ? '#' : '\$'}';
    return TerminalOutput.success(clue != null ? '$output\n$clue' : output);
  }
}

/// Simulasi exit/disconnect — kembali ke attacker host.
class ExitCommand extends TerminalCommand {
  @override
  String get name => 'exit';

  @override
  List<String> get aliases => ['logout', 'disconnect'];

  @override
  String get description => 'Disconnect from remote session';

  @override
  String get usage => 'exit';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (context.currentHost == 'attacker') {
      return TerminalOutput.output('logout\nNo active remote session.');
    }

    final previousHost = context.currentHost;
    // BUG-14 FIX: kembalikan user ke identitas attacker yang sesuai level.
    // M3 L5 menggunakan 'operator' sebagai attacker user, bukan 'user'.
    final attackerUser = context.levelId == 'm3_l5' ? 'operator' : 'user';
    context.currentUser = attackerUser;
    context.currentHost = 'attacker';
    context.currentDirectory = '/home/$attackerUser';
    context.hasRootPrivilege = false;

    return TerminalOutput.success(
      'Connection to $previousHost closed.\n$attackerUser@attacker:~\$',
    );
  }
}

/// Simulasi netcat listener sederhana untuk foothold / reverse shell.
class NcCommand extends TerminalCommand {
  @override
  String get name => 'nc';

  @override
  List<String> get aliases => ['netcat'];

  @override
  String get description => 'Arbitrary TCP and UDP connections and listens';

  @override
  String get usage => 'nc -lvnp <port>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('nc: missing arguments\nUsage: $usage');
    }

    await Future.delayed(const Duration(milliseconds: 180));

    final isListener =
        args.contains('-l') ||
        args.any((arg) => arg.contains('l') && arg.startsWith('-'));
    final port = args.lastWhere(
      (arg) => int.tryParse(arg) != null,
      orElse: () => '4444',
    );

    if (isListener) {
      final levelId = context.levelId;
      if (levelId == 'm2_l5') {
        return TerminalOutput.success(
          'listening on [any] $port ...\nconnect to [$port] from (UNKNOWN) [192.168.90.50] 43122\n\n[tip] Listener aktif. Sekarang kirim reverse shell payload melalui webshell yang sudah ada di server.',
        );
      }
      return TerminalOutput.success(
        'listening on [any] $port ...\nconnect to [$port] from (UNKNOWN) [192.168.90.50] 43122',
      );
    }

    final host = args.firstWhere(
      (arg) => !arg.startsWith('-') && int.tryParse(arg) == null,
      orElse: () => '127.0.0.1',
    );

    return TerminalOutput.success(
      'Connection to $host $port port [tcp/*] succeeded!',
    );
  }
}
