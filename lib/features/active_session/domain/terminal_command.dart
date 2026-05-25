import 'package:nullbyte/features/active_session/domain/level_context.dart';

export 'package:nullbyte/features/active_session/domain/level_context.dart'
    show LevelContext;

/// Tipe output terminal untuk styling visual.
enum TerminalOutputType { input, output, error, info, success }

/// Satu baris output di terminal simulator.
class TerminalOutput {
  final String text;
  final TerminalOutputType type;
  final DateTime timestamp;

  const TerminalOutput({
    required this.text,
    required this.type,
    required this.timestamp,
  });

  factory TerminalOutput.input(String text) => TerminalOutput(
    text: text,
    type: TerminalOutputType.input,
    timestamp: DateTime.now(),
  );

  factory TerminalOutput.output(String text) => TerminalOutput(
    text: text,
    type: TerminalOutputType.output,
    timestamp: DateTime.now(),
  );

  factory TerminalOutput.error(String text) => TerminalOutput(
    text: text,
    type: TerminalOutputType.error,
    timestamp: DateTime.now(),
  );

  factory TerminalOutput.info(String text) => TerminalOutput(
    text: text,
    type: TerminalOutputType.info,
    timestamp: DateTime.now(),
  );

  factory TerminalOutput.success(String text) => TerminalOutput(
    text: text,
    type: TerminalOutputType.success,
    timestamp: DateTime.now(),
  );
}

/// Hasil parsing dari input string pengguna.
class ParsedCommand {
  final String name;
  final List<String> args;

  const ParsedCommand({required this.name, required this.args});

  bool get isEmpty => name.isEmpty;
}

/// Interface untuk semua perintah terminal.
abstract class TerminalCommand {
  /// Nama utama perintah (misal: 'nmap').
  String get name;

  /// Alias alternatif (misal: ['nm'] untuk nmap).
  List<String> get aliases;

  /// Deskripsi singkat untuk `help`.
  String get description;

  /// Contoh penggunaan.
  String get usage;

  /// Apakah perintah ini membutuhkan privilege root.
  bool get requiresPrivilege;

  /// Eksekusi perintah dengan argumen dan konteks level.
  Future<TerminalOutput> execute(List<String> args, LevelContext context);
}
