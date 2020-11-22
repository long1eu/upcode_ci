// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/flutter/application_mixin.dart';

class FlutterFirebaseAppDistributionCommand extends UpcodeCommand with EnvironmentMixin, ApplicationMixin {
  FlutterFirebaseAppDistributionCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption(
        'env',
        abbr: 'e',
        help: 'The name of the environment you want to create',
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help: 'The name of the platform you want to deploy to.',
        allowed: ['android', 'ios'],
      )
      ..addMultiOption(
        'groups',
        abbr: 'g',
        help: 'E comma separated list of group aliases to distribute to.',
        defaultsTo: ['testers'],
      );
  }

  @override
  final String name = 'flutter:fad';

  @override
  final String description = 'Distribute app on Firebase App Distribution';

  @override
  FutureOr<dynamic> run() async {
    await initFirebase();

    String appId;
    String path;
    if (argResults['platform'] == 'android') {
      appId = (await getAndroidApp()).appId;
      path = join(flutterDir, 'build', 'app', 'outputs', 'flutter-apk', 'app-$env-release.apk');
    } else if (argResults['platform'] == 'ios') {
      appId = (await getIosApp()).appId;
      path = join(flutterDir, 'build', 'ios', 'iphoneos', 'Runner_adhoc_$env.ipa');
    } else {
      throw ArgumentError('Unknown platform.');
    }

    await execute(
      () => runCommand(
        'firebase',
        <String>[
          'appdistribution:distribute',
          path,
          '--app',
          appId,
          '--groups',
          argResults['groups'].join(','),
          '--debug'
        ],
        workingDirectory: pwd,
      ),
      description,
    );
  }
}
