import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

/// Simulasi grep — filter output berdasarkan pattern.
class GrepCommand extends TerminalCommand {
  @override
  String get name => 'grep';

  @override
  List<String> get aliases => ['egrep', 'fgrep'];

  @override
  String get description => 'Print lines that match patterns';

  @override
  String get usage => 'grep [options] <pattern> <file>';

  @override
  bool get requiresPrivilege => false;

  static const Map<String, String> _fileContents = {
    '/etc/passwd':
        'root:x:0:0:root:/root:/bin/bash\ndaemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin\nwww-data:x:33:33:www-data:/var/www:/usr/sbin/nologin\nuser:x:1000:1000::/home/user:/bin/bash\nadmin:x:1001:1001::/home/admin:/bin/bash',
    '/var/log/auth.log':
        'Jan 15 03:40:01 nullbyte sshd[1234]: Failed password for root from UNKNOWN port 54321 ssh2\nJan 15 03:40:05 nullbyte sshd[1234]: Failed password for admin from UNKNOWN port 54322 ssh2\nJan 15 03:41:00 nullbyte sshd[1235]: Accepted password for user from UNKNOWN port 54323 ssh2\nJan 15 03:42:00 nullbyte sudo[1236]: user : TTY=pts/0 ; PWD=/home/user ; USER=root ; COMMAND=/bin/bash',
    '/etc/hosts': '127.0.0.1\tlocalhost\n127.0.1.1\tnullbyte\n',
  };

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.length < 2) {
      return TerminalOutput.error(
        'grep: missing pattern or file\nUsage: $usage',
      );
    }

    await Future.delayed(const Duration(milliseconds: 100));

    final ignoreCase = args.contains('-i');
    final invertMatch = args.contains('-v');
    final lineNumbers = args.contains('-n');

    final nonFlagArgs = args.where((a) => !a.startsWith('-')).toList();
    if (nonFlagArgs.length < 2) {
      return TerminalOutput.error(
        'grep: missing pattern or file\nUsage: $usage',
      );
    }

    final pattern = nonFlagArgs[0];
    final file = nonFlagArgs[1];

    final filePath = file.startsWith('/')
        ? file
        : '${context.currentDirectory}/$file';

    // Check LevelContext (dynamic, level-aware) first as authoritative source
    final dynamicContent = context.getFileContent(filePath);
    final content = (!dynamicContent.startsWith('cat:'))
        ? dynamicContent
        : (_fileContents[filePath] ?? _fileContents[file]);

    if (content == null) {
      return TerminalOutput.error('grep: $file: No such file or directory');
    }

    final lines = content.split('\n');
    final results = <String>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final matches = ignoreCase
          ? line.toLowerCase().contains(pattern.toLowerCase())
          : line.contains(pattern);

      if (invertMatch ? !matches : matches) {
        results.add(lineNumbers ? '${i + 1}:$line' : line);
      }
    }

    if (results.isEmpty) {
      return TerminalOutput.output('');
    }

    return TerminalOutput.output(results.join('\n'));
  }
}

/// Simulasi find — cari file.
class FindCommand extends TerminalCommand {
  @override
  String get name => 'find';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Search for files in a directory hierarchy';

  @override
  String get usage => 'find <path> [options]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('find: missing path\nUsage: $usage');
    }

    await Future.delayed(const Duration(milliseconds: 200));

    final nameIdx = args.indexOf('-name');
    final namePattern = nameIdx >= 0 && nameIdx + 1 < args.length
        ? args[nameIdx + 1]
        : null;
    final typeIdx = args.indexOf('-type');
    final typeFilter = typeIdx >= 0 && typeIdx + 1 < args.length
        ? args[typeIdx + 1]
        : null;

    final searchPath = args.first.startsWith('/')
        ? args.first
        : context.currentDirectory;

    // Simulasi hasil pencarian — level-aware via LevelContext
    final levelId = context.levelId;
    final allFiles = <String>[
      // Common files yang aman di semua level
      '/etc/passwd',
      '/etc/hostname',
      '/etc/os-release',
      '/home/user/.bash_history',
      '/home/user/notes.txt',
    ];

    // Tambahkan file dari LevelContext (sudah difilter per level)
    final levelFileKeys = context.getLevelFileKeys();
    for (final key in levelFileKeys) {
      if (!allFiles.contains(key)) allFiles.add(key);
    }

    var results = allFiles.where((f) => f.startsWith(searchPath)).toList();

    if (namePattern != null) {
      final pattern = namePattern.replaceAll('*', '');
      results = results
          .where((f) => f.split('/').last.contains(pattern))
          .toList();
    }

    if (typeFilter == 'f') {
      results = results.where((f) => f.contains('.')).toList();
    } else if (typeFilter == 'd') {
      results = results.where((f) => !f.contains('.')).toList();
    }

    if (results.isEmpty) {
      return TerminalOutput.output('');
    }

    // M1: find shows local files, guide toward network recon
    if (levelId.startsWith('m1')) {
      return TerminalOutput.output(
        '${results.join('\n')}\n\n[tip] File lokal bisa ditemukan, tapi fokus mission ini adalah reconnaissance jaringan. Gunakan nmap dan curl untuk menemukan target.',
      );
    }

    // M3 escalation levels: hint about -exec capability via sudo
    if ((levelId == 'm3_l3' || levelId == 'm3_l5') &&
        context.completedObjectives.contains('exploit_successful') &&
        !context.hasRootPrivilege) {
      return TerminalOutput.output(
        '${results.join('\n')}\n\n[tip] find mendukung flag -exec untuk menjalankan perintah. Jika diizinkan oleh sudo, ini bisa menjadi jalur escalation.',
      );
    }

    return TerminalOutput.output(results.join('\n'));
  }
}

