import 'package:flutter/foundation.dart';
import 'package:nullbyte/shared/models/level_definition.dart';
import 'package:nullbyte/shared/models/network_topology.dart';
import 'package:nullbyte/shared/models/node_state.dart';

/// Konteks level aktif yang menyimpan state runtime sesi gameplay.
///
/// Extend [ChangeNotifier] agar bisa di-listen oleh Riverpod
/// [ChangeNotifierProvider].
class LevelContext extends ChangeNotifier {
  static const Map<String, String> _levelFlags = {
    'm1_l1': 'nullbyte{m1_l1_host_discovery}',
    'm1_l2': 'nullbyte{m1_l2_port_scan}',
    'm1_l3': 'nullbyte{m1_l3_service_fingerprint}',
    'm1_l4': 'nullbyte{m1_l4_file_discovery}',
    'm1_l5': 'nullbyte{m1_l5_flag_extraction}',
    'm2_l1': 'nullbyte{m2_l1_endpoint_discovery}',
    'm2_l2': 'nullbyte{m2_l2_sql_injection}',
    'm2_l3': 'nullbyte{m2_l3_auth_bypass}',
    'm2_l4': 'nullbyte{m2_l4_file_upload_abuse}',
    'm2_l5': 'nullbyte{m2_l5_webshell_pivot}',
    'm3_l1': 'nullbyte{m3_l1_foothold_access}',
    'm3_l2': 'nullbyte{m3_l2_enumeration_sweep}',
    'm3_l3': 'nullbyte{m3_l3_sudo_misconfig}',
    'm3_l4': 'nullbyte{m3_l4_service_pivot}',
    'm3_l5': 'nullbyte{m3_l5_root_access}',
  };

  String levelId;
  final Map<String, NodeState> nodeStates;
  String currentDirectory;
  String currentUser;
  String currentHost;
  bool hasRootPrivilege;
  final List<String> commandHistory;

  /// Objective yang sudah diselesaikan player dalam sesi ini.
  /// Contoh key: 'hosts_discovered', 'service_fingerprinted',
  /// 'exploit_successful', 'credentials_found'.
  final Set<String> completedObjectives;

  /// Level definition lengkap, tersedia setelah [startLevel] dipanggil.
  LevelDefinition? levelDefinition;

  LevelContext({
    required this.levelId,
    Map<String, NodeState>? nodeStates,
    this.currentDirectory = '/',
    this.currentUser = 'user',
    this.currentHost = 'attacker',
    this.hasRootPrivilege = false,
    List<String>? commandHistory,
    Set<String>? completedObjectives,
    this.levelDefinition,
  }) : nodeStates = nodeStates ?? {},
       commandHistory = commandHistory ?? [],
       completedObjectives = completedObjectives ?? {};

  /// Inisialisasi context dari [LevelDefinition].
  factory LevelContext.fromDefinition(LevelDefinition definition) {
    return LevelContext(levelId: definition.id, levelDefinition: definition);
  }

  void startLevel(LevelDefinition definition) {
    levelId = definition.id;
    levelDefinition = definition;
    currentDirectory = '/';
    currentUser = 'user';
    currentHost = 'attacker';
    hasRootPrivilege = false;
    nodeStates.clear();
    commandHistory.clear();
    completedObjectives.clear();
    notifyListeners();
  }

  void restoreRuntimeState({
    required String currentDirectory,
    required String currentUser,
    required String currentHost,
    required bool hasRootPrivilege,
    required List<String> commandHistory,
    required Map<String, NodeState> nodeStates,
    Set<String>? completedObjectives,
  }) {
    this.currentDirectory = currentDirectory;
    this.currentUser = currentUser;
    this.currentHost = currentHost;
    this.hasRootPrivilege = hasRootPrivilege;
    this.commandHistory
      ..clear()
      ..addAll(commandHistory);
    this.nodeStates
      ..clear()
      ..addAll(nodeStates);
    this.completedObjectives
      ..clear()
      ..addAll(completedObjectives ?? {});
    notifyListeners();
  }

  /// Update state sebuah node dan notify listeners.
  void updateNodeState(String nodeId, NodeState state) {
    nodeStates[nodeId] = state;
    notifyListeners();
  }

  /// Tambah command ke history dan notify listeners.
  void addToHistory(String command) {
    if (command.trim().isNotEmpty) {
      commandHistory.add(command);
      notifyListeners();
    }
  }

