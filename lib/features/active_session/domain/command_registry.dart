import 'terminal_command.dart';

/// Registry untuk semua [TerminalCommand] yang tersedia.
///
/// Mendukung lookup by name dan alias, autocomplete suggestions,
/// dan error response untuk command yang tidak ditemukan.
class CommandRegistry {
  final Map<String, TerminalCommand> _commands = {};

  /// Daftarkan sebuah [command]. Jika name atau alias sudah ada, akan di-overwrite.
  void register(TerminalCommand command) {
    _commands[command.name] = command;
    for (final alias in command.aliases) {
      _commands[alias] = command;
    }
  }

  /// Cari command berdasarkan [name] atau alias-nya.
  /// Mengembalikan null jika tidak ditemukan.
  TerminalCommand? lookup(String name) => _commands[name];

  /// Semua command unik yang terdaftar (tanpa duplikat dari alias).
  List<TerminalCommand> get all {
    final seen = <String>{};
    final result = <TerminalCommand>[];
    for (final cmd in _commands.values) {
      if (seen.add(cmd.name)) {
        result.add(cmd);
      }
    }
    return result;
  }

  /// Kembalikan daftar nama command yang dimulai dengan [prefix].
  /// Berguna untuk fitur autocomplete.
  List<String> getSuggestions(String prefix) {
    if (prefix.isEmpty) return all.map((c) => c.name).toList();
    return all
        .map((c) => c.name)
        .where((name) => name.startsWith(prefix))
        .toList();
  }

  /// Cek apakah command dengan [name] (atau alias) sudah terdaftar.
  bool isRegistered(String name) => _commands.containsKey(name);

  /// Buat [TerminalOutput] error "command not found" untuk [input] yang tidak dikenal.
  /// Menyertakan saran untuk command yang mirip atau sering dicoba.
  TerminalOutput notFound(String input) {
    final lower = input.toLowerCase();
    // Common commands players try but aren't implemented
    const suggestions = {
      'ifconfig':
          'Gunakan ip addr atau netstat untuk melihat konfigurasi jaringan.',
      'ip': 'Gunakan netstat untuk melihat koneksi jaringan.',
      'env':
          'Coba cat /etc/passwd atau cat /etc/hosts untuk melihat konfigurasi sistem.',
      'export': 'Environment variables tidak tersedia di simulasi ini.',
      'uname': 'Gunakan cat /etc/passwd untuk informasi sistem.',
      'ls': 'Gunakan ls -la atau find untuk menemukan file.',
      'dir': 'Gunakan ls atau find untuk menemukan file.',
      'ftp': 'Gunakan curl atau wget untuk transfer file.',
      'telnet': 'Gunakan nc (netcat) untuk koneksi TCP.',
      'python': 'Gunakan nc untuk reverse shell, atau curl untuk web request.',
      'python3': 'Gunakan nc untuk reverse shell, atau curl untuk web request.',
      'perl': 'Gunakan nc untuk reverse shell, atau curl untuk web request.',
      'ruby': 'Gunakan nc untuk reverse shell, atau curl untuk web request.',
      'php': 'Gunakan curl untuk mengakses webshell yang sudah diupload.',
      'service': 'Gunakan ps aux untuk melihat service yang berjalan.',
      'systemctl': 'Gunakan ps aux untuk melihat service yang berjalan.',
      'apt': 'Package manager tidak tersedia di simulasi ini.',
      'yum': 'Package manager tidak tersedia di simulasi ini.',
      'pip': 'Package manager tidak tersedia di simulasi ini.',
      'make': 'Compiler tidak tersedia di simulasi ini.',
      'gcc': 'Compiler tidak tersedia di simulasi ini.',
      'gdb': 'Debugger tidak tersedia di simulasi ini.',
      'vim':
          'Gunakan cat untuk membaca file. Editor tidak tersedia di simulasi ini.',
      'nano':
          'Gunakan cat untuk membaca file. Editor tidak tersedia di simulasi ini.',
      'vi':
          'Gunakan cat untuk membaca file. Editor tidak tersedia di simulasi ini.',
      'less': 'Gunakan cat untuk membaca file.',
      'more': 'Gunakan cat untuk membaca file.',
      'head': 'Gunakan cat untuk membaca file.',
      'tail': 'Gunakan cat untuk membaca file.',
      'grep':
          'Gunakan find -name untuk mencari file, atau cat untuk membaca isi.',
      'awk': 'Gunakan cat untuk membaca file dan filter output secara manual.',
      'sed':
          'Gunakan cat untuk membaca file. Editor tidak tersedia di simulasi ini.',
      'man': 'Gunakan help untuk melihat daftar command yang tersedia.',
      'history': 'Gunakan panah atas/bawah untuk navigasi riwayat command.',
      'clear': 'Gunakan clear untuk membersihkan terminal.',
      'exit': 'Gunakan exit untuk menutup koneksi SSH.',
      'ssh-keygen':
          'Gunakan cat /home/user/.ssh/id_rsa untuk melihat kunci SSH.',
      'searchsploit':
          'Gunakan nmap dan curl untuk enumerasi, lalu exploit manual.',
    };
    final tip = suggestions[lower];
    if (tip != null) {
      return TerminalOutput.error('command not found: $input\n$tip');
    }
    // Fuzzy match: suggest similar registered commands
    final allNames = all.map((c) => c.name).toList();
    final similar = allNames.where((n) {
      if (n.contains(lower) || lower.contains(n)) return true;
      // Simple edit distance: off-by-one prefix
      if (n.length >= 2 &&
          lower.length >= 2 &&
          n.substring(0, n.length - 1) ==
              lower.substring(0, lower.length - 1)) {
        return true;
      }
      return false;
    }).toList();
    if (similar.isNotEmpty) {
      return TerminalOutput.error(
        'command not found: $input\nMaksud Anda: ${similar.take(3).join(', ')}? Ketik help untuk daftar command.',
      );
    }
    return TerminalOutput.error(
      'command not found: $input\nKetik help untuk melihat daftar command yang tersedia.',
    );
  }
}
