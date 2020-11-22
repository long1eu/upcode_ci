// File created by
// Lung Razvan <long1eu>
// on 10/05/2020

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';

class FlutterVersionCommand extends UpcodeCommand {
  FlutterVersionCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(FlutterIncrementVersionCommand(config));
    addSubcommand(FlutterReadVersionCommand(config));
  }

  @override
  final String name = 'flutter:version';

  @override
  final String description = 'Update the flutter app version base on the cloud version value.';
}

mixin _VersionMixin on UpcodeCommand {
  String get databaseUrl {
    final String databaseKey = join(privateDir, 'firebase_database.key').readAsStringSync();
    return 'https://$projectId.firebaseio.com/.json?auth=$databaseKey';
  }

  Version _version;

  Version get version {
    if (_version == null) {
      throw StateError('You need to call getVersion() at least once.');
    }

    return _version;
  }

  Future<Version> _getVersion() async {
    if (_version != null) {
      return _version;
    }

    final Response data = await googleClient.get(databaseUrl);
    final Map<dynamic, dynamic> values = jsonDecode(data.body) ?? <dynamic, dynamic>{};

    return _version ??= Version.parse(values['versionName'] ?? '0.0.0');
  }
}

class FlutterIncrementVersionCommand extends UpcodeCommand with _VersionMixin {
  FlutterIncrementVersionCommand(Map<String, dynamic> config) : super(config);
  @override
  final String name = 'increment';

  @override
  final String description =
      'Increment the cloud version of the Flutter app and update the flutter files to reflect that version.';

  FlutterVersionCommand get parent => super.parent;

  Future<void> _setVersion() async {
    await googleClient.patch(
      databaseUrl,
      body: jsonEncode(
        <String, dynamic>{
          'versionCode': _version.versionCode,
          'versionName': _version.versionName,
        },
      ),
    );
  }

  @override
  FutureOr<void> run() async {
    await initFirebase();
    Version version = await execute(_getVersion, 'Get current version from cloud');
    version = await execute(version.increment, 'Increment Flutter version');
    _version = version;
    await execute(_setVersion, 'Set version back to cloud: $version');
    await runner.run(['flutter:version', 'read']);
  }
}

class FlutterReadVersionCommand extends UpcodeCommand with _VersionMixin {
  FlutterReadVersionCommand(Map<String, dynamic> config) : super(config);
  @override
  final String name = 'read';

  @override
  final String description =
      'Read the cloud version of the Flutter app and update the flutter files to reflect that version.';

  FlutterVersionCommand get parent => super.parent;

  void _updateYaml() {
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

  void _updateIos() {
    final String configFile = join(iosDir, 'Flutter', 'Generated.xcconfig');

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

  void _updateAndroid() {
    join(androidPropertiesDir, 'version.properties').writeAsStringSync(<String, Object>{
      'versionCode': version.versionCode,
      'versionName': version.versionName,
    }.asProperties);
  }

  void _updateFlutter() {
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
    await initFirebase();
    await execute(_getVersion, 'Get current version from cloud');
    await execute(_updateYaml, 'Update pubspec.yaml file');
    await execute(_updateIos, 'Updating Generated.xcconfig');
    await execute(_updateAndroid, 'Updating version.properties');
    await execute(_updateFlutter, 'Updating version.dart');
  }
}
