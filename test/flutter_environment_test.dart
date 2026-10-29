import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:upcode_ci/src/commands/flutter/environment.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('flutter:environment set', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('upcode_environment');
      Directory(join(project.path, 'windows')).createSync();
    });
    tearDown(() => project.deleteSync(recursive: true));

    Future<void> setEnvironment(String env) async {
      final Map<String, dynamic> config = <String, dynamic>{
        'pwd': project.path,
        ...loadYaml('''
flutter_dir: ${project.path}
env:
  prod:
    windows:
      name: Cinderblock
      binary_name: cinderblock
      installer_id: 5E2A1C7B-9D44-4F1E-8B36-2C0F7A9D41E8
'''),
      };
      await (CommandRunner<dynamic>(
        'upcode',
        'test',
      )..addCommand(FlutterEnvironmentCommand(config))).run(<String>['flutter:environment', 'set', '--env', env]);
    }

    File windowsFile(String name) => File(join(project.path, 'windows', name));

    test('writes the environment\'s Windows identity for the build', () async {
      await setEnvironment('prod');

      expect(windowsFile('environment.cmake').readAsStringSync(), contains('set(BINARY_NAME "cinderblock")'));
      expect(windowsFile('environment.iss').readAsStringSync(), contains('#define AppName "Cinderblock"'));
    });

    test('removes what another environment wrote when this one has no windows section', () async {
      await setEnvironment('prod');
      await setEnvironment('staging');

      expect(windowsFile('environment.cmake').existsSync(), isFalse);
      expect(windowsFile('environment.iss').existsSync(), isFalse);
    });
  });
}
