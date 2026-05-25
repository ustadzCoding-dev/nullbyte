import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

/// Simulasi whoami — tampilkan username saat ini.
class WhoamiCommand extends TerminalCommand {
  @override
  String get name => 'whoami';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Print effective user name';

  @override
  String get usage => 'whoami';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final user = context.hasRootPrivilege ? 'root' : context.currentUser;
    final levelId = context.levelId;
    // M1: whoami confirms local identity, guide toward recon
    if (levelId.startsWith('m1')) {
      return TerminalOutput.output(
        '$user\n\n[tip] Identitas lokal diketahui. Fokus ke reconnaissance jaringan — gunakan nmap dan curl.',
      );
    }
    // M3: after SSH foothold, guide toward next step
    if (levelId.startsWith('m3') &&
        !context.hasRootPrivilege &&
        context.completedObjectives.contains('exploit_successful')) {
      if (levelId == 'm3_l1' || levelId == 'm3_l2') {
        return TerminalOutput.output(
          '$user\n\n[tip] Foothold aktif. Lanjutkan enumerasi sistem — cek id, cat /etc/passwd, dan file sensitif.',
        );
      }
      if (levelId == 'm3_l4') {
        return TerminalOutput.output(
          '$user\n\n[tip] Foothold aktif. Periksa jaringan internal dan pivot ke host berikutnya.',
        );
      }
    }
    return TerminalOutput.output(user);
  }
}

/// Simulasi id — tampilkan UID/GID info.
class IdCommand extends TerminalCommand {
  @override
  String get name => 'id';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Print real and effective user and group IDs';

  @override
  String get usage => 'id [user]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (context.hasRootPrivilege) {
      return TerminalOutput.output('uid=0(root) gid=0(root) groups=0(root)');
    }

    final user = context.currentUser;
    final levelId = context.levelId;
    // M1: id confirms local identity, guide toward recon
    if (levelId.startsWith('m1')) {
      return TerminalOutput.output(
        'uid=1000(user) gid=1000(user) groups=1000(user),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev)\n\n[tip] Identitas lokal diketahui. Fokus ke reconnaissance jaringan — gunakan nmap dan curl.',
      );
    }

    if (user == 'operator') {
      // M3 L5: operator with sudo hints
      return TerminalOutput.output(
        'uid=1001(operator) gid=1001(operator) groups=1001(operator),27(sudo),46(plugdev)\n\n[tip] Operator punya akses sudo. Cek sudo -l untuk melihat command yang diizinkan.',
      );
    }

    // M3: after foothold, sudo group membership is a clue
    if (levelId.startsWith('m3') &&
        context.completedObjectives.contains('exploit_successful')) {
      if (levelId == 'm3_l3') {
        return TerminalOutput.output(
          'uid=1000(user) gid=1000(user) groups=1000(user),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev)\n\n[tip] User berada di grup sudo. Cek sudo -l untuk melihat apa yang bisa dijalankan sebagai root.',
        );
      }
    }

    return TerminalOutput.output(
      'uid=1000(user) gid=1000(user) groups=1000(user),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev)',
    );
  }
}

/// Simulasi ps — list proses berjalan.
class PsCommand extends TerminalCommand {
  @override
  String get name => 'ps';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Report a snapshot of the current processes';

  @override
  String get usage => 'ps [options]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 120));

    final showAll =
        args.contains('aux') || args.contains('-aux') || args.contains('-e');

    if (showAll) {
      final levelId = context.levelId;
      // M3: show level-relevant processes
      if (levelId.startsWith('m3')) {
        final m3Processes =
            '''USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.1 168940 11264 ?        Ss   Jan15   0:03 /sbin/init
root         312  0.0  0.0  14428  1024 ?        Ss   Jan15   0:00 /usr/sbin/sshd -D
root         623  0.0  0.0  14428   896 ?        Ss   Jan15   0:00 /usr/sbin/cron -f
${levelId == 'm3_l3' || levelId == 'm3_l5' ? 'root         700  0.0  0.0   8432   640 ?        Ss   Jan15   0:00 /bin/bash /opt/scripts/backup.sh' : ''}
${levelId == 'm3_l5' ? 'operator    1024  0.0  0.1  21312  8192 pts/0    Ss   03:42   0:00 -bash' : 'user        1024  0.0  0.1  21312  8192 pts/0    Ss   03:42   0:00 -bash'}
user        1337  0.0  0.0  17664  3072 pts/0    R+   03:45   0:00 ps aux''';
        String? tip;
        if (levelId == 'm3_l3' || levelId == 'm3_l5') {
          tip =
              '[tip] Cron job berjalan sebagai root. Periksa script yang dieksekusi — mungkin bisa dimodifikasi atau dimanfaatkan.';
        }
        return TerminalOutput.output(
          tip != null ? '$m3Processes\n\n$tip' : m3Processes,
        );
      }
      const output =
          '''USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.1 168940 11264 ?        Ss   Jan15   0:03 /sbin/init
root         312  0.0  0.0  14428  1024 ?        Ss   Jan15   0:00 /usr/sbin/sshd -D
www-data     445  0.1  0.5 456320 42112 ?        S    Jan15   1:23 /usr/sbin/apache2
mysql        512  0.2  2.1 1823456 172032 ?      Sl   Jan15   4:12 /usr/sbin/mysqld
root         623  0.0  0.0  14428   896 ?        Ss   Jan15   0:00 /usr/sbin/cron -f
user        1024  0.0  0.1  21312  8192 pts/0    Ss   03:42   0:00 -bash
user        1337  0.0  0.0  17664  3072 pts/0    R+   03:45   0:00 ps aux''';
      // M1: ps shows local processes, guide toward network recon
      if (levelId.startsWith('m1')) {
        return TerminalOutput.output(
          '$output\n\n[tip] Proses lokal tidak terlalu relevan di mission ini. Fokus ke reconnaissance jaringan — gunakan nmap dan curl.',
        );
      }
      // M2: ps shows web services, guide toward web exploitation
      if (levelId.startsWith('m2')) {
        return TerminalOutput.output(
          '$output\n\n[tip] Service web dan database aktif. Fokus ke endpoint dan kelemahan aplikasi web.',
        );
      }
      return TerminalOutput.output(output);
    }

    const output = '''  PID TTY          TIME CMD
 1024 pts/0    00:00:00 bash
 1337 pts/0    00:00:00 ps''';
    return TerminalOutput.output(output);
  }
}
