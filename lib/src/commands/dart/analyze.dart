// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:upcode_ci/src/commands/command.dart';

class DartAnalyzeCommand extends UpcodeCommand {
  DartAnalyzeCommand(Map<String, dynamic> config) : super(config) {
    argParser.addMultiOption(
      'module',
      help: 'Select what modules you want to check.',
    );
  }

  @override
  final String name = 'dart:analyze';

  @override
  final String description = 'Runs the dart analyzer and exists with a non 0 code when there are issues.';

  @override
  FutureOr<dynamic> run() async {
    List<String> modules;
    if (argResults!.wasParsed('module')) {
      modules = List<String>.from(argResults!['module']).map((String item) => item.dirName).toList();
    } else {
      modules = analyzedModules;
    }

    for (final String module in modules) {
      await execute(
        () => runCommand(
          'dart',
          <String>['analyze'],
          workingDirectory: module,
        ),
        'Runs the dart analyzer in $module.',
      );
    }
  }
}
