import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nullbyte/shared/models/level_definition.dart';

void main() {
  group('Level content contract', () {
    test('every level keeps the V1 content structure intact', () async {
      final levels = await _loadAllLevels();

      for (final level in levels) {
        expect(level.objectives, hasLength(3), reason: '${level.id}: must have 3 objectives');
        expect(level.hints, hasLength(3), reason: '${level.id}: must have 3 hints');
        expect(
          level.hints.map((hint) => hint.level).toList(),
          equals([1, 2, 3]),
          reason: '${level.id}: hint levels must be 1, 2, 3 in order',
        );
        expect(
          level.expectedCommandPath,
          isNotEmpty,
          reason: '${level.id}: expectedCommandPath must not be empty',
        );
        expect(
          level.recommendedTools,
          isNotEmpty,
          reason: '${level.id}: recommendedTools must not be empty',
        );
        expect(
          level.realWorldContext.trim().length,
          greaterThan(40),
          reason: '${level.id}: realWorldContext must teach something meaningful',
        );

        final firstCommand = _commandName(level.expectedCommandPath.first);
        expect(
          level.recommendedTools,
          contains(firstCommand),
          reason: '${level.id}: recommendedTools should include the first expected command',
        );

        final finalCommand = _commandName(level.expectedCommandPath.last);
        expect(
          ['curl', 'cat', 'sqlmap'],
          contains(finalCommand),
          reason: '${level.id}: final command should reveal data through curl/cat/sqlmap',
        );

        final finalHint = level.hints.last.text.toLowerCase();
        expect(
          finalHint,
          anyOf(contains('flag'), contains('root'), contains('admin')),
          reason: '${level.id}: final hint should point to the end goal clearly',
        );
      }
    });
  });
}

String _commandName(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return trimmed.split(RegExp(r'\s+')).first;
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
