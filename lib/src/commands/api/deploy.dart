// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';

import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';

class ApiDeployCommand extends UpcodeCommand {
  ApiDeployCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(AllDeployCommand(config));

    addSubcommand(EndpointsDeployCommand(config));
    addSubcommand(GatewayDeployCommand(config));
    addSubcommand(ServiceDeployCommand(config));
  }

  @override
  final String name = 'api:deploy';

  @override
  final String description = 'API deploy functions';
}

/// This command deploy the api configuration and returns the configurationId
class EndpointsDeployCommand extends UpcodeCommand {
  EndpointsDeployCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'endpoints';

  @override
  final String description =
      'Deploys the endpoints configuration. Make sure you set the environment first before calling this.';

  @override
  FutureOr<dynamic> run() async {
    await runner!.run(<String>['protos', '--descriptor']);

    final CapturedOutput capturedOutput = CapturedOutput();
    await execute(
      () => runCommand(
        'gcloud',
        <String>[
          'endpoints',
          'services',
          'deploy',
          apiDescriptor,
          apiConfigFile,
          '--format="json"',
          '--project',
          projectId,
          '-q',
        ],
        outputMode: OutputMode.capture,
        output: capturedOutput,
        workingDirectory: pwd,
      ),
      'Deploy endpoints service',
    );

    final Map<String, dynamic> serviceDeployResult =
        Map<String, dynamic>.from(jsonDecode(capturedOutput.stdout)['serviceConfig']);
    print(serviceDeployResult['id']);
    return serviceDeployResult['id'];
  }
}

class GatewayDeployCommand extends UpcodeCommand with EnvironmentMixin {
  GatewayDeployCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption('env', abbr: 'e', help: 'The name of the environment you want to deploy the gateway for.')
      ..addOption(
        'configuration_id',
        abbr: 'c',
        help: 'The configuration id received when deploying the endpoints configuration.',
      );
  }

  @override
  final String name = 'gateway';

  @override
  final String description = 'Builds and deploys the gateway image using the configurationId';

  @override
  FutureOr<dynamic> run() async {
    await runner!.run(<String>['api:environment', 'set', '--env', rawEnv]);
    await execute(
      () => runCommand(
        './gcloud_build_image',
        <String>['-s', gatewayHost, '-c', argResults!['configuration_id'], '-p', projectId],
        workingDirectory: apiDir,
      ),
      'Configure the gateway',
    );

    final int minInstances = int.parse('${apiConfig['min_instances'] ?? 0}');
    await execute(
      () => runCommand(
        'gcloud',
        <String>[
          'run',
          'deploy',
          gatewayName,
          if (minInstances > 0) ...<String>['--min-instances', '$minInstances'],
          '--image',
          'gcr.io/$projectId/endpoints-runtime-serverless:$gatewayHost',
          '--allow-unauthenticated',
          '--platform',
          'managed',
          '--region',
          projectLocation,
          '--service-account',
          serviceAccountEmail,
          '--labels',
          'env=$env',
          '--timeout',
          '60',
          '--project',
          projectId,
          '-q'
        ],
        workingDirectory: pwd,
      ),
      'Deploy gateway',
    );
  }
}

class ServiceDeployCommand extends UpcodeCommand with EnvironmentMixin {
  ServiceDeployCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption('env', abbr: 'e', help: 'The name of the environment you want to deploy the gateway for.')
      ..addOption('image', abbr: 'i', help: 'The name of the image you want to deploy as defined in upcode.yaml.');
  }

  @override
  final String name = 'service';

  @override
  final String description = 'Builds and deploys the service image. This assumes you already set the environment.';

  Future<void> _deployImage(String apiName, List<String> cloudSqlInstances, int minInstances) async {
    final String imageUrl = 'gcr.io/$projectId/$apiName';

    await execute(
      () => runCommand(
        'gcloud',
        <String>[
          'builds',
          'submit',
          '--tag',
          imageUrl,
          '--project',
          projectId,
        ],
        workingDirectory: apiDir,
      ),
      'Build service image',
    );

    await execute(
      () => runCommand(
        'gcloud',
        <String>[
          'run',
          'deploy',
          apiName,
          if (minInstances > 0) ...<String>['--min-instances', '$minInstances'],
          '--image',
          imageUrl,
          '--platform',
          'managed',
          '--region',
          projectLocation,
          '--service-account',
          serviceAccountEmail,
          '--labels',
          'env=$env',
          '--timeout',
          '60',
          '--project',
          projectId,
          if (cloudSqlInstances.isNotEmpty) ...<String>[
            '--set-cloudsql-instances',
            cloudSqlInstances.join(','),
          ],
          '-q'
        ],
        workingDirectory: apiDir,
      ),
      'Deploy service',
    );
  }

  @override
  FutureOr<dynamic> run() async {
    await runner!.run(<String>['api:environment', 'set', '--env', rawEnv]);

    if (!isDartBackend) {
      await runner!.run(<String>['api:version', 'read']);
      await execute(
        () => runCommand('npm', <String>['run', 'build'], workingDirectory: apiDir),
        'Build service sources',
      );
    }

    final int minInstances = int.parse('${apiConfig['min_instances'] ?? 0}');
    if (argResults!.wasParsed('image')) {
      final String name = argResults!['image'];

      final int index = images.indexWhere((ApiImage image) => image.name == name);
      await _deployImage(apiNames[index], images[index].cloudSqlInstances, minInstances);
    } else {
      for (final String apiName in apiNames) {
        await _deployImage(apiName, cloudSqlInstances, minInstances);
      }
    }
  }
}

class AllDeployCommand extends UpcodeCommand with EnvironmentMixin {
  AllDeployCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption('env', abbr: 'e', help: 'The name of the environment you want to deploy the gateway for.')
      ..addOption('image', abbr: 'i', help: 'The name of the image you want to deploy as defined in upcode.yaml.')
      ..addFlag('deploy-service',
          defaultsTo: true, help: 'Whether you want ot deploy the service or just the api and gateway.');
  }

  @override
  final String name = 'all';

  @override
  final String description = 'Builds and deploy all the necessary files on the specified environment.';

  @override
  FutureOr<dynamic> run() async {
    await runner!.run(<String>['protos', '--backend']);
    await runner!.run(<String>['api:environment', 'set', '--env', rawEnv]);
    final String configurationId = await runner!.run(<String>['api:deploy', 'endpoints']);
    await runner!.run(<String>['api:deploy', 'gateway', '--env', rawEnv, '--configuration_id', configurationId]);
    final bool deployService = argResults!['deploy-service'];

    if (deployService) {
      await runner!.run(<String>[
        'api:deploy',
        'service',
        '--env',
        rawEnv,
        if (argResults!.wasParsed('image')) ...<String>[
          '--image',
          argResults!['image'],
        ],
      ]);
    }
  }
}
