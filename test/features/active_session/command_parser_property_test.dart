// Property test untuk CommandParser
//
// **Validates: Requirements 3.1, 3.4**
//
// Property 7: Terminal Output Selalu Non-Null
// For any string input that is a registered command in CommandRegistry
// with valid arguments, Terminal_Simulator SHALL produce output that is
// not null and not empty within a limited time.
//
// Property 8: Pesan Error Command Not Found
// For any string input that is not registered in CommandRegistry,
// Terminal_Simulator SHALL produce output containing the text
// "command not found: " followed by the input string verbatim.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nullbyte/features/active_session/domain/command_parser.dart';
import 'package:nullbyte/features/active_session/domain/command_registry.dart';
import 'package:nullbyte/features/active_session/domain/terminal_command.dart';

// ── Mock Command ──────────────────────────────────────────────────────────────

/// A simple mock command for testing.
class MockCommand extends TerminalCommand {
  @override
  String get name => 'mock';

  @override
  List<String> get aliases => ['m'];

  @override
  String get description => 'Mock command for testing';

  @override
  String get usage => 'mock [arg1] [arg2]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    return TerminalOutput.output('Mock output with ${args.length} args');
  }
}

/// Another mock command.
class HelpCommand extends TerminalCommand {
  @override
  String get name => 'help';

  @override
  List<String> get aliases => ['h', '?'];

  @override
  String get description => 'Show help';

  @override
  String get usage => 'help [command]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    return TerminalOutput.output('Help output');
  }
}

/// Echo command that returns its arguments.
class EchoCommand extends TerminalCommand {
  @override
  String get name => 'echo';

  @override
  List<String> get aliases => [];

  @override
  String get description => 'Echo arguments';

  @override
  String get usage => 'echo [text...]';

  @override
  bool get requiresPrivilege => false;

  @override
  Future<TerminalOutput> execute(
    List<String> args,
    LevelContext context,
  ) async {
    final text = args.join(' ');
    return TerminalOutput.output('Echo: $text');
  }
}

// ── Generators ────────────────────────────────────────────────────────────────

/// Generate a random invalid command name (not in registry).
String _generateInvalidCommand(Random rng) {
  const chars = 'abcdefghijklmnopqrstuvwxyz';
  final length = rng.nextInt(10) + 3;
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
}

