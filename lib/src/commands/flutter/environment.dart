// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:strings/strings.dart' show camelize;
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/flutter/application_mixin.dart';
import 'package:xml/xml.dart';

class FlutterEnvironmentCommand extends UpcodeCommand {
  FlutterEnvironmentCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(FlutterSetEnvironmentCommand(config));
  }

  @override
  final String name = 'flutter:environment';

  @override
  final String description = 'Manage Flutter environments.';
}

mixin _FlutterEnvironmentCommandMixin on UpcodeCommand {
  FlutterEnvironmentCommand get parent => super.parent;
}

class FlutterSetEnvironmentCommand extends UpcodeCommand
    with _FlutterEnvironmentCommandMixin, EnvironmentMixin, ApplicationMixin {
  FlutterSetEnvironmentCommand(Map<String, dynamic> config) : super(config) {
    argParser.addOption(
      'env',
      abbr: 'e',
      help: 'The name of the environment you want to create',
    );
  }

  @override
  final String name = 'set';

  @override
  final String description = 'Set an already existing environment to Flutter.';

  void _setIdeaEnv() {
    if (!workspaceIdea.existsSync()) {
      return;
    }

    final XmlDocument document = XmlDocument.parse(workspaceIdea.readAsStringSync());
    final int projectNodeIndex = document.children.indexWhere((element) =>
        element is XmlElement && //
        element.name.local == 'project' &&
        element.getAttribute('version') == '4');
    final XmlNode projectNode = document.children.removeAt(projectNodeIndex);

    final int runManagerIndex = projectNode.children
        .indexWhere((element) => element is XmlElement && element.getAttribute('name') == 'RunManager');

    final XmlNode runManager =
        (runManagerIndex != -1 ? projectNode.children.removeAt(runManagerIndex) : _intelliJRunManager(env)).copy();

    runManager.setAttribute('selected', 'Flutter.$env');
    if (!runManager.children.any((element) =>
        element is XmlElement &&
        element.name.local == 'configuration' &&
        element.getAttribute('name') == env &&
        element.getAttribute('type') == 'FlutterRunConfigurationType' &&
        element.getAttribute('factoryName') == 'Flutter')) {
      runManager.children.add(_intelliJConfiguration(env, join(flutterDir, 'lib', 'main.dart')));
    }

    projectNode.children.add(runManager);
    document.children.add(projectNode);
    workspaceIdea.writeAsStringSync(document.toXmlString(pretty: true));
  }

  Future<void> _saveFlutterConfiguration() async {
    final String androidKey = await execute(androidApiKey, 'Reading Android API key');
    final String iosKey = await execute(iosApiKey, 'Reading iOS API key');

    stdout.writeln('Saving Flutter configuration');
    final StringBuffer buffer = StringBuffer() //
      ..writeln('// ignore: avoid_classes_with_only_static_members')
      ..writeln('class Config {');

    if (argResults.wasParsed('env')) {
      buffer.writeln('  static const String environment = \'$env\';');
    }

    buffer //
      ..writeln('  static const String androidApiKey = \'$androidKey\';')
      ..writeln('  static const String iosApiKey = \'$iosKey\';');


    for (String key in this.flutterApiConfig.keys) {
      String variableName = camelize(key);
      final List<String> parts = variableName.split('');
      variableName = [parts.first.toLowerCase(), ...parts.skip(1)].join('');
      buffer.writeln('  static const String ${variableName} = \'${this.flutterApiConfig[key]}\';');
    }
    buffer //
      ..writeln('}')
      ..writeln('');

    join(flutterGeneratedDir, 'config.dart').writeAsStringSync(buffer.toString());
  }

  @override
  FutureOr<dynamic> run() async {
    await initFirebase();
    await execute(saveAndroidConfig, 'Saving Firebase configuration for Android');
    await execute(saveIosConfig, 'Saving Firebase configuration for iOS');
    if (argResults.wasParsed('env')) {
      await execute(_setIdeaEnv, 'Updating IntelliJ Idea run configuration.');
    }
    await execute(_saveFlutterConfiguration, 'Saving Flutter configuration');
  }
}

XmlElement _intelliJRunManager(String environment) {
  final XmlDocument document =
      XmlDocument.parse('<component name="RunManager" selected="Flutter.$environment"></component>');
  return document.rootElement..detachParent(document);
}

XmlElement _intelliJConfiguration(String environment, String main) {
  final StringBuffer buffer = StringBuffer()
    ..writeln('  <configuration name="${environment}" type="FlutterRunConfigurationType" factoryName="Flutter">')
    ..writeln('    <option name="buildFlavor" value="$environment" />')
    ..writeln('    <option name="filePath" value="\$PROJECT_DIR\$/$main" />')
    ..writeln('    <method v="2" />')
    ..writeln('  </configuration>');

  final XmlDocument document = XmlDocument.parse(buffer.toString());
  return document.rootElement..detachParent(document);
}
