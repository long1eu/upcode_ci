// File created by
// Lung Razvan <long1eu>
// on 11/05/2020

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

  Map<String, dynamic> get apiConfig {
    if (config.isEmpty) {
      return config;
    }

    String env = '';
    if (argResults.wasParsed('env')) {
      env = this.env;
    }
    return <String, dynamic>{
      for (MapEntry<String, dynamic> entry
          in config.entries.where((MapEntry<String, dynamic> element) => element.value is! Map))
        entry.key: entry.value,
      for (var value
          in config.entries.where((MapEntry<String, dynamic> element) => element.key == env && element.value is Map))
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
}
