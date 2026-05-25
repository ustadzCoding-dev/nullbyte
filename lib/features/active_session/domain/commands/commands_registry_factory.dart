import 'package:nullbyte/features/active_session/domain/command_registry.dart';
import 'package:nullbyte/features/active_session/domain/commands/access_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/crypto_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/exploit_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/info_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/meta_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/navigation_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/recon_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/utility_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/web_commands.dart';

/// Buat [CommandRegistry] dengan semua command terdaftar.
CommandRegistry createDefaultRegistry() {
  final registry = CommandRegistry();

  // --- Recon ---
  registry.register(NmapCommand());
  registry.register(PingCommand());
  registry.register(NetstatCommand());

  // --- Navigation ---
  registry.register(LsCommand());
  registry.register(CatCommand());
  registry.register(CdCommand());

  // --- Info ---
  registry.register(WhoamiCommand());
  registry.register(IdCommand());
  registry.register(PsCommand());

  // --- Web ---
  registry.register(CurlCommand());
  registry.register(WgetCommand());

  // --- Exploit ---
  registry.register(HydraCommand());
  registry.register(SqlmapCommand());

  // --- Crypto ---
  registry.register(JohnCommand());
  registry.register(HashcatCommand());
  registry.register(Base64Command());

  // --- Utility ---
  registry.register(GrepCommand());
  registry.register(FindCommand());
  registry.register(ChmodCommand());
  registry.register(SudoCommand());
  registry.register(SshCommand());
  registry.register(ExitCommand());
  registry.register(NcCommand());

  // --- Meta (HelpCommand butuh registry reference) ---
  registry.register(HelpCommand(registry));
  registry.register(ClearCommand());
  registry.register(HistoryCommand());

  return registry;
}
