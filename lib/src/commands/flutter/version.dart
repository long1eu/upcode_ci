// File created by
// Lung Razvan <long1eu>
// on 10/05/2020

import 'dart:async';
import 'dart:convert';
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
      ..addOption('operation', abbr: 'o', allowed: <String>['patch', 'release'], defaultsTo: 'patch')
      ..addOption(
        'compute',
        abbr: 'c',
        help:
            'You can specify a dart file that will compute the next version. You will receive the current saved values and you need to print the value to be used.',
      )
      ..addOption('type', abbr: 't', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'increment';

  @override
  final String description =
      'Increment the cloud version of the Flutter app and update the flutter files to reflect that version.';

  @override
  FlutterVersionCommand get parent => super.parent as FlutterVersionCommand;

  @override
  String get versionType {
    if (argResults!.wasParsed('type')) {
      return argResults!['type'];
    } else {
      return super.versionType;
    }
  }

  @override
  FutureOr<void> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    if (argResults!.wasParsed('compute')) {
      Map<String, dynamic> data = await execute(getRawVersion, 'Get version from cloud');
      data = await execute(
        () async {
          final CapturedOutput output = CapturedOutput();
          await runCommand(
            'dart',
            <String>[
              argResults!['compute'],
              jsonEncode(<String, dynamic>{
                ...data,
                'operation': argResults!['operation'],
              }),
            ],
            outputMode: OutputMode.capture,
            output: output,
            workingDirectory: pwd,
          );

          return jsonDecode(output.stdout);
        },
        'Computing version using user script',
      );

      if (data['versionCode'] == null) {
        throw ArgumentError('You need to provide a versionCode.');
      } else if (data['versionName'] == null) {
        throw ArgumentError('You need to provide a versionName.');
      }

      await execute(() => setRawVersion(data), 'Set back to cloud: $data');
    } else {
      Version version = await execute(getVersion, 'Get current version from cloud');
      if (argResults!['operation'] == 'release') {
        version = await execute(version.releaseVersion, 'Increment Flutter version');
      } else {
        version = await execute(version.patchVersion, 'Increment Flutter version');
      }

      await execute(() => setVersion(version), 'Set version back to cloud: $version');
    }

    await runner!.run(<String>[
      'flutter:version',
      'read',
      if (argResults!.wasParsed('env')) ...<String>[
        '--env',
        argResults!['env'],
      ],
      if (argResults!.wasParsed('type')) ...<String>[
        '--type',
        argResults!['type'],
      ],
    ]);
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

  @override
  FlutterVersionCommand get parent => super.parent as FlutterVersionCommand;

  @override
  String get versionType {
    if (argResults!.wasParsed('type')) {
      return argResults!['type'];
    } else {
      return super.versionType;
    }
  }

  @override
  FutureOr<void> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    final Map<String, dynamic> data = await getRawVersion();
    await execute<void>(
          () => runner!.run(<String>[
        'flutter:version',
        'set',
        '--versionName',
        data['versionName'] ?? '0.0.0',
        '--versionCode',
        '${data['versionCode'] ?? 0}',
        ...argResults!.arguments,
      ]),
      'Setting version $data',
    );
  }
}

class FlutterSetVersionCommand extends UpcodeCommand with VersionMixin, EnvironmentMixin {
  FlutterSetVersionCommand(Map<String, dynamic> config) : super(config) {
    argParser //
      ..addOption('env', abbr: 'e')
      ..addFlag('update-cloud', help: 'Mirror the change in cloud also')
      ..addOption('version',
          abbr: 'v',
          help:
              'Specifies a semantic version that would be used to determine the version name and version code. You can also specify the values using the versionName and version code options.')
      ..addOption('versionName')
      ..addOption('versionCode')
      ..addOption('type', abbr: 't', help: 'The name used to save the version at.');
  }

  @override
  final String name = 'set';