/// Generate random arguments for a command.
List<String> _generateArgs(Random rng) {
  final argCount = rng.nextInt(4);
  return [for (var i = 0; i < argCount; i++) 'arg${rng.nextInt(100)}'];
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  const iterations = 100;
  late CommandParser parser;
  late CommandRegistry registry;
  late LevelContext mockContext;

  setUpAll(() {
    parser = const CommandParser();
    registry = CommandRegistry();
    mockContext = LevelContext(levelId: 'test_level');

    // Register test commands
    registry.register(MockCommand());
    registry.register(HelpCommand());
    registry.register(EchoCommand());
  });

  group('Property 7: Terminal Output Selalu Non-Null', () {
    test(
      'valid command with no args produces non-null, non-empty output',
      () async {
        final validCommands = ['mock', 'help', 'echo'];

        for (var i = 0; i < iterations; i++) {
          final cmdName = validCommands[i % validCommands.length];
          final cmd = registry.lookup(cmdName);

          expect(cmd, isNotNull, reason: 'command $cmdName must be registered');

          final output = await cmd!.execute([], mockContext);

          expect(
            output,
            isNotNull,
            reason: 'iteration $i: output must not be null',
          );
          expect(
            output.text,
            isNotEmpty,
            reason: 'iteration $i: output text must not be empty',
          );
        }
      },
    );

    test(
      'valid command with args produces non-null, non-empty output',
      () async {
        final rng = Random(42);
        final validCommands = ['mock', 'help', 'echo'];

        for (var i = 0; i < iterations; i++) {
          final cmdName = validCommands[i % validCommands.length];
          final cmd = registry.lookup(cmdName);
          final args = _generateArgs(rng);

          expect(cmd, isNotNull);

          final output = await cmd!.execute(args, mockContext);

          expect(
            output,
            isNotNull,
            reason: 'iteration $i: output must not be null',
          );
          expect(
            output.text,
            isNotEmpty,
            reason: 'iteration $i: output text must not be empty',
          );
        }
      },
    );

    test('parsed valid command produces non-null output', () async {
      final validCommands = ['mock', 'help', 'echo'];

      for (var i = 0; i < iterations; i++) {
        final cmdName = validCommands[i % validCommands.length];
        final parsed = parser.parse(cmdName);

        expect(parsed.name, isNotEmpty);

        final cmd = registry.lookup(parsed.name);
        expect(cmd, isNotNull);

        final output = await cmd!.execute(parsed.args, mockContext);

        expect(
          output,
          isNotNull,
          reason: 'iteration $i: output must not be null',
        );
        expect(
          output.text,
          isNotEmpty,
          reason: 'iteration $i: output text must not be empty',
        );
      }
    });

    test('command with quoted arguments produces non-null output', () async {
      final inputs = [
        'echo "hello world"',
        'mock "arg with spaces"',
        'help "some topic"',
      ];

      for (var i = 0; i < inputs.length; i++) {
        final parsed = parser.parse(inputs[i]);
        final cmd = registry.lookup(parsed.name);

        expect(cmd, isNotNull);

        final output = await cmd!.execute(parsed.args, mockContext);

        expect(
          output,
          isNotNull,
          reason: 'iteration $i: output must not be null',
        );
        expect(
          output.text,
          isNotEmpty,
          reason: 'iteration $i: output text must not be empty',
        );
      }
    });
  });

  group('Property 8: Pesan Error Command Not Found', () {
    test('unregistered command produces "command not found" error', () async {
      final rng = Random(99);

      for (var i = 0; i < iterations; i++) {
        final invalidCmd = _generateInvalidCommand(rng);

        // Ensure it's not accidentally a registered command
        if (registry.isRegistered(invalidCmd)) {
          continue;
        }

        final output = registry.notFound(invalidCmd);

        expect(
          output.text,
          contains('command not found:'),
          reason:
              'iteration $i: error message must contain "command not found:"',
        );
        expect(
          output.text,
          contains(invalidCmd),
          reason: 'iteration $i: error message must contain the input verbatim',
        );
        expect(
          output.type,
          equals(TerminalOutputType.error),
          reason: 'iteration $i: output type must be error',
        );
      }
    });

    test('error message contains input string verbatim', () async {
      final testInputs = [
        'nonexistent',
        'xyz123',
        'foobar',
        'unknown_command',
        'test-cmd',
      ];

      for (final input in testInputs) {
        if (registry.isRegistered(input)) {
          continue;
        }

        final output = registry.notFound(input);

        expect(
          output.text,
          equals('command not found: $input'),
          reason: 'error message must be exactly "command not found: $input"',
        );
      }
    });

    test('error message format is consistent', () async {
      final rng = Random(77);

      for (var i = 0; i < iterations; i++) {
        final invalidCmd = _generateInvalidCommand(rng);

        if (registry.isRegistered(invalidCmd)) {
          continue;
        }

        final output = registry.notFound(invalidCmd);
        final expectedFormat = 'command not found: $invalidCmd';

        expect(
          output.text,
          equals(expectedFormat),
          reason: 'iteration $i: format must be consistent',
        );
      }
    });

    test('error message preserves special characters in input', () async {
      final specialInputs = [
        'cmd@123',
        'test-cmd',
        'cmd_name',
        'cmd.exe',
        'cmd/path',
      ];

      for (final input in specialInputs) {
        if (registry.isRegistered(input)) {
          continue;
        }

        final output = registry.notFound(input);

        expect(
          output.text,
          contains(input),
          reason: 'error message must preserve special characters',
        );
      }
    });

    test('parsed invalid command produces correct error', () async {
      final rng = Random(55);

      for (var i = 0; i < iterations; i++) {
        final invalidCmd = _generateInvalidCommand(rng);

        if (registry.isRegistered(invalidCmd)) {
          continue;
        }

        final parsed = parser.parse(invalidCmd);
        final cmd = registry.lookup(parsed.name);

        expect(
          cmd,
          isNull,
          reason: 'iteration $i: command must not be registered',
        );

        final output = registry.notFound(parsed.name);

        expect(
          output.text,
          contains('command not found:'),
          reason:
              'iteration $i: error message must contain "command not found:"',
        );
        expect(
          output.text,
          contains(invalidCmd),
          reason: 'iteration $i: error message must contain the input',
        );
      }
    });

    test('empty command produces error', () async {
      final output = registry.notFound('');

      expect(
        output.text,
        equals('command not found: '),
        reason: 'empty command should produce error with empty string',
      );
      expect(output.type, equals(TerminalOutputType.error));
    });

    test('whitespace-only command produces error', () async {
      final output = registry.notFound('   ');

      expect(
        output.text,
        contains('command not found:'),
        reason: 'whitespace command should produce error',
      );
    });
  });

  group('Integration: Parser + Registry', () {
    test('parser output can be looked up in registry', () async {
      final inputs = [
        'mock',
        'help',
        'echo',
        'mock arg1 arg2',
        'help "some topic"',
      ];

      for (final input in inputs) {
        final parsed = parser.parse(input);
        final cmd = registry.lookup(parsed.name);

        expect(
          cmd,
          isNotNull,
          reason: 'parsed command "$input" must be found in registry',
        );

        final output = await cmd!.execute(parsed.args, mockContext);
        expect(output.text, isNotEmpty);
      }
    });

    test('parser handles invalid commands correctly', () async {
      final invalidInputs = ['nonexistent', 'xyz123 arg1 arg2', 'unknown_cmd'];

      for (final input in invalidInputs) {
        final parsed = parser.parse(input);
        final cmd = registry.lookup(parsed.name);

        if (cmd == null) {
          final output = registry.notFound(parsed.name);
          expect(
            output.text,
            contains('command not found:'),
            reason: 'invalid command "$input" should produce error',
          );
        }
      }
    });
  });
}
