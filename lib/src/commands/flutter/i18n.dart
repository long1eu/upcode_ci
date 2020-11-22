// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';

class FlutterI18nCommand extends UpcodeCommand {
  FlutterI18nCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'flutter:i18n';

  @override
  final String description = 'Generate internalization file for Flutter app.';

  @override
  FutureOr<dynamic> run() async {
    await execute(
          () =>
          runCommand(
            'dart',
            <String>[
              join(toolsDir, 'flutter_l10n', 'bin', 'main.dart'),
              '-s',
              flutterResDir,
              '-o',
              join(flutterGeneratedDir, 'i18n'),
            ],
            workingDirectory: pwd,
          ),
      description,
    );
  }
}
