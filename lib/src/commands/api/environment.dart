// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:pub_semver/src/version.dart';
import 'package:strings/strings.dart' show camelize;
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
  String get versionType => argResults!['type'];

  void _updateYamlField(List<String> lines, String field, String value) {
    int index = lines.indexWhere((String element) => element.startsWith('$field:'));
    if (index == -1) {
      index = 2;
      lines.insert(2, '$field: ');
    }

    lines[index] = '$field: $value';
  }

  void _writeJsApiConfigFile(Version? version) {
    final String key = base64Encode(utf8.encode(join(privateDir, 'service_account.json').readAsStringSync()));
    final Map<String, dynamic> config = <String, dynamic>{
      ...apiApiConfig,
      'key': key,
      'projectId': projectId,
      'projectLocation': projectLocation,
      if (version != null) 'version': '$version',
    };

    final StringBuffer buffer = StringBuffer()..writeln('export const config = {');
    for (final MapEntry<String, dynamic> entry in config.entries) {
      buffer.writeln('  ${entry.key}: \'${entry.value}\',');
    }
    buffer //
      ..writeln('  env: \'$env\'')
      ..writeln('};');

    join(apiOutDir, 'config.ts').writeAsStringSync(buffer.toString());
  }

  void _writeDartApiConfigFile(Version? version) {
    final String key = base64Encode(utf8.encode(join(privateDir, 'service_account.json').readAsStringSync()));
    final Map<String, dynamic> config = <String, dynamic>{
      ...apiApiConfig,
      'key': key,
      'project_id': projectId,
      'project_location': projectLocation,
      if (version != null) 'version': '$version',
    };

    final StringBuffer buffer = StringBuffer() //
      ..writeln('// ignore: avoid_classes_with_only_static_members')
      ..writeln('class Config {');
    if (argResults!.wasParsed('env')) {
      buffer.writeln('  static const String environment = \'$env\';');
    }

    for (final String key in config.keys) {
      String variableName = camelize(key);
      final List<String> parts = variableName.split('');
      variableName = <String>[parts.first.toLowerCase(), ...parts.skip(1)].join('');
      buffer.writeln('  static const String $variableName = \'${config[key]}\';');
    }
    buffer //
      ..writeln('}')
      ..writeln('');

    join(apiOutDir, 'config.dart').writeAsStringSync(buffer.toString());
  }

  Future<void> _updateConfig() async {
    Version? version;
    try {
      version = await getVersion();
    } catch (_) {}
    if (isDartBackend) {
      _writeDartApiConfigFile(version);
    } else {
      _writeJsApiConfigFile(version);
    }
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
    await execute(_updateConfig, 'Saving server configuration');
    await execute(_updateApiConfiguration, 'Saving api configuration in api_config.yaml');
  }
}
