// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';

class FlutterTestCommand extends UpcodeCommand {
  FlutterTestCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'flutter:test';

  @override
  final String description = 'Runs the all the test in modules.';

  @override
  FutureOr<dynamic> run() async {
    for (final String module in testedModules) {
      final bool isFlutter = join(module, 'pubspec.yaml').readAsStringSync().contains('sdk: flutter');

      if (isFlutter) {
        await execute(
          () => runCommand(
            'flutter',
            <String>['test'],
            workingDirectory: module,
          ),
          'Runs the all the test in the $module module.',
        );
      } else {
        await execute(
          () => runCommand(
            'pub',
            <String>['run', 'test'],
            workingDirectory: module,
          ),
          'Runs the all the test in the $module module.',
        );
      }
    }
  }
}
