// File created by
// Lung Razvan <long1eu>
// on 10/05/2020

import 'dart:async';
import 'dart:io';

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

  @override
  ApiVersionCommand get parent => super.parent! as ApiVersionCommand;

  @override
  String get versionType => argResults!['type'];

  @override
  FutureOr<void> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    Version version = await execute(getVersion, 'Get current version from cloud');
    version = await execute(version.patchVersion, 'Increment api version');
    await execute(() => setVersion(version), 'Set version back to cloud: $version');
    await runner!.run(<String>['api:version', 'read']);
  }
}

class ApiReadVersionCommand extends UpcodeCommand with VersionMixin {
  ApiReadVersionCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption('env', abbr: 'e')
      ..addOption('type', abbr: 't', defaultsTo: 'api', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'read';

  @override
  final String description =
      'Read the cloud version of the api app and update the config files to reflect that version.';

  @override
  ApiVersionCommand get parent => super.parent! as ApiVersionCommand;

  @override
  String get versionType {
    if (argResults!.wasParsed('type')) {
      return argResults!['type'];
    } else {
      return super.versionType;
    }
  }

  void _updateYaml(String versionName, int versionCode) {
    final String pubspecFile = join(apiDir, 'pubspec.yaml');

    String yaml = pubspecFile.readAsStringSync();
    if (!yaml.contains('versionCode')) {
      yaml = yaml.replaceAllMapped(RegExp('version: (.+)'), (_) => 'version: $versionName\nversionCode: $versionCode');
    } else {
      yaml = yaml.replaceAllMapped(RegExp('version: (.+)'), (_) => 'version: $versionName');
      yaml = yaml.replaceAllMapped(RegExp('versionCode: (.+)'), (_) => 'versionCode: $versionCode');
    }
    pubspecFile.writeAsStringSync(yaml);
  }

  void _updateFlutter(String versionName, int versionCode) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('import \'package:pub_semver/pub_semver.dart\' as semver;')
      ..writeln()
      ..writeln('// ignore: avoid_classes_with_only_static_members')
      ..writeln('class Version {')
      ..writeln('  static const String versionName = \'$versionName\';')
      ..writeln('  static const int versionCode = $versionCode;')
      ..writeln('  static final semver.Version version = semver.Version.parse(versionName);')
      ..writeln('}')
      ..writeln('');

    join(flutterGeneratedDir, 'version.dart').writeAsStringSync(buffer.toString());
  }

  @override
  FutureOr<void> run() async {
    Version? version;
    try {
      version = await getVersion();
    } catch (_) {}

    if (isDartBackend) {
      if (version == null) {
        stderr.writeln('You need to specify a version.');
        exit(1);
      }
      if (!dartApiGeneratedDir.dir.existsSync()) {
        dartApiGeneratedDir.dir.createSync(recursive: true);
      }

      await execute(() => _updateYaml(version!.versionName, version.versionCode), 'Update pubspec.yaml file');
      await execute(() => _updateFlutter(version!.versionName, version.versionCode), 'Updating version.dart');
    } else {
      String data = join(apiDir, 'src', 'config.ts').readAsStringSync();
      if (version != null) {
        data = data.replaceFirstMapped(RegExp('  version: "(.+?)"'), (_) => '$version');
      }
      join(apiDir, 'src', 'config.ts').writeAsStringSync(data);
    }
    exit(0);
  }
}
