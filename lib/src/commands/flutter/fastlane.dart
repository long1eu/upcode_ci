// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/flutter/application_mixin.dart';

class FlutterFastlaneDeployCommand extends UpcodeCommand with EnvironmentMixin, ApplicationMixin {
  FlutterFastlaneDeployCommand(Map<String, dynamic> config) : super(config) {
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
        allowed: <String>['android', 'ios'],
      );
  }

  @override
  final String name = 'flutter:fastlane';

  @override
  final String description = 'Distribute app on App and Play Store';

  @override
  FutureOr<dynamic> run() async {
    if (argResults['platform'] == 'android') {
      final String serviceAccountKey = join(privateDir, 'service_account.json');
      final String path = join(flutterDir, 'build', 'app', 'outputs', 'bundle', '$env\Release', 'app-$env-release.aab');

      await execute(
        () => runCommand(
          'bundle',
          <String>[
            'exec',
            'fastlane',
            'run',
            'upload_to_play_store',
            'package_name:$iosAppId',
            'track:beta',
            'release_status:draft',
            'aab:$path',
            'json_key:$serviceAccountKey',
          ],
          workingDirectory: androidDir,
        ),
        description,
      );
    } else if (argResults['platform'] == 'ios') {
      await execute(
        () => runCommand(
          'bundle',
          <String>[
            'exec',
            'fastlane',
            'upload_prod_to_appstore',
          ],
          workingDirectory: iosDir,
        ),
        description,
      );
    }
  }
}