  /// Return [NetworkNode] berdasarkan [nodeId] dari topology level.
  /// Return null jika node tidak ditemukan atau levelDefinition belum di-set.
  NetworkNode? getNodeById(String nodeId) {
    return levelDefinition?.topology.nodes
        .where((n) => n.id == nodeId)
        .firstOrNull;
  }

  /// Simulasi konten file berdasarkan [path] dan level aktif.
  ///
  /// Return string konten file, atau pesan error jika file tidak ditemukan.
  String getFileContent(String path) {
    final normalizedPath = _normalizePath(path);

    // File-file umum yang tersedia di semua level
    final commonFiles = _commonFileContents();
    if (commonFiles.containsKey(normalizedPath)) {
      return commonFiles[normalizedPath]!;
    }

    // File spesifik level berdasarkan levelId
    final levelFiles = _levelFileContents();
    if (levelFiles.containsKey(normalizedPath)) {
      return levelFiles[normalizedPath]!;
    }

    return 'cat: $path: No such file or directory';
  }

  /// Daftar isi direktori berdasarkan [dirPath] dan level aktif.
  ///
  /// Mengembalikan daftar nama file/subdirektori yang tersedia di level ini.
  /// Direktori yang tidak punya konten mengembalikan list kosong.
  List<String> getDirectoryListing(String dirPath) {
    final normalizedDir = _normalizePath(dirPath);
    if (!normalizedDir.endsWith('/')) {
      // ignore: unnecessary_brace_in_string_interps
      final withSlash = '$normalizedDir/';
      return _buildDirListing(withSlash);
    }
    return _buildDirListing('$normalizedDir/');
  }

  List<String> _buildDirListing(String dirWithSlash) {
    final allFilePaths = <String>{}
      ..addAll(_commonFileContents().keys)
      ..addAll(_levelFileContents().keys);

    final entries = <String>{};
    for (final filePath in allFilePaths) {
      if (!filePath.startsWith(dirWithSlash)) continue;
      final relative = filePath.substring(dirWithSlash.length);
      final slashIdx = relative.indexOf('/');
      if (slashIdx >= 0) {
        // Subdirektori
        entries.add(relative.substring(0, slashIdx));
      } else if (relative.isNotEmpty) {
        // File
        entries.add(relative);
      }
    }

    // Selalu sertakan subdirektori umum yang selalu ada
    final commonSubdirs = _commonSubdirs(dirWithSlash);
    entries.addAll(commonSubdirs);

    return entries.toList()..sort();
  }

  /// Subdirektori yang selalu ada terlepas dari file yang terdaftar.
  List<String> _commonSubdirs(String dirWithSlash) {
    const structure = <String, List<String>>{
      '/': ['bin', 'etc', 'home', 'tmp', 'var', 'usr', 'root', 'opt'],
      '/etc/': ['ssh', 'cron.d'],
      '/home/': ['user', 'operator', 'admin', 'backup'],
      '/var/': ['log', 'www', 'backup', 'export'],
      '/var/www/': ['html'],
      '/var/www/html/': ['admin', 'uploads', 'secret', 'export', 'recon'],
      '/opt/': ['scripts'],
    };
    return structure[dirWithSlash] ?? [];
  }

  /// Mengembalikan semua file path yang tersedia di level ini (common + level-specific).
  List<String> getLevelFileKeys() {
    return <String>[
      ..._commonFileContents().keys,
      ..._levelFileContents().keys,
    ];
  }

  /// Cek apakah host IP ada dalam topology level ini.
  bool isHostInTopology(String host) {
    final nodes = levelDefinition?.topology.nodes ?? [];
    return nodes.any((node) => node.ip == host);
  }

  /// Cek apakah host sudah di-discover (node state = discovered/scanning/exploited/secured).
  bool isHostDiscovered(String host) {
    final nodes = levelDefinition?.topology.nodes ?? [];
    for (final node in nodes) {
      if (node.ip == host) {
        final state = nodeStates[node.id];
        return state == NodeState.discovered ||
            state == NodeState.scanning ||
            state == NodeState.exploited ||
            state == NodeState.secured;
      }
    }
    // Host tidak ada di topology — izinkan (tidak bisa divalidasi)
    return true;
  }

  /// Tandai host sebagai exploited berdasarkan IP address.
  void markHostExploited(String host) {
    final nodes = levelDefinition?.topology.nodes ?? [];
    for (final node in nodes) {
      if (node.ip == host) {
        updateNodeState(node.id, NodeState.exploited);
        break;
      }
    }
  }

