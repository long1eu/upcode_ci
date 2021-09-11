// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';

class FlutterTestCommand extends UpcodeCommand {
  FlutterTestCommand(Map<String, dynamic> config) : super(config) {
    argParser.addFlag(
      'coverage',
      abbr: 'c',
      help: 'Whether to generate the lcov.info file or not',
      defaultsTo: true,
    );
  }

  @override
  final String name = 'flutter:test';

  @override
  final String description = 'Runs the all the test in modules.';

  @override
  FutureOr<dynamic> run() async {
    final bool generatedCoverage = argResults['coverage'];
    for (final String module in testedModules) {
      final bool isFlutter = join(module, 'pubspec.yaml').readAsStringSync().contains('sdk: flutter');

      if (isFlutter) {
        await execute(
          () => runCommand('flutter', <String>['pub', 'get'], workingDirectory: module),
          'flutter pub get in $module',
        );
        await execute(
          () => runCommand(
            'flutter',
            <String>[
              'test',
              if (generatedCoverage) '--coverage',
            ],
            workingDirectory: module,
          ),
          'Runs the all the test in the $module module.',
        );
      } else {
        await execute(
          () => runCommand('pub', <String>['get'], workingDirectory: module),
          'pub get in $module',
        );

        await execute(
          () => runCommand(
            'pub',
            <String>['run', if (generatedCoverage) 'test_coverage' else 'test'],
            workingDirectory: module,
          ),
          'Runs the all the test in the $module module.',
        );
      }
    }
  }
}
