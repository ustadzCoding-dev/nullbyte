import 'dart:convert';
import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

/// Simulasi john the ripper — password cracking.
class JohnCommand extends TerminalCommand {
  @override
  String get name => 'john';

  @override
  List<String> get aliases => ['john-the-ripper'];

  @override
  String get description => 'John the Ripper password cracker';

  @override
  String get usage => 'john [options] <hashfile>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('john: missing hash file\nUsage: $usage');
    }

    final levelId = context.levelId;

    // Level gating: john is a password cracking tool
    if (levelId.startsWith('m1')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.error(
        'john: no hash file found\n[tip] Mission ini fokus ke reconnaissance. Tidak perlu password cracking — gunakan nmap dan curl.',
      );
    }
    if (levelId.startsWith('m3')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'john: no hash file found on target\n[tip] Mission ini fokus ke privilege escalation. Gunakan ssh dan sudo untuk jalur yang sesuai.',
      );
    }
    if (levelId == 'm2_l1') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'john: no hash file found\n[tip] Level ini tentang endpoint discovery. Fokus ke curl untuk memetakan permukaan serang.',
      );
    }
    if (levelId == 'm2_l2') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'john: no hash file found\n[tip] Level ini tentang SQL injection. Gunakan sqlmap untuk mengeksploitasi parameter pencarian.',
      );
    }
    if (levelId == 'm2_l4') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'john: no hash file found\n[tip] Level ini tentang file upload. Gunakan curl -F untuk upload webshell.',
      );
    }
    if (levelId == 'm2_l5') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'john: no hash file found\n[tip] Level ini tentang reverse shell. Gunakan webshell yang sudah ada.',
      );
    }

    // M2 L3: auth bypass — john can crack hashes from /etc/shadow
    await Future.delayed(const Duration(milliseconds: 450));

    final hashFile =
        args.where((a) => !a.startsWith('-')).lastOrNull ?? 'hashes.txt';
    final wordlistIdx = args.indexOf('--wordlist');
    final wordlist = wordlistIdx >= 0 && wordlistIdx + 1 < args.length
        ? args[wordlistIdx + 1]
        : '/usr/share/wordlists/rockyou.txt';

    final output =
        '''Using default input encoding: UTF-8
Loaded 3 password hashes from $hashFile with no different salts (md5crypt, crypt(3) \$1\$ [MD5 256/256 AVX2 8x3])
Using wordlist: $wordlist
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
P@ssw0rd123      (admin)
toor             (root)
letmein          (user)
3g 0:00:00:02 DONE (2024-01-15 03:42) 1.500g/s 21504p/s 21504c/s 21504C/s
Use the "--show" option to display all of the cracked passwords reliably
Session completed.''';

    return TerminalOutput.success(output);
  }
}

/// Simulasi hashcat — hash cracking.
class HashcatCommand extends TerminalCommand {
  @override
  String get name => 'hashcat';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Advanced CPU-based password recovery utility';

