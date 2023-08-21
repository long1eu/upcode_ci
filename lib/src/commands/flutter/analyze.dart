// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:upcode_ci/src/commands/command.dart';

class FlutterAnalyzeCommand extends UpcodeCommand {
  FlutterAnalyzeCommand(Map<String, dynamic> config) : super(config);
  @override
  final String name = 'flutter:analyze';

  @override
  final String description = 'Runs the dart analyzer and exists with a non 0 code when there are issues.';

  @override
  FutureOr<dynamic> run() async {
    for (final String module in analyzedModules) {
      await execute(
        () => runFlutter(
          <String>['analyze'],
          workingDirectory: module,
        ),
        'Runs the dart analyzer in $module.',
      );
    }
  }
}
