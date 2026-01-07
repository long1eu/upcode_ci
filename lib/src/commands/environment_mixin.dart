// File created by
// Lung Razvan <long1eu>
// on 11/05/2020

import 'dart:convert';

import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:yaml/yaml.dart';

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

  String get rawEnv => argResults!['env'];

  Map<String, dynamic> get flutterApiConfig {
    if (flutterConfig.isEmpty) {
      return flutterConfig;
    }

    String env = '';
    if (argResults!.wasParsed('env')) {
      env = this.env!;
    }
    return <String, dynamic>{
      for (final MapEntry<String, dynamic> entry
          in flutterConfig.entries.where((MapEntry<String, dynamic> element) => element.value is! Map))
        entry.key: entry.value,
      for (final MapEntry<String, dynamic> value in flutterConfig.entries
          .where((MapEntry<String, dynamic> element) => element.key == env && element.value is Map))
        ...value.value,
    };
  }

  Map<String, dynamic> get apiApiConfig {
    if (apiConfig.isEmpty) {
      return apiConfig;
    }

    String env = '';
    if (argResults!.wasParsed('env')) {
      env = this.env!;
    }
    return <String, dynamic>{
      for (final MapEntry<String, dynamic> entry
          in apiConfig.entries.where((MapEntry<String, dynamic> element) => element.value is! Map))
        entry.key: entry.value,
      for (final MapEntry<String, dynamic> value
          in apiConfig.entries.where((MapEntry<String, dynamic> element) => element.key == env && element.value is Map))
        ...value.value,
    };
  }

  String? get env {
    if (!argResults!.wasParsed('env')) {
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

  String? get apiVersion => apiApiConfig['api_version'];

  String get apiBaseName {
    if (apiApiConfig['api_base_name'] == null) {
      throw StateError('You need to provide a value for "api_base_name" in your upcode.yaml file.');
    }

    return apiApiConfig['api_base_name'];
  }

  String get gatewayBaseName => apiApiConfig['gateway_base_name'];

  double get gatewayDeadlineSeconds => apiApiConfig['gateway_deadline_seconds'] ?? 15.0;

  String get apiBaseDisplayName => apiApiConfig['api_base_display_name'];

  String get cloudRunHash => apiApiConfig['cloud_run_hash'];

  String get serviceAccountEmail {
    final Map<String, dynamic> serviceAccount = jsonDecode(join(privateDir, 'service_account.json').readAsStringSync());
    return serviceAccount['client_email'];
  }

  String get hostSuffix {
    return env == 'prod' ? '' : '${env?.replaceAll('_', '-')}';
  }

  String get apiVersionSuffix => apiVersion ?? '';

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

  List<String> get apiNames {
    return images.map((ApiImage image) => '$apiName${image.name.isEmpty ? '' : '-${image.name}'}').toList();
  }

  List<String> get cloudSqlInstances {
    final YamlList? instances = apiConfig['cloudsql_instances'];

    if (instances == null) {
      return <String>[];
    }

    return instances.map((dynamic name) => '$name').toList();
  }

  List<String> get apiHosts {
    return apiNames.map((String name) => '$name-$cloudRunHash.a.run.app').toList();
  }

  String get gatewayHost {
    return '$gatewayName-$cloudRunHash.a.run.app';
  }

  List<ApiImage> get images {
    final List<Map<dynamic, dynamic>> images =
        List<Map<dynamic, dynamic>>.from(apiConfig['images'] ?? <Map<String, dynamic>>[]);

    if (images.isEmpty) {
      images.add(<String, dynamic>{'selector': '*', 'name': '', 'deadline_seconds': gatewayDeadlineSeconds});
    }

    return images.map((Map<dynamic, dynamic> image) {
      return ApiImage(
        name: image['name'] ?? '',
        selector: image['selector'] ?? '*',
        deadlineSeconds: double.tryParse('deadline_seconds') ?? gatewayDeadlineSeconds,
        cloudSqlInstances: image['cloudsql_instances'] //
                ?.map((dynamic name) => '$name')
                ?.cast<String>()
                ?.toList() ??
            cloudSqlInstances,
      );
    }).toList();
  }
}

class ApiImage {
  ApiImage({
    required this.name,
    required this.selector,
    required this.deadlineSeconds,
    required this.cloudSqlInstances,
  });

  final String name;
  final String selector;
  final double deadlineSeconds;
  final List<String> cloudSqlInstances;
}