  @override
  String get usage => 'hashcat -m <mode> <hashfile> <wordlist>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('hashcat: missing arguments\nUsage: $usage');
    }

    final levelId = context.levelId;

    // Level gating: hashcat is a hash cracking tool
    if (levelId.startsWith('m1')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.error(
        'hashcat: no hash file found\n[tip] Mission ini fokus ke reconnaissance. Tidak perlu hash cracking — gunakan nmap dan curl.',
      );
    }
    if (levelId.startsWith('m3')) {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'hashcat: no hash file found on target\n[tip] Mission ini fokus ke privilege escalation. Gunakan ssh dan sudo untuk jalur yang sesuai.',
      );
    }
    if (levelId == 'm2_l1') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'hashcat: no hash file found\n[tip] Level ini tentang endpoint discovery. Fokus ke curl untuk memetakan permukaan serang.',
      );
    }
    if (levelId == 'm2_l2') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'hashcat: no hash file found\n[tip] Level ini tentang SQL injection. Gunakan sqlmap untuk mengeksploitasi parameter pencarian.',
      );
    }
    if (levelId == 'm2_l4') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'hashcat: no hash file found\n[tip] Level ini tentang file upload. Gunakan curl -F untuk upload webshell.',
      );
    }
    if (levelId == 'm2_l5') {
      await Future.delayed(const Duration(milliseconds: 300));
      return TerminalOutput.output(
        'hashcat: no hash file found\n[tip] Level ini tentang reverse shell. Gunakan webshell yang sudah ada.',
      );
    }

    // M2 L3: auth bypass — hashcat can crack hashes
    await Future.delayed(const Duration(milliseconds: 480));

    final modeIdx = args.indexOf('-m');
    final mode = modeIdx >= 0 && modeIdx + 1 < args.length
        ? args[modeIdx + 1]
        : '0';
    final modeDesc = _getModeDesc(mode);

    final output =
        '''hashcat (v6.2.6) starting...

OpenCL API (OpenCL 3.0 ) - Platform #1 [The pocl project]
==========================================================
* Device #1: pthread-Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz, 2873/5810 MB (1024 MB allocatable), 4MCU

Minimum password length supported by kernel: 0
Maximum password length supported by kernel: 256

Hashes: 1 digests; 1 unique digests, 1 unique salts
Bitmaps: 16 bits, 65536 entries, 0x0000ffff mask, 262144 bytes, 5/13 rotates
Rules: 1

Optimizers applied:
* Zero-Byte
* Early-Skip
* Not-Salted
* Not-Iterated
* Single-Hash
* Raw-Hash

ATTENTION! Pure (unoptimized) backend kernels selected.

Host memory required for this attack: 1 MB

Dictionary cache built:
* Filename..: /usr/share/wordlists/rockyou.txt
* Passwords.: 14344391
* Bytes.....: 139921497
* Keyspace..: 14344391
* Runtime...: 1 sec

5f4dcc3b5aa765d61d8327deb882cf99:password
                                                          
Session..........: hashcat
Status...........: Cracked
Hash.Mode........: $mode ($modeDesc)
Hash.Target......: 5f4dcc3b5aa765d61d8327deb882cf99
Time.Started.....: Mon Jan 15 03:42:00 2024 (0 secs)
Time.Estimated...: Mon Jan 15 03:42:00 2024 (0 secs)
Kernel.Feature...: Pure Kernel
Guess.Base.......: File (/usr/share/wordlists/rockyou.txt)
Guess.Queue......: 1/1 (100.00%)
Speed.#1.........:  9876.5 kH/s (0.22ms) @ Accel:512 Loops:1 Thr:1 Vec:8
Recovered........: 1/1 (100.00%) Digests (total), 1/1 (100.00%) Digests (new)
Progress.........: 14344391/14344391 (100.00%)
Rejected.........: 0/14344391 (0.00%)
Restore.Point....: 0/14344391 (0.00%)
Restore.Sub.#1...: Salt:0 Amplifier:0-1 Iteration:0-1
Candidate.Engine.: Device Generator
Candidates.#1....: 123456 -> password

Started: Mon Jan 15 03:42:00 2024
Stopped: Mon Jan 15 03:42:01 2024''';

    return TerminalOutput.success(output);
  }

  String _getModeDesc(String mode) {
    const modes = {
      '0': 'MD5',
      '100': 'SHA1',
      '1400': 'SHA2-256',
      '1700': 'SHA2-512',
      '1800': 'sha512crypt \$6\$, SHA512 (Unix)',
      '3200': 'bcrypt \$2*\$, Blowfish (Unix)',
    };
    return modes[mode] ?? 'MD5';
  }
}

/// Base64 encode/decode.
class Base64Command extends TerminalCommand {
  @override
  String get name => 'base64';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Base64 encode or decode data';

  @override
  String get usage => 'base64 [-e|-d] <string>';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    if (args.isEmpty) {
      return TerminalOutput.error('base64: missing operand\nUsage: $usage');
    }

    await Future.delayed(const Duration(milliseconds: 50));

    final decode = args.contains('-d') || args.contains('--decode');
    final input = args.where((a) => !a.startsWith('-')).join(' ');

    if (input.isEmpty) {
      return TerminalOutput.error('base64: missing input string');
    }

    try {
      if (decode) {
        final decoded = utf8.decode(base64.decode(input.trim()));
        return TerminalOutput.output(decoded);
      } else {
        final encoded = base64.encode(utf8.encode(input));
        return TerminalOutput.output(encoded);
      }
    } catch (e) {
      return TerminalOutput.error('base64: invalid input: $e');
    }
  }
}
