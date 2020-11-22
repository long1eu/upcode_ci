// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:upcode_ci/src/commands/command.dart';

class FlutterTestCommand extends UpcodeCommand {
  FlutterTestCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'flutter:test';

  @override
  final String description = 'Runs the all the test in the flutter module.';

  @override
  FutureOr<dynamic> run() async {
    await execute(() => runCommand('flutter', <String>['test'], workingDirectory: flutterDir), description);
  }
}
