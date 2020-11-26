// File created by
// Lung Razvan <long1eu>
// on 11/05/2020

import 'package:upcode_ci/src/commands/command.dart';

mixin EnvironmentMixin on UpcodeCommand {
  String get rawEnv => argResults['env'];

  Map<String, dynamic> get apiConfig {
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
    final String env = rawEnv;
    if (env != 'prod' && env != 'dev' && !env.startsWith('feature/')) {
      throw StateError('The environment can only be \'prod\', \'dev\' or \'feature/*\'.');
    }

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
