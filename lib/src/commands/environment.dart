// File created by
// Lung Razvan <long1eu>
// on 11/05/2020

import 'dart:async';

import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';

class EnvironmentCommand extends UpcodeCommand with EnvironmentMixin {
  EnvironmentCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(SetEnvironmentCommand(config));
  }

  @override
  final String name = 'environment';

  @override
  final String description = 'Adds or remove environments';
}

class SetEnvironmentCommand extends UpcodeCommand with EnvironmentMixin {
  SetEnvironmentCommand(Map<String, dynamic> config) : super(config) {
    argParser.addOption('env', abbr: 'e');
  }

  @override
  final String name = 'set';

  @override
  final String description = 'Set the environment for both API and Flutter app.';

  @override
  FutureOr<dynamic> run() async {
    await runner!.run(<String>['api:environment', 'set', '--env', rawEnv]);
    await runner!.run(<String>['flutter:environment', 'set', '--env', rawEnv]);
  }
}
