import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

/// Simulasi ls — list direktori.
class LsCommand extends TerminalCommand {
  @override
  String get name => 'ls';

  @override
  List<String> get aliases => ['dir'];

  @override
  String get description => 'List directory contents';

  @override
  String get usage => 'ls [options] [path]';

  @override
  bool get requiresPrivilege => false;

  // Minimal fallback — level-aware getDirectoryListing() adalah sumber utama.
  // Static map hanya untuk direktori yang tidak punya file di LevelContext.
  static const Map<String, List<String>> _dirContents = {
    '/etc/ssh': ['sshd_config', 'ssh_host_rsa_key.pub'],
    '/var/log': ['auth.log', 'syslog', 'nginx', 'mysql'],
  };

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 80));

    final showAll =
        args.contains('-a') || args.contains('-la') || args.contains('-al');
    final longFormat =
        args.contains('-l') || args.contains('-la') || args.contains('-al');

    final pathArg = args.where((a) => !a.startsWith('-')).lastOrNull;
    final dir = pathArg ?? context.currentDirectory;

    // Level-aware listing: gunakan LevelContext sebagai sumber utama
    final levelListing = context.getDirectoryListing(dir);
    final List<String> contents;
    if (levelListing.isNotEmpty) {
      contents = levelListing;
    } else {
      // Fallback ke static map untuk direktori yang tidak dikelola LevelContext
      contents = _dirContents[dir] ?? [];
    }

    final filtered = showAll
        ? contents
        : contents.where((f) => !f.startsWith('.')).toList();

    if (filtered.isEmpty) {
      return TerminalOutput.output('(empty directory)');
    }

    if (longFormat) {
      final lines = filtered
          .map((f) {
            final isDir = !f.contains('.');
            final perm = isDir ? 'drwxr-xr-x' : '-rw-r--r--';
            final size = isDir ? '4096' : '${(f.hashCode.abs() % 9000) + 100}';
            return '$perm  2 root root $size Jan 15 03:42 $f';
          })
          .join('\n');
      return TerminalOutput.output('total ${filtered.length * 8}\n$lines');
    }

    return TerminalOutput.output(filtered.join('  '));
  }
}

/// Simulasi cat — baca isi file.
class CatCommand extends TerminalCommand {
  @override
  String get name => 'cat';

  @override
  List<String> get aliases => [];

  @override
  String get description =>
      'Concatenate files and print on the standard output';

  @override
  String get usage => 'cat <file>';

  @override
  bool get requiresPrivilege => false;

  static const Map<String, String> _fileContents = {
    '/etc/passwd':
        'root:x:0:0:root:/root:/bin/bash\ndaemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin\nwww-data:x:33:33:www-data:/var/www:/usr/sbin/nologin\nuser:x:1000:1000::/home/user:/bin/bash\nadmin:x:1001:1001::/home/admin:/bin/bash',
    '/etc/hosts': '127.0.0.1\tlocalhost\n127.0.1.1\tnullbyte\n',
    '/home/user/notes.txt':
        '# Personal Notes\nRemember to change default password\nReview permissions on sensitive directories',
  };

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('cat: missing file operand\nUsage: $usage');
    }

    await Future.delayed(const Duration(milliseconds: 100));

    final filePath = args.last.startsWith('/')
        ? args.last
        : '${context.currentDirectory}/${args.last}';

    // Check LevelContext (dynamic, level-aware) first as authoritative source
    final dynamicContent = context.getFileContent(filePath);
    if (!dynamicContent.startsWith('cat:')) {
      return TerminalOutput.output(dynamicContent);
    }

    // Fallback ke static map untuk file yang tidak dikelola LevelContext
    final staticContent = _fileContents[filePath] ?? _fileContents[args.last];
    if (staticContent != null) {
      return TerminalOutput.output(staticContent);
    }

    return TerminalOutput.error('cat: ${args.last}: No such file or directory');
  }
}

/// Simulasi cd — pindah direktori.
class CdCommand extends TerminalCommand {
  @override
  String get name => 'cd';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Change the shell working directory';

  @override
  String get usage => 'cd <directory>';

  @override
  bool get requiresPrivilege => false;

  /// Direktori yang selalu bisa diakses terlepas dari level.
  static const Set<String> _alwaysValidDirs = {
    '/',
    '/etc',
    '/etc/ssh',
    '/home',
    '/home/user',
    '/home/user/.ssh',
    '/home/operator',
    '/home/operator/.ssh',
    '/home/admin',
    '/home/backup',
    '/root',
    '/tmp',
    '/var',
    '/var/log',
    '/usr',
    '/bin',
    '/opt',
  };

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty || args.first == '~') {
      context.currentDirectory = context.hasRootPrivilege
          ? '/root'
          : '/home/${context.currentUser}';
      return TerminalOutput.output('');
    }

    final target = args.first;
    String newDir;

    if (target == '..') {
      final parts = context.currentDirectory.split('/')..removeLast();
      newDir = parts.isEmpty || parts.join('/').isEmpty ? '/' : parts.join('/');
    } else if (target.startsWith('/')) {
      newDir = target;
    } else {
      newDir = context.currentDirectory == '/'
          ? '/$target'
          : '${context.currentDirectory}/$target';
    }

    // Validasi: selalu valid, atau punya konten di LevelContext
    if (!_alwaysValidDirs.contains(newDir) &&
        context.getDirectoryListing(newDir).isEmpty) {
      return TerminalOutput.error('cd: $target: No such file or directory');
    }

    context.currentDirectory = newDir;
    return TerminalOutput.output('');
  }
}