/// Simulasi chmod — ubah permission.
class ChmodCommand extends TerminalCommand {
  @override
  String get name => 'chmod';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Change file mode bits';

  @override
  String get usage => 'chmod <mode> <file>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.length < 2) {
      return TerminalOutput.error('chmod: missing operand\nUsage: $usage');
    }

    await Future.delayed(const Duration(milliseconds: 80));

    final mode = args[0];
    final file = args[1];

    // Validasi mode format
    final isNumeric = RegExp(r'^[0-7]{3,4}$').hasMatch(mode);
    final isSymbolic = RegExp(r'^[ugoa]*[+\-=][rwxXst]+$').hasMatch(mode);

    if (!isNumeric && !isSymbolic) {
      return TerminalOutput.error("chmod: invalid mode: '$mode'");
    }

    // M2 L4: hint about making webshell executable
    if (context.levelId == 'm2_l4' && file.contains('php')) {
      return TerminalOutput.output(
        'chmod: $file: permissions updated to $mode\n\n[tip] Webshell sekarang executable. Akses via curl untuk menjalankan perintah di server.',
      );
    }

    return TerminalOutput.output('chmod: $file: permissions updated to $mode');
  }
}

/// Simulasi sudo — eskalasi privilege.
class SudoCommand extends TerminalCommand {
  static const _sudoPassword = 'P@ssw0rd123';

  @override
  String get name => 'sudo';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Execute a command as another user';

