import 'terminal_command.dart';

/// Mem-parse string input pengguna menjadi [ParsedCommand].
class CommandParser {
  const CommandParser();

  /// Parse [input] menjadi [ParsedCommand].
  ///
  /// Aturan:
  /// - Trim whitespace di awal/akhir
  /// - Token pertama = nama command
  /// - Token berikutnya = args
  /// - String dalam tanda kutip ganda diperlakukan sebagai satu token
  /// - Multiple spaces antar token diabaikan
  /// - Input kosong → ParsedCommand(name: '', args: [])
  ParsedCommand parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ParsedCommand(name: '', args: []);
    }

    final tokens = _tokenize(trimmed);
    if (tokens.isEmpty) {
      return const ParsedCommand(name: '', args: []);
    }

    return ParsedCommand(name: tokens.first, args: tokens.sublist(1));
  }

  /// Tokenize string dengan dukungan quoted strings (double-quote dan single-quote).
  List<String> _tokenize(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inDoubleQuotes = false;
    var inSingleQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];

      // BUG-17 FIX: handle single-quote agar SQLi payload (misal: 'a' OR '1'='1')
      // tidak terpotong di tengah saat parsing argumen command.
      if (char == '"' && !inSingleQuotes) {
        inDoubleQuotes = !inDoubleQuotes;
        continue;
      }

      if (char == "'" && !inDoubleQuotes) {
        inSingleQuotes = !inSingleQuotes;
        continue;
      }

      if (char == ' ' && !inDoubleQuotes && !inSingleQuotes) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        // Skip multiple spaces
        continue;
      }

      buffer.write(char);
    }

    // Tambahkan token terakhir jika ada
    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }
}
