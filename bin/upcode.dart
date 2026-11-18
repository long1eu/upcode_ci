// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:upcode_ci/src/commands/index.dart';
import 'package:yaml/yaml.dart';

/// Where the settings are read from when neither `--config` nor the
/// `UPCODE_CONFIG` environment variable names another file.
const String defaultConfigPath = './upcode.yaml';

void main(List<String> arguments) {
  // The settings file is read before any command exists, so its option is
  // taken out of the arguments here: `--config <file>` or `--config=<file>`,
  // anywhere on the line.
  final List<String> args = <String>[];
  String? configPath = Platform.environment['UPCODE_CONFIG'];
  for (int i = 0; i < arguments.length; i++) {
    final String argument = arguments[i];
    if (argument == '--config') {
      if (i + 1 >= arguments.length) {
        stderr.writeln('--config needs the path of a settings file.');
        exit(64);
      }
      configPath = arguments[++i];
    } else if (argument.startsWith('--config=')) {
      configPath = argument.substring('--config='.length);
    } else {
      args.add(argument);
    }
  }
  if (configPath == null || configPath.isEmpty) {
    configPath = defaultConfigPath;
  }

  final File upcode = File(configPath);
  if (!upcode.existsSync()) {
    stderr.writeln(
      configPath == defaultConfigPath
          ? 'You need to call this command from the same directory as you upcode.yaml file, '
                'or name the file with --config <file> or UPCODE_CONFIG.'
          : 'No settings file at $configPath.',
    );
    exit(1);
  }

  // Paths in the settings are relative to the directory the command is run
  // from, wherever the settings file itself is kept (it may sit in a private,
  // encrypted folder). For ./upcode.yaml that is the file's own directory,
  // as it always was.
  final Map<String, dynamic> config = <String, dynamic>{
    'pwd': Directory.current.absolute.path,
    ...loadYaml(upcode.readAsStringSync()),
  };

  final CommandRunner<dynamic> runner = CommandRunner<dynamic>(
    'upcode',
    'Provides useful automation tools',
  );
  // Shown by --help; the value was already read above.
  runner.argParser.addOption(
    'config',
    help:
        'The settings file to read instead of ./upcode.yaml. Paths in it stay relative to the '
        'directory the command is run from. The UPCODE_CONFIG environment variable does the same.',
    valueHelp: 'file',
  );
  runner
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
