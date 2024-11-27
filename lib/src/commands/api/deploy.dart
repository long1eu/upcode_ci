// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/src/arg_results.dart';
import 'package:http/http.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';

const String _kBaseImageName = 'gcr.io/endpoints-release/endpoints-runtime-serverless';

class ApiDeployCommand extends UpcodeCommand {
  ApiDeployCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(AllDeployCommand(config));
    addSubcommand(GcloudBuildImageCommand(config));

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
    stdout.writeln('Config id: ${serviceDeployResult['id']}');
    return serviceDeployResult['id'];
  }
}

class GcloudBuildImageCommand extends UpcodeCommand {
  GcloudBuildImageCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption('config_id', abbr: 'c', mandatory: true)
      ..addOption('service', abbr: 's', mandatory: true)
      ..addOption('project', abbr: 'p')
      ..addOption('esp_tag', abbr: 'v')
      ..addOption('zone', abbr: 'z')
      ..addOption('base_image', abbr: 'i');
  }

  @override
  final String name = 'gcloud_build_image';

  @override
  final String description =
      'Transcription of the gcloud_build_image command that you can find here https://github.com/GoogleCloudPlatform/esp-v2/blob/master/docker/serverless/gcloud_build_image';

  Future<String> _getEspFullVersion(String espTag) async {
    final CapturedOutput output = CapturedOutput();
    await execute(
      () => runCommand(
        'gcloud',
        <String>[
          'container',
          'images',
          'list-tags',
          _kBaseImageName,
          '--filter=tags~^$espTag\$',
          '--format=json',
        ],
        outputMode: OutputMode.capture,
        output: output,
        workingDirectory: apiDir,
      ),
      'Determining fully-qualified ESP version for tag: $espTag',
    );

    final List<Version> tags = <Version>[];
    for (final dynamic item in jsonDecode(output.stdout) as List<dynamic>) {
      String version = '';
      for (final String tag in List<String>.from(item['tags'])) {
        version = tag.length > version.length ? tag : version;
      }

      Version? parsedVersion;
      try {
        parsedVersion = Version.parse(version);
      } on FormatException catch (_) {
        // No-op
      }
      if (parsedVersion != null) {
        tags.add(parsedVersion);
      }
    }

    tags.sort();

    if (tags.isEmpty) {
      stderr.writeln('Did not find ESP version: $espTag');
      exit(1);
    }

    return tags.last.toString();
  }

  @override
  FutureOr<void> run() async {
    String espTag = '2';
    String zone = '';
    String baseImage = '';
    String? espFullVersion;

    final ArgResults result = argResults!;
    final String configId = result['config_id'];
    final String service = result['service'];
    final String project = result['project'] ?? projectId;

    if (result.wasParsed('esp_tag')) {
      espTag = result['v'];
    }
    if (result.wasParsed('zone')) {
      zone = result['zone'];
    }
    if (result.wasParsed('base_image')) {
      espFullVersion = 'custom';
      baseImage = result['base_image'];
    } else {
      baseImage = '$_kBaseImageName:$espTag';
    }

    stdout.writeln('Using base image: $baseImage');
    espFullVersion ??= await _getEspFullVersion(espTag);
    stdout.writeln('Building image for ESP version: $espFullVersion');

    final Directory tempDir = await Directory.systemTemp.createTemp('docker.');
    final String serviceJsonFilePath = '${tempDir.path}/service.json';

    final CapturedOutput output = CapturedOutput();
    await execute(
      () => runCommand(
        'gcloud',
        <String>['auth', 'print-access-token'],
        outputMode: OutputMode.capture,
        output: output,
        workingDirectory: tempDir.path,
      ),
      'Get gcloud token.',
    );

    final Response response = await get(
      Uri.parse(
        'https://servicemanagement.googleapis.com/v1/services/$service/configs/$configId?view=FULL',
      ),
      headers: <String, String>{
        'Authorization': 'Bearer ${output.stdout.split('\n').first}',
      },
    );

    if (response.statusCode != 200) {
      stderr.writeln('Failed to download service config');
      exit(1);
    }

    File(serviceJsonFilePath).writeAsStringSync(response.body);

    final String espArgs = config['esp_args'] ??
        '^++^--cors_preset=basic++--cors_allow_headers="keep-alive,user-agent,cache-control,content-type,content-transfer-encoding,x-accept-content-transfer-encoding,x-accept-response-streaming,x-user-agent,x-grpc-web,grpc-timeout,DNT,X-Requested-With,If-Modified-Since,Range,Authorization,x-api-key"++--cors_expose_headers="grpc-status,grpc-message"';

    final String dockerContent = '''
FROM $baseImage

USER root
ENV ENDPOINTS_SERVICE_PATH /etc/endpoints/service.json
COPY service.json \${ENDPOINTS_SERVICE_PATH}
RUN chown -R envoy:envoy \${ENDPOINTS_SERVICE_PATH} && chmod -R 755 \${ENDPOINTS_SERVICE_PATH}
USER envoy

ENV ESPv2_ARGS $espArgs

ENTRYPOINT ["/env_start_proxy.py"]
  ''';

    await File('${tempDir.path}/Dockerfile').writeAsString(dockerContent);

    String newImage = 'gcr.io/$project/endpoints-runtime-serverless:$service';
    if (zone.isNotEmpty) {
      newImage = '$zone.$newImage';
    }

    await execute(
      () => runCommand(
        'gcloud',
        <String>[
          'builds',
          'submit',
          '--tag',
          newImage,
          '.',
          '--project',
          project,
        ],
        workingDirectory: tempDir.path,
      ),
      'Build gateway image.',
    );

    await tempDir.delete(recursive: true);
  }
}

class GatewayDeployCommand extends UpcodeCommand with EnvironmentMixin {
  GatewayDeployCommand(Map<String, dynamic> config) : super(config) {
    argParser.addOption('env', abbr: 'e', help: 'The name of the environment you want to deploy the gateway for.');
  }

  @override
  final String name = 'gateway';

  @override
  final String description = 'Builds and deploys the gateway image using the configurationId';

  @override
  FutureOr<dynamic> run() async {
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
        workingDirectory: apiDockerfileDir,
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
    await runner!.run(<String>['api:deploy', 'gcloud_build_image', '-s', gatewayHost, '-c', configurationId]);
    await runner!.run(<String>['api:deploy', 'gateway', '--env', rawEnv]);
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