  /// Tandai objective sebagai selesai dan notify listeners.
  void completeObjective(String objectiveId) {
    if (completedObjectives.add(objectiveId)) {
      notifyListeners();
    }
  }

  /// Cek apakah objective sudah selesai.
  bool isObjectiveCompleted(String objectiveId) =>
      completedObjectives.contains(objectiveId);

  /// Cek apakah player sudah punya akses ke flag berdasarkan objective state.
  /// Gating berbeda per level, mengikuti tema kill chain masing-masing:
  /// - M1 (Recon): hosts_discovered cukup
  /// - M2 L1 (Endpoint Discovery): endpoint_discovered cukup (recon level)
  /// - M2 L2-L5 (Web Exploit): exploit_successful
  /// - M3 L1-L2 (Foothold/Enum): exploit_successful (user-level flag)
  /// - M3 L3-L5 (Priv Esc): exploit_successful + root
  bool get isFlagAccessible {
    // Mission 1: recon levels — butuh hosts_discovered dan service_fingerprinted
    if (levelId.startsWith('m1')) {
      return completedObjectives.contains('hosts_discovered') &&
          completedObjectives.contains('service_fingerprinted');
    }
    // M2 L1: endpoint discovery — recon level, bukan exploit
    if (levelId == 'm2_l1') {
      return completedObjectives.contains('endpoint_discovered');
    }
    // M2 L2-L5: web exploitation — exploit_successful
    if (levelId.startsWith('m2')) {
      return completedObjectives.contains('exploit_successful');
    }
    // M3 L1-L2: foothold, enumeration — user-level flag
    if (levelId == 'm3_l1' || levelId == 'm3_l2') {
      return completedObjectives.contains('exploit_successful');
    }
    // M3 L4: pivot — perlu internal_discovered + exploit_successful
    if (levelId == 'm3_l4') {
      return completedObjectives.contains('exploit_successful') &&
          completedObjectives.contains('internal_discovered');
    }
    // M3 L3, L5: privilege escalation — butuh root
    if (levelId.startsWith('m3')) {
      return completedObjectives.contains('exploit_successful') &&
          hasRootPrivilege;
    }
    return completedObjectives.contains('exploit_successful');
  }

  String get currentFlag => _levelFlags[levelId] ?? 'nullbyte{unknown_level}';

  // ── Private helpers ────────────────────────────────────────────────────────

  String _normalizePath(String path) {
    if (path.startsWith('/')) return path;
    // Resolve relative path dari currentDirectory
    final base = currentDirectory.endsWith('/')
        ? currentDirectory
        : '$currentDirectory/';
    return '$base$path';
  }

  Map<String, String> _commonFileContents() {
    return {
      '/etc/passwd': _etcPasswd,
      '/etc/hostname': 'target-server\n',
      '/etc/os-release':
          'NAME="Ubuntu"\nVERSION="20.04.6 LTS (Focal Fossa)"\nID=ubuntu\n',
      '/proc/version':
          'Linux version 5.4.0-182-generic (buildd@lcy02-amd64-059)\n',
      '/home/user/.bash_history': _bashHistory,
      '/home/operator/.bash_history': _bashHistory,
      '/var/log/auth.log': _authLog,
      '/tmp/readme.txt': 'Temporary files. Nothing to see here.\n',
    };
  }

