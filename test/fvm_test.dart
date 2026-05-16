import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:upcode_ci/src/commands/command.dart';

void main() {
  group('isFvmConfigured', () {
    late Directory root;

    setUp(() => root = Directory.systemTemp.createTempSync('fvm_test'));
    tearDown(() => root.deleteSync(recursive: true));

    test('returns true when the directory contains a .fvmrc file', () {
      File(join(root.path, '.fvmrc')).writeAsStringSync('{"flutter": "3.2.1"}');

      expect(isFvmConfigured(root.path), isTrue);
    });

    test('returns true when the directory contains a .fvm directory', () {
      Directory(join(root.path, '.fvm')).createSync();

      expect(isFvmConfigured(root.path), isTrue);
    });

    test('returns true for a sub-package nested in an fvm-configured repo', () {
      File(join(root.path, '.fvmrc')).writeAsStringSync('{"flutter": "3.2.1"}');
      final Directory subPackage = Directory(join(root.path, 'packages', 'app'))
        ..createSync(recursive: true);

      expect(isFvmConfigured(subPackage.path), isTrue);
    });

    test('returns false for a directory tree without fvm config', () {
      final Directory subPackage = Directory(join(root.path, 'packages', 'app'))
        ..createSync(recursive: true);

      expect(isFvmConfigured(subPackage.path), isFalse);
    });
  });
}