  @override
  final String description =
      'Set a version regardless of the the cloud version for the Flutter app and update the flutter files to reflect that version.';

  @override
  FlutterVersionCommand get parent => super.parent as FlutterVersionCommand;

  @override
  String get versionType {
    if (argResults!.wasParsed('type')) {
      return argResults!['type'];
    } else {
      return super.versionType;
    }
  }

  void _updateYaml(String versionName, int versionCode) {
    final String pubspecFile = join(flutterDir, 'pubspec.yaml');

    String yaml = pubspecFile.readAsStringSync();
    if (!yaml.contains('versionCode')) {
      yaml = yaml.replaceAllMapped(RegExp('version: (.+)'), (_) => 'version: $versionName\nversionCode: $versionCode');
    } else {
      yaml = yaml.replaceAllMapped(RegExp('version: (.+)'), (_) => 'version: $versionName');
      yaml = yaml.replaceAllMapped(RegExp('versionCode: (.+)'), (_) => 'versionCode: $versionCode');
    }
    pubspecFile.writeAsStringSync(yaml);
  }

  void _updateIos(String versionName, int versionCode) {
    final String configFile = join(iosDir, 'Flutter', 'Generated.xcconfig');

    if (!configFile.existsSync()) {
      stdout.writeln('$configFile does not exist.');
      return;
    }

    String config = configFile.readAsStringSync();
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NUMBER', '$versionCode');
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NAME', versionName);
    configFile.writeAsStringSync(config);
  }

  void _updateMacos(String versionName, int versionCode) {
    final String configFile = join(macosDir, 'Flutter', 'ephemeral', 'Flutter-Generated.xcconfig');

    if (!configFile.existsSync()) {
      stdout.writeln('$configFile does not exist.');
      return;
    }

    String config = configFile.readAsStringSync();
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NUMBER', '$versionCode');
    config = _updateXcconfigField(config, 'FLUTTER_BUILD_NAME', versionName);
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

  void _updateAndroid(String versionName, int versionCode) {
    final String versionProperties = join(androidPropertiesDir, 'version.properties');
    if (!versionProperties.existsSync()) {
      stdout.writeln('$versionProperties does not exist.');
      return;
    }

    versionProperties.writeAsStringSync(<String, Object>{
      'versionCode': versionCode,
      'versionName': versionName,
    }.asProperties);
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
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    String? versionName;
    int? versionCode;

    if (argResults!.wasParsed('version')) {
      Version version = Version.parse(argResults!['version']);
      version = Version.parse('$version${argResults!.wasParsed('env') ? '+$env' : ''}');

      versionName = version.versionName;
      versionCode = version.versionCode;
    } else {
      if (!argResults!.wasParsed('versionName') || !argResults!.wasParsed('versionCode')) {
        throw ArgumentError('You need to pass versionName and versionCode when not specifying version.');
      }

      versionName = argResults!['versionName'];
      versionCode = int.tryParse(argResults!['versionCode'] ?? '');

      if (versionName == null || versionCode == null) {
        throw ArgumentError(
            'Make sure you pass both versionName and versionCode when not specifying a semantic version.');
      }
    }

    await execute(() => _updateYaml(versionName!, versionCode!), 'Update pubspec.yaml file');
    await execute(() => _updateIos(versionName!, versionCode!), 'Updating ios Generated.xcconfig');
    await execute(() => _updateMacos(versionName!, versionCode!), 'Updating macos Flutter-Generated.xcconfig');
    await execute(() => _updateAndroid(versionName!, versionCode!), 'Updating version.properties');
    await execute(() => _updateFlutter(versionName!, versionCode!), 'Updating version.dart');

    if (argResults!.wasParsed('update-cloud') && (argResults!['update-cloud'] ?? false)) {
      await execute(
        () {
          return setRawVersion(<String, dynamic>{
            'versionName': versionName,
            'versionCode': versionCode,
          });
        },
        'Set the version back to cloud',
      );
    }
  }
}