  Map<String, String> _levelFileContents() {
    final levelId = this.levelId;
    final flagContent = isFlagAccessible
        ? '$currentFlag\n'
        : 'Access denied: insufficient privileges\n';
    final rootFlag = hasRootPrivilege && isFlagAccessible
        ? '$currentFlag\n'
        : 'Permission denied\n';

    // ── Base files yang selalu ada ──────────────────────────────────────────
    final files = <String, String>{
      '/var/www/html/config.php': _phpConfigContent(levelId),
      '/home/admin/notes.txt': _adminNotes(levelId),
    };

    // ── Level-specific files ────────────────────────────────────────────────
    switch (levelId) {
      // ── Mission 1: Network Recon ──────────────────────────────────────────
      case 'm1_l1':
        files.addAll({
          '/var/www/html/index.html': '''<!DOCTYPE html>
<html><body><h1>Corp Intranet</h1>
<p>Welcome to the corporate internal portal.</p>
<!-- TODO: remove /flag.txt before production deploy -->
</body></html>''',
          '/var/www/html/flag.txt': flagContent,
        });
        break;

      case 'm1_l2':
        files.addAll({
          '/var/www/html/index.html':
              '<html><body><h1>Workstation B</h1><p>Dev environment</p></body></html>',
          '/var/www/html:8080/index.html':
              '<html><body><h1>Hidden Service</h1><a href="/secret">Secret</a></body></html>',
          '/var/www/html:8080/secret/index.html':
              '<html><body><h1>Restricted Area</h1><!-- flag in flag.txt --></body></html>',
          '/var/www/html:8080/secret/flag.txt': flagContent,
        });
        break;

      case 'm1_l3':
        files.addAll({
          '/var/www/html/index.html': '''<html><body>
<h1>Apache/2.4.49 Test Server</h1>
<p>Default installation — DO NOT EXPOSE TO INTERNET</p>
<!-- Server version visible in headers. Check CVE-2021-41773 -->
</body></html>''',
          '/var/www/html/flag.txt': flagContent,
        });
        break;

      case 'm1_l4':
        files.addAll({
          '/var/www/html/index.html':
              '<html><body><h1>File Server</h1><p>Backup repository</p></body></html>',
          '/var/backup/notes.txt': '''Backup Schedule:
- Full backup: Sundays 02:00
- Incremental: Daily 04:00
- Flag backup stored in: /var/backup/flag.txt
WARNING: backup directory is world-readable!
''',
          '/var/backup/flag.txt': flagContent,
        });
        break;

      case 'm1_l5':
        files.addAll({
          '/var/www/html/index.html':
              '<html><body><h1>Data Export Service</h1><p>Automated export pipeline</p></body></html>',
          '/var/export/manifest.csv': '''id,type,status,location
1,logs,archived,/var/export/logs/
2,config,active,/var/export/config/
3,flag,restricted,/var/export/flag.txt
''',
          '/var/export/flag.txt': flagContent,
        });
        break;

      // ── Mission 2: Web Exploitation ───────────────────────────────────────
      case 'm2_l1':
        files.addAll({
          '/var/www/html/index.html': '''<!DOCTYPE html>
<html><body>
<h1>NULLBYTE Demo App</h1>
<a href="/search?q=test">Search</a>
<a href="/login">Login</a>
<!-- recon-note: /recon/flag.txt -->
</body></html>''',
          '/var/www/html/recon/flag.txt': flagContent,
        });
        break;

      case 'm2_l2':
        files.addAll({
          '/var/www/html/index.html':
              '<html><body><h1>Search Gateway</h1><form action="/search"><input name="q"><button>Search</button></form></body></html>',
          '/var/www/html/search.php': '''<?php
// Vulnerable search endpoint
\$q = \$_GET['q'] ?? '';
\$sql = "SELECT * FROM products WHERE name LIKE '%\$q%'";
// WARNING: direct string interpolation = SQL injection!
\$result = mysqli_query(\$conn, \$sql);
?>''',
          '/var/www/html/flag.txt': flagContent,
        });
        break;

      case 'm2_l3':
        files.addAll({
          '/var/www/html/index.html':
              '<html><body><h1>Login Portal</h1><p>Admin access required</p></body></html>',
          '/var/www/html/login.php': '''<?php
\$user = \$_POST['username'] ?? '';
\$pass = \$_POST['password'] ?? '';
// VULNERABLE: no parameterized queries
\$sql = "SELECT * FROM users WHERE username='\$user' AND password='\$pass'";
?>''',
          '/var/www/html/admin/index.php':
              '<?php session_start(); if(!isset(\$_SESSION["admin"])){header("Location: /login");} ?>\n<h1>Admin Panel</h1>',
          '/var/www/html/admin/flag': flagContent,
        });
        break;

      case 'm2_l4':
        files.addAll({
          '/var/www/html/index.html':
              '<html><body><h1>Upload Portal</h1><p>Share your files</p></body></html>',
          '/var/www/html/upload.php': '''<?php
\$target = "/var/www/html/uploads/" . basename(\$_FILES["file"]["name"]);
// VULNERABLE: only checks MIME type, not extension
if (strpos(\$_FILES["file"]["type"], "image/") === 0) {
  move_uploaded_file(\$_FILES["file"]["tmp_name"], \$target);
}
?>''',
          '/var/www/html/flag.txt': flagContent,
        });
        break;

      case 'm2_l5':
        files.addAll({
          '/var/www/html/index.html':
              '<html><body><h1>Production Server</h1><p>All systems nominal</p></body></html>',
          '/var/www/html/uploads/shell.php':
              '<?php echo "<pre>"; system(\$_GET["cmd"]); echo "</pre>"; ?>',
          '/var/www/html/secret/flag.txt': flagContent,
        });
        break;

      // ── Mission 3: Privilege Escalation ──────────────────────────────────
      case 'm3_l1':
        files.addAll({
          '/home/user/flag.txt': flagContent,
          '/home/user/.ssh/authorized_keys': 'ssh-rsa AAAAB3... user@kali\n',
          '/home/user/.bash_history': '''ssh user@192.168.100.10
cat /etc/passwd
ls -la /home/user/
cat flag.txt
''',
        });
        break;

      case 'm3_l2':
        files.addAll({
          '/home/user/flag.txt': flagContent,
          '/etc/shadow': '''root:\$6\$xyz\$Kjhg...:19200:0:99999:7:::
user:\$6\$abc\$Qwer...:19200:0:99999:7:::
admin:\$6\$def\$Asdf...:19200:0:99999:7:::
''',
          '/home/user/.bash_history': '''whoami
id
cat /etc/passwd
cat /etc/shadow
sudo -l
find / -perm -4000 2>/dev/null
ls -la /opt/scripts/
''',
        });
        break;

      case 'm3_l3':
        files.addAll({
          '/root/flag.txt': rootFlag,
          '/etc/sudoers': '''# /etc/sudoers
root    ALL=(ALL:ALL) ALL
user    ALL=(ALL) NOPASSWD: /usr/bin/find
# WARNING: find with -exec allows shell escape!
''',
          '/opt/scripts/backup.sh': '''#!/bin/bash
# Backup script — runs as root via cron
tar czf /var/backup/full.tar.gz /var/www/html/
# This script is world-writable (misconfiguration!)
''',
          '/home/user/.bash_history': '''ssh user@192.168.100.30
whoami
id
sudo -l
cat /etc/passwd
ls -la /opt/scripts/
''',
        });
        break;

      case 'm3_l4':
        // Flag hanya accessible setelah pivot ke internal host
        final m34FlagAccessible =
            isObjectiveCompleted('internal_discovered') &&
            isObjectiveCompleted('exploit_successful');
        final m34Flag = m34FlagAccessible
            ? flagContent
            : 'Access denied: insufficient privileges\n';
        files.addAll({
          '/home/user/flag.txt': m34Flag,
          '/etc/internal_hosts': '''# Internal network hosts
10.10.10.20  db-server
10.10.10.30  app-server
10.10.10.40  monitoring
''',
          '/home/user/.bash_history': '''ssh user@192.168.100.40
cat /etc/internal_hosts
nmap 10.10.10.20
ssh user@10.10.10.20
''',
        });
        break;

      case 'm3_l5':
        files.addAll({
          '/root/flag.txt': rootFlag,
          '/etc/sudoers': '''# /etc/sudoers
root       ALL=(ALL:ALL) ALL
operator   ALL=(ALL) NOPASSWD: /usr/bin/find, /usr/bin/vim
# DANGER: vim can escape to shell (:!bash)
# DANGER: find -exec can spawn shell
''',
          '/home/operator/.bash_history': '''ssh operator@192.168.120.1
whoami
id
sudo -l
cat /etc/sudoers
ls -la /home/operator/
''',
          '/home/operator/flag.txt': flagContent,
        });
        break;
    }

    return files;
  }

  static const String _etcPasswd = '''root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
user:x:1000:1000:User,,,:/home/user:/bin/bash
admin:x:1001:1001:Admin,,,:/home/admin:/bin/bash
''';

  static const String _bashHistory = '''ls -la
cat /etc/passwd
whoami
id
pwd
''';

  static const String _authLog =
      '''Jan 15 10:23:01 target sshd[1234]: Failed password for root from UNKNOWN port 22 ssh2
Jan 15 10:23:05 target sshd[1234]: Failed password for root from UNKNOWN port 22 ssh2
Jan 15 10:23:10 target sshd[1235]: Accepted password for user from UNKNOWN port 22 ssh2
Jan 15 10:24:00 target sudo[1236]: user : TTY=pts/0 ; PWD=/home/user ; USER=root ; COMMAND=/bin/bash
''';

  String _phpConfigContent(String levelId) => '''<?php
// Database configuration
define('DB_HOST', 'localhost');
define('DB_USER', 'webapp');
define('DB_PASS', '[REDACTED]');
define('DB_NAME', 'ctf_db');
?>
''';

  String _adminNotes(String levelId) =>
      '''Remember to change default credentials!
Check cron schedule for automated tasks.
Review script permissions regularly.
''';
}