  @override
  String get usage => 'sudo <command>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('sudo: missing command\nUsage: $usage');
    }

    // sudo -l: list privileges
    if (args.first == '-l') {
      await Future.delayed(const Duration(milliseconds: 150));
      final levelId = context.levelId;
      if (levelId == 'm3_l3') {
        return TerminalOutput.output(
          'Matching Defaults entries for user on nullbyte:\n    env_reset, mail_badpass\n\nUser user may run the following commands on nullbyte:\n    (root) NOPASSWD: /usr/bin/find',
        );
      }
      if (levelId == 'm3_l5') {
        return TerminalOutput.output(
          'Matching Defaults entries for operator on nullbyte:\n    env_reset, mail_badpass\n\nUser operator may run the following commands on nullbyte:\n    (root) NOPASSWD: /usr/bin/find, /usr/bin/vim',
        );
      }
      if (levelId == 'm3_l1') {
        return TerminalOutput.output(
          'Matching Defaults entries for user on nullbyte:\n    env_reset, mail_badpass\n\nUser user is not allowed to run sudo on nullbyte.\n\n[tip] Sudo tidak tersedia di level ini. Fokus ke SSH foothold dan enumerasi file flag.',
        );
      }
      if (levelId == 'm3_l2') {
        return TerminalOutput.output(
          'Matching Defaults entries for user on nullbyte:\n    env_reset, mail_badpass\n\nUser user is not allowed to run sudo on nullbyte.\n\n[tip] Sudo tidak tersedia di level ini. Cek /etc/shadow dan cari SUID binary untuk enumerasi lebih lanjut.',
        );
      }
      if (levelId == 'm3_l4') {
        return TerminalOutput.output(
          'Matching Defaults entries for user on nullbyte:\n    env_reset, mail_badpass\n\nUser user is not allowed to run sudo on nullbyte.\n\n[tip] Sudo tidak tersedia di level ini. Gunakan host ini sebagai pivot — scan jaringan internal dengan nmap.',
        );
      }
      return TerminalOutput.output(
        'Matching Defaults entries for user on nullbyte:\n    env_reset, mail_badpass\n\nUser user is not allowed to run sudo on nullbyte.',
      );
    }

    // sudo find -exec: M3 L3/L5 escalation vector (NOPASSWD: /usr/bin/find)
    if (args.first == 'find' && args.contains('-exec')) {
      await Future.delayed(const Duration(milliseconds: 200));
      final levelId = context.levelId;
      if (levelId == 'm3_l3' || levelId == 'm3_l5') {
        context.hasRootPrivilege = true;
        context.currentUser = 'root';
        context.currentDirectory = '/root';
        context.completeObjective('exploit_successful');
        context.markHostExploited(context.currentHost);
        return TerminalOutput.success(
          '[sudo] running as root: find / -exec bash \\;\nbash-5.1# \n\n[tip] find -exec berhasil spawn shell sebagai root. Baca flag dengan: cat /root/flag.txt',
        );
      }
      return TerminalOutput.error(
        '[sudo] Sorry, user is not allowed to execute sudo on this target.',
      );
    }

    // sudo vim: M3 L5 escalation vector (NOPASSWD: /usr/bin/vim)
    if (args.first == 'vim') {
      await Future.delayed(const Duration(milliseconds: 200));
      if (context.levelId == 'm3_l5') {
        context.hasRootPrivilege = true;
        context.currentUser = 'root';
        context.currentDirectory = '/root';
        context.completeObjective('exploit_successful');
        context.markHostExploited(context.currentHost);
        return TerminalOutput.success(
          '[sudo] running as root: vim\nVim shell escape: :!bash\nbash-5.1# \n\n[tip] Vim shell escape berhasil. Baca flag dengan: cat /root/flag.txt',
        );
      }
      return TerminalOutput.error(
        '[sudo] Sorry, user is not allowed to execute sudo on this target.',
      );
    }

    // sudo su atau sudo -i: switch ke root (only on sudo escalation levels)
    if (args.first == 'su' || args.first == '-i' || args.first == '-s') {
      await Future.delayed(const Duration(milliseconds: 200));
      final isSudoEscalationLevel =
          context.levelId == 'm3_l3' || context.levelId == 'm3_l5';
      if (!isSudoEscalationLevel) {
        return TerminalOutput.error(
          '[sudo] Sorry, user is not allowed to execute sudo on this target.\n[tip] Sudo bukan jalur yang dimaksud di level ini. Fokus ke vektor yang sesuai dengan objective.',
        );
      }
      context.hasRootPrivilege = true;
      context.currentUser = 'root';
      context.currentDirectory = '/root';
      context.completeObjective('exploit_successful');
      context.markHostExploited(context.currentHost);
      return TerminalOutput.success(
        'root@${context.currentHost}:/# \n\n[tip] Root access obtained. Read the flag with: cat /root/flag.txt',
      );
    }

    // Simulasi password prompt untuk command lain
    await Future.delayed(const Duration(milliseconds: 300));

    // Dalam simulasi, kita langsung grant privilege jika ada password di args
    final passwordIdx = args.indexOf('-p');
    if (passwordIdx >= 0 && passwordIdx + 1 < args.length) {
      final password = args[passwordIdx + 1];
      if (password == _sudoPassword) {
        context.hasRootPrivilege = true;
        context.currentUser = 'root';
        context.currentDirectory = '/root';
        return TerminalOutput.success('[sudo] privilege granted');
      } else {
        return TerminalOutput.error(
          '[sudo] incorrect password attempt\nsudo: 1 incorrect password attempt',
        );
      }
    }

    // Level-aware sudo gating:
    // - M3 L3/L5: sudo is the intended privilege escalation path → grant root
    // - M3 L1/L2/L4: SSH is the intended vector, sudo not the path → reject
    // - M1/M2: no privilege escalation intended → reject
    final levelId = context.levelId;
    final isSudoEscalationLevel = levelId == 'm3_l3' || levelId == 'm3_l5';

    if (!isSudoEscalationLevel) {
      return TerminalOutput.error(
        '[sudo] Sorry, user is not allowed to execute sudo on this target.\n[tip] Sudo bukan jalur yang dimaksud di level ini. Fokus ke vektor yang sesuai dengan objective.',
      );
    }

    // Only grant root on levels where sudo is the intended path
    context.hasRootPrivilege = true;
    context.currentUser = 'root';
    context.completeObjective('exploit_successful');
    final sudoOutput = '[sudo] running as root: ${args.join(' ')}';
    return TerminalOutput.success(
      '$sudoOutput\n\n[tip] Root access obtained. Read the flag with: cat /root/flag.txt',
    );
  }
}
