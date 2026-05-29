// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:upcode_ci/src/commands/index.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) {
  final File upcode = File('./upcode.yaml');
  if (!upcode.existsSync()) {
    stderr.writeln('You need to call this command from the same directory as you upcode.yaml file.');
    exit(1);
  }

  final Map<String, dynamic> config = <String, dynamic>{
    'pwd': upcode.parent.absolute.path,
    ...loadYaml(upcode.readAsStringSync()),
  };

  CommandRunner<dynamic>('upcode', 'Provides useful automation tools')
    ..addCommand(DartFormatCommand(config))
    ..addCommand(DartAnalyzeCommand(config))
    ..addCommand(FlutterGenerateCommand(config))
    ..addCommand(FlutterI18nCommand(config))
    ..addCommand(FlutterBuildRunnerCommand(config))
    ..addCommand(FlutterVersionCommand(config))
    ..addCommand(FadCommand(config))
    ..addCommand(FlutterFastlaneDeployCommand(config))
    ..addCommand(FlutterEnvironmentCommand(config))
    ..addCommand(FlutterAnalyzeCommand(config))
    ..addCommand(FlutterFormatCommand(config))
    ..addCommand(FlutterTestCommand(config))
    ..addCommand(TestLabCommand(config))
    ..addCommand(SaveReleaseNotesCommand(config))
    ..addCommand(ProtosCommand(config))
    ..addCommand(ApiDeployCommand(config))
    ..addCommand(ApiEnvironmentCommand(config))
    ..addCommand(ApiVersionCommand(config))
    ..addCommand(EnvironmentCommand(config))
    ..addCommand(GoogleCommand(config))
    ..run(args);
}
