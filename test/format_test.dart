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

  group('onlyChanged', () {
    const List<String> files = <String>['lib/main.dart', 'lib/model.dart'];

    test('keeps only what git reported, for a module at the root', () {
      final List<String> kept = onlyChanged('.', files, <String>{'lib/main.dart', 'other/x.dart'});

      expect(kept, <String>['lib/main.dart']);
    });

    test('prefixes a nested module before comparing', () {
      final List<String> kept = onlyChanged('tool', files, <String>{'tool/lib/model.dart'});

      expect(kept, <String>['lib/model.dart']);
    });

    test('an empty report keeps nothing, rather than falling back to every file', () {
      expect(onlyChanged('.', files, const <String>{}), isEmpty);
    });
  });

  group('changedFiles', () {
    late Directory repo;

    String run(List<String> arguments) {
      final ProcessResult result = Process.runSync('git', arguments, workingDirectory: repo.path);
      expect(result.exitCode, 0, reason: 'git ${arguments.join(' ')}: ${result.stderr}');
      return (result.stdout as String).trim();
    }

    void write(String file, [String contents = '']) {
      File(join(repo.path, file))
        ..createSync(recursive: true)
        ..writeAsStringSync(contents);
    }

    setUp(() {
      repo = Directory.systemTemp.createTempSync('upcode_changed');
      run(<String>['init', '-q']);
      run(<String>['config', 'user.email', 'test@example.com']);
      run(<String>['config', 'user.name', 'Test']);
      write('kept.dart');
      write('edited.dart');
      write('removed.dart');
      run(<String>['add', '-A']);
      run(<String>['commit', '-qm', 'base']);
    });

    tearDown(() => repo.deleteSync(recursive: true));

    test('reports uncommitted edits and additions, but not deletions or untouched files', () {
      write('edited.dart', '// changed');
      write('added.dart');
      File(join(repo.path, 'removed.dart')).deleteSync();

      final Set<String> changed = changedFiles(workingDirectory: repo.path);

      expect(changed, containsAll(<String>['edited.dart', 'added.dart']));
      expect(changed, isNot(contains('removed.dart')));
      expect(changed, isNot(contains('kept.dart')));
    });

    test('a rename contributes its new path only', () {
      run(<String>['mv', 'edited.dart', 'renamed.dart']);

      final Set<String> changed = changedFiles(workingDirectory: repo.path);

      expect(changed, contains('renamed.dart'));
      expect(changed, isNot(contains('edited.dart')));
    });

    test('since a ref includes what was committed after it', () {
      final String base = run(<String>['rev-parse', 'HEAD']);
      write('committed.dart');
      run(<String>['add', '-A']);
      run(<String>['commit', '-qm', 'later']);

      expect(changedFiles(since: base, workingDirectory: repo.path), contains('committed.dart'));
      expect(changedFiles(workingDirectory: repo.path), isNot(contains('committed.dart')));
    });

    test('a clean tree reports nothing', () {
      expect(changedFiles(workingDirectory: repo.path), isEmpty);
    });
  });
}
