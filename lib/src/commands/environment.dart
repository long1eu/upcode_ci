// File created by
// Lung Razvan <long1eu>
// on 11/05/2020

import 'dart:async';
import 'dart:io';

import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';

import 'command.dart';

class EnvironmentCommand extends UpcodeCommand with EnvironmentMixin {
  EnvironmentCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(SetEnvironmentCommand(config));
    addSubcommand(CreateEnvironmentCommand(config));
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

class CreateEnvironmentCommand extends UpcodeCommand with EnvironmentMixin {
  CreateEnvironmentCommand(Map<String, dynamic> config) : super(config) {
    argParser.addOption('env', abbr: 'e');
  }

  @override
  final String name = 'create';

  @override
  final String description = 'create a new environment';

  Future<void> _deployInitialGateway() async {
    final String envSuffix = env == 'prod' ? '' : '-${env!.replaceAll('_', '-')}';
    final String apiVersion = apiApiConfig['api_version'] == null ? '' : '-${apiApiConfig['api_version']}';
    final String gatewayName = '$gatewayBaseName$apiVersion$envSuffix';

    await runCommand(
      'gcloud',
      <String>[
        'run',
        'deploy',
        gatewayName,
        '--image',
        'gcr.io/endpoints-release/endpoints-runtime-serverless:2',
        '--allow-unauthenticated',
        '--platform',
        'managed',
        '--region',
        projectLocation,
        '--format',
        'json',
        '--project',
        projectId,
        '-q'
      ],
      workingDirectory: pwd,
    );
  }

  @override
  FutureOr<dynamic> run() async {
    await execute(_deployInitialGateway, 'Deploy the initial gateway');
    stdout.writeln('Add the "cloud_run_hash" to your upcode.yaml file under the "api" root and press Enter/Return.');
    stdin.readLineSync();
    await runner!.run(<String>['api:deploy', 'all', '--env', rawEnv]);
  }
}
