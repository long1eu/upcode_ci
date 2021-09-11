// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:path/path.dart';
import 'package:pub_semver/src/version.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/version_mixin.dart';

class ApiEnvironmentCommand extends UpcodeCommand {
  ApiEnvironmentCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(ApiSetEnvironmentCommand(config));
  }

  @override
  final String name = 'api:environment';

  @override
  final String description = 'Manage API environments.';
}

class ApiSetEnvironmentCommand extends UpcodeCommand with EnvironmentMixin, VersionMixin {
  ApiSetEnvironmentCommand(Map<String, dynamic> config) : super(config) {
    argParser //
      ..addOption('env', abbr: 'e')
      ..addOption('type', abbr: 't', defaultsTo: 'api', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'set';

  @override
  final String description = 'Set an already existing environment to API.';

  @override
  String get versionType => argResults['type'];

  void _updateYamlField(List<String> lines, String field, String value) {
    int index = lines.indexWhere((String element) => element.startsWith('$field:'));
    if (index == -1) {
      index = 2;
      lines.insert(2, '$field: ');
    }

    lines[index] = '$field: $value';
  }

  Future<void> _updateConfig() async {
    final Version version = await getVersion();
    final String data = getApiConfigFile(version);
    join(apiDir, 'src', 'config.ts').writeAsStringSync(data);
  }

  Future<void> _updateApiConfiguration() async {
    final List<String> lines = apiConfigFile.readAsLinesSync();
    _updateYamlField(lines, 'name', gatewayHost);
    _updateYamlField(lines, 'title', '$apiBaseDisplayName gRPC API $apiVersion${env == 'prod' ? '' : ' $env'}');

    final List<String> backend = <String>[
      'backend:',
      '  rules:',
      ...List<List<String>>.generate(
        images.length,
        (int index) {
          final ApiImage image = images[index];
          final String host = apiHosts[index];

          return <String>[
            '    - selector: "${image.selector}"',
            '      address: grpcs://$host',
          ];
        },
      ).expand((List<String> image) => image),
    ];

    final int index = lines.lastIndexWhere((String line) => line.startsWith('backend:'));
    apiConfigFile.writeAsStringSync(<String>[...lines.sublist(0, index), ...backend].join('\n'));
  }

  @override
  FutureOr<dynamic> run() async {
    await execute(_updateConfig, 'Saving server configuration in config.ts');
    await execute(_updateApiConfiguration, 'Saving api configuration in api_config.yaml');
  }
}
