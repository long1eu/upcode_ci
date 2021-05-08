// File created by
// Lung Razvan <long1eu>
// on 11/05/2020

import 'dart:convert';

import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';

mixin EnvironmentMixin on UpcodeCommand {
  @override
  void init() {
    baseConfig.addAll(<String, dynamic>{
      if (baseConfig.containsKey('env') &&
          baseConfig['env'] is Map &&
          baseConfig['env'].containsKey(env) &&
          baseConfig['env'][env] is Map)
        ...baseConfig['env'][env],
    });
  }

  String get rawEnv => argResults['env'];

  Map<String, dynamic> get flutterApiConfig {
    if (flutterConfig.isEmpty) {
      return flutterConfig;
    }

    String env = '';
    if (argResults.wasParsed('env')) {
      env = this.env;
    }
    return <String, dynamic>{
      for (MapEntry<String, dynamic> entry
          in flutterConfig.entries.where((MapEntry<String, dynamic> element) => element.value is! Map))
        entry.key: entry.value,
      for (var value in flutterConfig.entries
          .where((MapEntry<String, dynamic> element) => element.key == env && element.value is Map))
        ...value.value,
    };
  }

  Map<String, dynamic> get apiApiConfig {
    if (apiConfig.isEmpty) {
      return apiConfig;
    }

    String env = '';
    if (argResults.wasParsed('env')) {
      env = this.env;
    }
    return <String, dynamic>{
      for (MapEntry<String, dynamic> entry
          in apiConfig.entries.where((MapEntry<String, dynamic> element) => element.value is! Map))
        entry.key: entry.value,
      for (var value
          in apiConfig.entries.where((MapEntry<String, dynamic> element) => element.key == env && element.value is Map))
        ...value.value,
    };
  }

  String get env {
    if (!argResults.wasParsed('env')) {
      return null;
    }
    final String env = rawEnv;

    if (env.startsWith('feature/')) {
      final List<String> featureParts = env.split('feature/');

      if (featureParts[1].isEmpty) {
        throw StateError('When setting a new feature environment the name after \'feature/\' should not be empty.');
      } else if (!RegExp('[a-z0-9_-]+', caseSensitive: false).hasMatch(featureParts[1])) {
        throw StateError('The feature name should contain letters, numbers, dashes (\'-\') and underscores(\'_\').');
      }
    }

    return env.replaceAll('/', '_').replaceAll('-', '_').toLowerCase();
  }

  String get apiVersion => apiApiConfig['api_version'];

  String get apiBaseName => apiApiConfig['api_base_name'];

  String get gatewayBaseName => apiApiConfig['gateway_base_name'];

  String get apiBaseDisplayName => apiApiConfig['api_base_display_name'];

  String get cloudRunHash => apiApiConfig['cloud_run_hash'];

  String get serviceAccountEmail {
    final Map<String, dynamic> serviceAccount = jsonDecode(join(privateDir, 'service_account.json').readAsStringSync());
    return serviceAccount['client_email'];
  }

  String get hostSuffix {
    return env == 'prod' ? '' : '${env.replaceAll('_', '-')}';
  }

  String get apiVersionSuffix {
    return this.apiVersion == null ? '' : this.apiVersion;
  }

  String get gatewayName {
    return <String>[
      gatewayBaseName,
      if (apiVersionSuffix.isNotEmpty) apiVersionSuffix,
      if (hostSuffix.isNotEmpty) hostSuffix,
    ].join('-');
  }

  String get apiName {
    return <String>[
      apiBaseName,
      if (apiVersionSuffix.isNotEmpty) apiVersionSuffix,
      if (hostSuffix.isNotEmpty) hostSuffix,
    ].join('-');
  }

  String get apiHost {
    return '$apiName-$cloudRunHash.a.run.app';
  }

  String get gatewayHost {
    return '$gatewayName-$cloudRunHash.a.run.app';
  }

  String getApiConfigFile(Version version) {
    final String key = base64Encode(utf8.encode(join(privateDir, 'service_account.json').readAsStringSync()));
    final Map<String, dynamic> config = <String, dynamic>{
      ...apiApiConfig,
      'key': key,
      'projectId': projectId,
      'projectLocation': projectLocation,
      'version': '$version',
    };

    final StringBuffer buffer = StringBuffer()..writeln('export const config = {');
    for (var entry in config.entries) {
      buffer.writeln('  ${entry.key}: \'${entry.value}\',');
    }
    buffer //
      ..writeln('  env: \'$env\'')
      ..writeln('};');

    return buffer.toString();
  }
}
