// File created by
// Lung Razvan <long1eu>
// on 10/05/2020

import 'dart:async';

import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/version_mixin.dart';

class ApiVersionCommand extends UpcodeCommand {
  ApiVersionCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(ApiIncrementVersionCommand(config));
    addSubcommand(ApiReadVersionCommand(config));
  }

  @override
  final String name = 'api:version';

  @override
  final String description = 'Update the api version base on the cloud version value.';
}

class ApiIncrementVersionCommand extends UpcodeCommand with VersionMixin {
  ApiIncrementVersionCommand(Map<String, dynamic> config) : super(config) {
    argParser.addOption('type', abbr: 't', defaultsTo: 'api', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'increment';

  @override
  final String description =
      'Increment the cloud version of the api app and update the config files to reflect that version.';

  ApiVersionCommand get parent => super.parent;

  @override
  String get versionType => argResults['type'];

  @override
  FutureOr<void> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    Version version = await execute(getVersion, 'Get current version from cloud');
    version = await execute(version.patchVersion, 'Increment api version');
    await execute(() => setVersion(version), 'Set version back to cloud: $version');
    await runner.run(['api:version', 'read']);
  }
}

class ApiReadVersionCommand extends UpcodeCommand with VersionMixin {
  ApiReadVersionCommand(Map<String, dynamic> config) : super(config) {
    argParser.addOption('type', abbr: 't', defaultsTo: 'api', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'read';

  @override
  final String description =
      'Read the cloud version of the api app and update the config files to reflect that version.';

  ApiVersionCommand get parent => super.parent;

  @override
  String get versionType => argResults['type'];

  Future<void> _updateConfig() async {
    final Version version = await getVersion();
    final String data = join(apiDir, 'src', 'config.ts')
        .readAsStringSync()
        .replaceFirstMapped(RegExp('  version: "(.+?)"'), (_) => '$version');
    join(apiDir, 'src', 'config.ts').writeAsStringSync(data);
  }

  @override
  FutureOr<void> run() async {
    await execute(_updateConfig, 'Updating config.ts');
  }
}
