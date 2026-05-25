import 'package:flutter_test/flutter_test.dart';
import 'package:nullbyte/features/active_session/domain/commands/access_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/info_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/navigation_commands.dart';
import 'package:nullbyte/features/active_session/domain/commands/utility_commands.dart';
import 'package:nullbyte/features/active_session/domain/level_context.dart';

void main() {
  group('Access and identity commands', () {
    test('ssh preserves the requested username and home directory', () async {
      final context = LevelContext(levelId: 'm3_l5');
      final ssh = SshCommand();
      final whoami = WhoamiCommand();
      final id = IdCommand();
      final ls = LsCommand();

      final sshOutput = await ssh.execute(['operator@192.168.120.1'], context);
      final whoamiOutput = await whoami.execute([], context);
      final idOutput = await id.execute([], context);
      final lsOutput = await ls.execute([], context);

      expect(sshOutput.text, contains('Connected to 192.168.120.1 as operator'));
      expect(sshOutput.text, contains('operator@nullbyte:/home/operator\$'));
      expect(context.currentUser, equals('operator'));
      expect(context.currentDirectory, equals('/home/operator'));
      expect(whoamiOutput.text, equals('operator'));
      expect(idOutput.text, contains('uid=1001(operator)'));
      expect(lsOutput.text, contains('flag.txt'));
    });

    test('sudo escalation moves the session to root identity', () async {
      final context = LevelContext(levelId: 'm3_l3', currentUser: 'user');
      final sudo = SudoCommand();
      final whoami = WhoamiCommand();
      final cd = CdCommand();

      await sudo.execute(['find', '.', '-exec', '/bin/sh', ';', '-quit'], context);
      final whoamiOutput = await whoami.execute([], context);
      await cd.execute(['~'], context);

      expect(context.hasRootPrivilege, isTrue);
      expect(context.currentUser, equals('root'));
      expect(context.currentDirectory, equals('/root'));
      expect(whoamiOutput.text, equals('root'));
    });
  });
}
