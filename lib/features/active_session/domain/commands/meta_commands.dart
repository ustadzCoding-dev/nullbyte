import 'package:nullbyte/features/active_session/domain/command_registry.dart';
import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

class HelpCommand extends TerminalCommand {
  final CommandRegistry registry;

  HelpCommand(this.registry);

  @override
  String get name => 'help';

  @override
  List<String> get aliases => ['?', 'man'];

  @override
  String get description => 'Display available commands';

  @override
  String get usage => 'help [command]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (args.isNotEmpty) {
      final cmd = registry.lookup(args.first);
      if (cmd == null) {
        return TerminalOutput.error('help: no help for ${args.first}');
      }
      final aliasStr = cmd.aliases.isEmpty
          ? ''
          : '\nAliases: ${cmd.aliases.join(', ')}';
      return TerminalOutput.info(
        '${cmd.name} - ${cmd.description}\nUsage: ${cmd.usage}$aliasStr',
      );
    }

    final all = registry.all;
    final buffer = StringBuffer();
    buffer.writeln('NULLBYTE Terminal v1.0 - Available Commands');
    buffer.writeln('=' * 50);

    all.sort((a, b) => a.name.compareTo(b.name));

    for (final cmd in all) {
      final priv = cmd.requiresPrivilege ? ' [root]' : '';
      buffer.writeln('  ${cmd.name.padRight(12)} ${cmd.description}$priv');
    }

    buffer.writeln('');
    buffer.writeln("Type 'help <command>' for detailed usage.");
    buffer.writeln(
      "[tip] Untuk mission recon awal, mulai dari command discovery seperti 'nmap' atau 'ping'.",
    );

    return TerminalOutput.info(buffer.toString());
  }
}

class ClearCommand extends TerminalCommand {
  @override
  String get name => 'clear';

  @override
  List<String> get aliases => ['cls', 'reset'];

  @override
  String get description => 'Clear the terminal screen';

  @override
  String get usage => 'clear';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    return TerminalOutput.info('__CLEAR__');
  }
}

class HistoryCommand extends TerminalCommand {
  @override
  String get name => 'history';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Display command history';

  @override
  String get usage => 'history [n]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final history = context.commandHistory;
    if (history.isEmpty) {
      return TerminalOutput.output('(no commands in history)');
    }

    int limit = history.length;
    if (args.isNotEmpty) {
      limit = int.tryParse(args.first) ?? history.length;
    }

    final start = (history.length - limit).clamp(0, history.length);
    final slice = history.sublist(start);

    final lines = slice
        .asMap()
        .entries
        .map(
          (e) => '  ${(start + e.key + 1).toString().padLeft(4)}  ${e.value}',
        )
        .join('\n');

    return TerminalOutput.output(lines);
  }
}
