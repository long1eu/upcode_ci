import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:upcode_ci/src/commands/command.dart';

void main() {
  group('formattableFiles', () {
    late Directory module;

    void touch(String file) {
      File(join(module.path, file))
        ..createSync(recursive: true)
        ..writeAsStringSync('');
    }

    setUp(() {
      module = Directory.systemTemp.createTempSync('upcode_format');
      <String>[
        'lib/main.dart',
        'lib/l10n/strings.dart',
        'lib/api/service.pb.dart',
        'lib/model.g.dart',
        'root.pb.dart',
        'README.md',
      ].forEach(touch);
    });
    tearDown(() => module.deleteSync(recursive: true));

    List<String> files(List<String> exclude) {
      return formattableFiles(module.path, <Glob>[for (final String pattern in exclude) Glob(pattern)])..sort();
    }

    test('lists Dart files except generated ones when nothing is excluded', () {
      expect(files(<String>[]), <String>[
        join('lib', 'api', 'service.pb.dart'),
        join('lib', 'l10n', 'strings.dart'),
        join('lib', 'main.dart'),
        'root.pb.dart',
      ]);
    });

    test('skips files matching the exclude globs, relative to the module', () {
      expect(files(<String>['lib/l10n/**', '**/*.pb.dart']), <String>[join('lib', 'main.dart')]);
    });
  });
}
