import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:yaml/yaml.dart';

class _ProbeCommand extends UpcodeCommand with EnvironmentMixin {
  _ProbeCommand(super.config, this.onRun) {
    argParser.addOption('env');
  }

  final void Function(_ProbeCommand command) onRun;

  @override
  final String name = 'probe';

  @override
  final String description = 'Reads upcode.yaml values for tests.';

  @override
  void run() => onRun(this);
}

/// Parses [yaml] the way `bin/upcode.dart` does and returns what [read] sees
/// from inside a command run with [args].
Future<T> readConfig<T>(
  String yaml,
  T Function(_ProbeCommand command) read, {
  List<String> args = const <String>[],
}) async {
  final Map<String, dynamic> config = <String, dynamic>{'pwd': '.', ...loadYaml(yaml)};
  late T value;
  final _ProbeCommand probe = _ProbeCommand(config, (_ProbeCommand command) => value = read(command));
  await (CommandRunner<dynamic>('upcode', 'test')..addCommand(probe)).run(<String>['probe', ...args]);
  return value;
}

void main() {
  group('api.gateway_deadline_seconds', () {
    test('accepts an integer', () async {
      final double deadline = await readConfig(
        'api: {gateway_deadline_seconds: 30}',
        (_ProbeCommand command) => command.gatewayDeadlineSeconds,
      );

      expect(deadline, 30.0);
    });
  });

  group('api.images', () {
    test('uses the deadline_seconds set on the image', () async {
      final List<ApiImage> images = await readConfig(
        'api: {images: [{selector: "*", deadline_seconds: 20}]}',
        (_ProbeCommand command) => command.images,
      );

      expect(images.single.deadlineSeconds, 20.0);
    });

    test('falls back to gateway_deadline_seconds when the image sets none', () async {
      final List<ApiImage> images = await readConfig(
        'api: {gateway_deadline_seconds: 30.0, images: [{selector: "*"}]}',
        (_ProbeCommand command) => command.images,
      );

      expect(images.single.deadlineSeconds, 30.0);
    });
  });

  group('protos_dir', () {
    test('defaults to <flutter_dir>/res/protos', () async {
      final String dir = await readConfig(
        'flutter_dir: app',
        (_ProbeCommand command) => command.protoSrcDir,
      );

      expect(dir, join('app', 'res', 'protos'));
    });

    test('uses the configured directory', () async {
      final String dir = await readConfig(
        'flutter_dir: app\nprotos_dir: protos/src',
        (_ProbeCommand command) => command.protoSrcDir,
      );

      expect(dir, join('protos', 'src'));
    });

    test('is overridden by --protos_dir', () async {
      final String dir = await readConfig(
        'flutter_dir: app\nprotos_dir: protos/src',
        (_ProbeCommand command) => command.protoSrcDir,
        args: <String>['--protos_dir', 'other/protos'],
      );

      expect(dir, join('other', 'protos'));
    });
  });

  group('service account', () {
    late Directory privateDir;

    setUp(() => privateDir = Directory.systemTemp.createTempSync('upcode_private'));
    tearDown(() => privateDir.deleteSync(recursive: true));

    test('resolves <private_dir>/service_account.json', () async {
      final String key = join(privateDir.path, 'service_account.json');
      File(key).writeAsStringSync('{}');

      final String file = await readConfig(
        'private_dir: ${privateDir.path}',
        (_ProbeCommand command) => command.serviceAccountFile,
      );

      expect(file, key);
    });

    test('fails when private_dir is not set', () {
      expect(
        readConfig('flutter_dir: app', (_ProbeCommand command) => command.serviceAccountFile),
        throwsA(isA<StateError>().having((StateError e) => e.message, 'message', contains('private_dir'))),
      );
    });

    test('fails when service_account.json is missing', () {
      expect(
        readConfig('private_dir: ${privateDir.path}', (_ProbeCommand command) => command.serviceAccountFile),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains(join(privateDir.path, 'service_account.json')),
          ),
        ),
      );
    });
  });
}
