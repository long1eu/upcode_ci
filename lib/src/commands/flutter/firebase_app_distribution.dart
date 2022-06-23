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
        allowed: <String>['android', 'ios'],
      )
      ..addMultiOption(
        'groups',
        abbr: 'g',
        help: 'E comma separated list of group aliases to distribute to.',
        defaultsTo: <String>['testers'],
      )
      ..addOption(
        'release-notes',
        abbr: 'n',
        help: 'A file that contains the release notes for this version',
      )
      ..addOption(
        'token',
        abbr: 't',
        help: 'Provide the firebase token you want to use',
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
    if (argResults!['platform'] == 'android') {
      appId = (await getAndroidApp()).appId!;
      String fileName;
      if (argResults!.wasParsed('env')) {
        fileName = 'app-$env-release.apk';
      } else {
        fileName = 'app-release.apk';
      }

      path = join(flutterDir, 'build', 'app', 'outputs', 'flutter-apk', fileName);
    } else if (argResults!['platform'] == 'ios') {
      appId = (await getIosApp()).appId!;

      String fileName;
      if (argResults!.wasParsed('env')) {
        fileName = 'Runner_adhoc_$env.ipa';
      } else {
        fileName = 'Runner_adhoc.ipa';
      }

      path = join(flutterDir, 'build', 'ios', 'iphoneos', fileName);
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
          argResults!['groups'].join(','),
          if (argResults!.wasParsed('release-notes')) ...<String>[
            '--release-notes-file',
            argResults!['release-notes'],
          ],
          if (argResults!.wasParsed('token')) ...<String>[
            '--token',
            argResults!['token'],
          ],
          '--project',
          projectId,
        ],
        workingDirectory: pwd,
      ),
      description,
    );
  }
}
