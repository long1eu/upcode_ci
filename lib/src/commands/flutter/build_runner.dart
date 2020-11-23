// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:upcode_ci/src/commands/command.dart';

class FlutterBuildRunnerCommand extends UpcodeCommand {
  FlutterBuildRunnerCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'flutter:buildrunner';

  @override
  final String description = 'Use build_runner to generate Flutter files.';

  @override
  FutureOr<dynamic> run() async {
    for (final String module in generatedFilesModules) {
      await execute(() => runCommand('flutter', <String>['pub', 'get'], workingDirectory: module), description);
      await execute(
        () => runCommand(
          'flutter',
          <String>['pub', 'pub', 'run', 'build_runner', 'build', '--delete-conflicting-outputs'],
          workingDirectory: module,
        ),
        description,
      );
    }
  }
}
