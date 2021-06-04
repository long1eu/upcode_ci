// File created by
// Lung Razvan <long1eu>
// on 10/05/2020

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/version_mixin.dart';

class FlutterVersionCommand extends UpcodeCommand {
  FlutterVersionCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(FlutterIncrementVersionCommand(config));
    addSubcommand(FlutterReadVersionCommand(config));
    addSubcommand(FlutterSetVersionCommand(config));
  }

  @override
  final String name = 'flutter:version';

  @override
  final String description = 'Update the flutter app version base on the cloud version value.';
}

class FlutterIncrementVersionCommand extends UpcodeCommand with VersionMixin {
  FlutterIncrementVersionCommand(Map<String, dynamic> config) : super(config) {
    argParser //
      ..addOption('env', abbr: 'e')
      ..addOption('type', abbr: 't', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'increment';

  @override
  final String description =
      'Increment the cloud version of the Flutter app and update the flutter files to reflect that version.';

  FlutterVersionCommand get parent => super.parent;

  @override
  String get versionType {
    if (argResults.wasParsed('type')) {
      return argResults['type'];
    } else {
      return super.versionType;
    }
  }

  @override
  FutureOr<void> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    Version version = await execute(getVersion, 'Get current version from cloud');
    version = await execute(version.increment, 'Increment Flutter version');
    await execute(() => setVersion(version), 'Set version back to cloud: $version');
    await runner.run(['flutter:version', 'read', ...argResults.arguments]);
  }
}

class FlutterReadVersionCommand extends UpcodeCommand with VersionMixin, EnvironmentMixin {
  FlutterReadVersionCommand(Map<String, dynamic> config) : super(config) {
    argParser //
      ..addOption('env', abbr: 'e')
      ..addOption('type', abbr: 't', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'read';

  @override
  final String description =
      'Read the cloud version of the Flutter app and update the flutter files to reflect that version.';

  FlutterVersionCommand get parent => super.parent;

  @override
  String get versionType {
    if (argResults.wasParsed('type')) {
      return argResults['type'];
    } else {
      return super.versionType;
    }
  }

  @override
  FutureOr<void> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    Version version = await getVersion();
    await execute(
      () => runner.run(['flutter:version', 'set', '--version', version.toString(), ...argResults.arguments]),
      'Setting version $version',
    );
  }
}

class FlutterSetVersionCommand extends UpcodeCommand with VersionMixin, EnvironmentMixin {
  FlutterSetVersionCommand(Map<String, dynamic> config) : super(config) {
    argParser //
      ..addOption('env', abbr: 'e')
      ..addFlag('update-cloud', help: 'Mirror the change in cloud also')
      ..addOption('version', abbr: 'v')
      ..addOption('type', abbr: 't', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'set';

  @override
  final String description =
      'Set a version regardless of the the cloud version for the Flutter app and update the flutter files to reflect that version.';

  FlutterVersionCommand get parent => super.parent;

  @override
  String get versionType {
    if (argResults.wasParsed('type')) {
      return argResults['type'];
    } else {
      return super.versionType;
    }
  }

  void _updateYaml(Version version) {
    final String pubspecFile = join(flutterDir, 'pubspec.yaml');

    String yaml = pubspecFile.readAsStringSync();
    if (!yaml.contains('versionCode')) {
      yaml = yaml.replaceAllMapped(
          RegExp('version: (.+)'), (_) => 'version: ${version.versionName}\nversionCode: ${version.versionCode}');
    } else {
      yaml = yaml.replaceAllMapped(RegExp('version: (.+)'), (_) => 'version: ${version.versionName}');
      yaml = yaml.replaceAllMapped(RegExp('versionCode: (.+)'), (_) => 'versionCode: ${version.versionCode}');
    }
    pubspecFile.writeAsStringSync(yaml);
  }

  void _updateIos(Version version) {
    final String configFile = join(iosDir, 'Flutter', 'Generated.xcconfig');

    if (!configFile.existsSync()) {
      stdout.writeln('$configFile does not exist.');
      return;
    }

    String config = configFile.readAsStringSync();
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NUMBER', '${version.versionCode}');
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NAME', version.versionName);
    configFile.writeAsStringSync(config);
  }

  void _updateMacos(Version version) {
    final String configFile = join(macosDir, 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig');

    if (!configFile.existsSync()) {
      stdout.writeln('$configFile does not exist.');
      return;
    }

    String config = configFile.readAsStringSync();
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NUMBER', '${version.versionCode}');
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NAME', version.versionName);
    configFile.writeAsStringSync(config);
  }

  String _updateXcconfigField(String item, String field, String value) {
    String data = item;
    if (!data.contains(field)) {
      data += '\n$field=$value';
    } else {
      data = data.replaceAll(
        RegExp('$field=(.+)'),
        '$field=$value',
      );
    }

    return data;
  }

  void _updateAndroid(Version version) {
    final String versionProperties = join(androidPropertiesDir, 'version.properties');
    if (!versionProperties.existsSync()) {
      stdout.writeln('$versionProperties does not exist.');
      return;
    }

    versionProperties.writeAsStringSync(<String, Object>{
      'versionCode': version.versionCode,
      'versionName': version.versionName,
    }.asProperties);
  }

  void _updateFlutter(Version version) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('import \'package:pub_semver/pub_semver.dart\' as semver;')
      ..writeln()
      ..writeln('// ignore: avoid_classes_with_only_static_members')
      ..writeln('class Version {')
      ..writeln('  static const String versionName = \'${version.versionName}\';')
      ..writeln('  static const int versionCode = ${version.versionCode};')
      ..writeln('  static final semver.Version version = semver.Version.parse(versionName);')
      ..writeln('}')
      ..writeln('');

    join(flutterGeneratedDir, 'version.dart').writeAsStringSync(buffer.toString());
  }

  @override
  FutureOr<void> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    Version version = Version.parse(argResults['version']);
    version = Version.parse('$version${argResults.wasParsed('env') ? '+$env' : ''}');
    await execute(() => _updateYaml(version), 'Update pubspec.yaml file');
    await execute(() => _updateIos(version), 'Updating ios Generated.xcconfig');
    await execute(() => _updateMacos(version), 'Updating macos Flutter-Generated.xcconfig');
    await execute(() => _updateAndroid(version), 'Updating version.properties');
    await execute(() => _updateFlutter(version), 'Updating version.dart');

    if (argResults.wasParsed('update-cloud') && (argResults['update-cloud'] ?? false)) {
      await execute(() => setVersion(version), 'Set the version back to cloud');
    }
  }
}
