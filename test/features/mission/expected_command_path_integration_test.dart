import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nullbyte/features/active_session/domain/command_parser.dart';
import 'package:nullbyte/features/active_session/domain/commands/commands_registry_factory.dart';
import 'package:nullbyte/features/active_session/domain/level_context.dart';
import 'package:nullbyte/shared/models/level_definition.dart';

void main() {
  const parser = CommandParser();

  group('Expected command path integration', () {
    test(
      'every level expectedCommandPath can drive the simulator to the active flag',
      () async {
        final levels = await _loadAllLevels();

        for (final level in levels) {
          final registry = createDefaultRegistry();
          final context = LevelContext.fromDefinition(level);
          context.startLevel(level);

          String finalOutput = '';

          for (final commandInput in level.expectedCommandPath) {
            final parsed = parser.parse(commandInput);

            expect(
              parsed.isEmpty,
              isFalse,
              reason: '${level.id}: command must parse -> $commandInput',
            );

            final command = registry.lookup(parsed.name);
            expect(
              command,
              isNotNull,
              reason: '${level.id}: command must be registered -> ${parsed.name}',
            );

            final output = await command!.execute(parsed.args, context);
            finalOutput = output.text;
          }

          expect(
            finalOutput,
            contains(context.currentFlag),
            reason:
                '${level.id}: final expected command must reveal the active flag',
          );
        }
      },
    );
  });
}

Future<List<LevelDefinition>> _loadAllLevels() async {
  final files = [
    'D:/gameDev/nullbyte/assets/data/levels/mission_1.json',
    'D:/gameDev/nullbyte/assets/data/levels/mission_2.json',
    'D:/gameDev/nullbyte/assets/data/levels/mission_3.json',
  ];

  final levels = <LevelDefinition>[];
  for (final path in files) {
    final raw = await File(path).readAsString();
    final jsonMap = json.decode(raw) as Map<String, dynamic>;
    final levelList = (jsonMap['levels'] as List<dynamic>)
        .map((entry) => LevelDefinition.fromJson(entry as Map<String, dynamic>))
        .toList();
    levels.addAll(levelList);
  }
  return levels;
}
