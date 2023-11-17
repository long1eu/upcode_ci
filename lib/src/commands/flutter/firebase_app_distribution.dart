// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/firebaseappdistribution/v1.dart';
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/flutter/application_mixin.dart';

class FadCommand extends UpcodeCommand with EnvironmentMixin, ApplicationMixin {
  FadCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(FadUploadCommand(config));
  }

  @override
  final String name = 'fad';

  @override
  final String description = 'Work with Firebase App Distribution';
}

class FadUploadCommand extends UpcodeCommand with EnvironmentMixin, ApplicationMixin {
  FadUploadCommand(Map<String, dynamic> config) : super(config) {
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
  final String name = 'upload';

  @override
  final String description = 'Distribute app on Firebase App Distribution';

  String _getPath() {
    if (argResults!['platform'] == 'android') {
      String fileName;
      if (argResults!.wasParsed('env')) {
        fileName = 'app-$env-release.apk';
      } else {
        fileName = 'app-release.apk';
      }

      return join(flutterDir, 'build', 'app', 'outputs', 'flutter-apk', fileName);
    } else if (argResults!['platform'] == 'ios') {
      String fileName;
      if (argResults!.wasParsed('env')) {
        fileName = 'Runner_adhoc_$env.ipa';
      } else {
        fileName = 'Runner_adhoc.ipa';
      }

      return join(flutterDir, 'build', 'ios', 'iphoneos', fileName);
    } else {
      throw ArgumentError('Unknown platform.');
    }
  }

  Future<String> _getAppId() async {
    if (argResults!['platform'] == 'android') {
      return (await getAndroidApp()).appId!;
    } else if (argResults!['platform'] == 'ios') {
      return (await getIosApp()).appId!;
    } else {
      throw ArgumentError('Unknown platform.');
    }
  }

  Future<String> _upload({required String path, required String appId}) async {
    // Note: we need the project number not the project name
    final String projectId = appId.split(':')[1];
    final String appName = Uri.encodeFull('projects/$projectId/apps/$appId');

    final File file = File(path);
    final Uri uri = Uri.parse('https://firebaseappdistribution.googleapis.com/upload/v1/$appName/releases:upload');

    final HttpClientRequest request = await HttpClient().postUrl(uri);
    request
      ..headers.add('x-goog-upload-file-name', Uri.encodeComponent(basename(path)))
      ..headers.add('x-goog-upload-protocol', 'raw')
      ..headers.add('content-type', 'application/octet-stream')
      ..headers.add('authorization', 'Bearer ${googleClient!.credentials.accessToken.data}');

    await request.addStream(file.openRead());
    final HttpClientResponse response = await request.close();

    final dynamic body = await response.transform(const Utf8Decoder()).transform(const JsonDecoder()).first;
    final String operationName = body['name']! as String;

    GoogleLongrunningOperation? operationResult;
    while (!(operationResult?.done ?? false)) {
      operationResult = await appDistribution.projects.apps.releases.operations.get(operationName);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final Map<String, dynamic> releaseResponse = operationResult!.response!;
    final String result = releaseResponse['result']! as String;
    final GoogleFirebaseAppdistroV1Release release =
        GoogleFirebaseAppdistroV1Release.fromJson(releaseResponse['release']! as Map<String, dynamic>);

    switch (result) {
      case 'RELEASE_CREATED':
        stdout.writeln(
          'Uploaded new release ${release.displayVersion} (${release.buildVersion}) successfully!\n${release.firebaseConsoleUri}',
        );
        break;
      case 'RELEASE_UPDATED':
        stdout.writeln(
          'Uploaded update to existing release ${release.displayVersion} (${release.buildVersion}) successfully!\n${release.firebaseConsoleUri}',
        );
        break;
      case 'RELEASE_UNMODIFIED':
        stdout.writeln(
          'Re-uploaded already existing release ${release.displayVersion} (${release.buildVersion}) successfully!\n${release.firebaseConsoleUri}',
        );
        break;
      default:
        stdout.writeln(
          'Uploaded release ${release.displayVersion} (${release.buildVersion}) successfully!\n${release.firebaseConsoleUri}',
        );
    }

    return release.name!;
  }

  Future<void> _updateReleaseNotes(String releaseName) async {
    if (argResults!.wasParsed('release-notes')) {
      final String releaseNotes = File(argResults!['release-notes'] as String).readAsStringSync();
      if (releaseNotes.isNotEmpty) {
        await appDistribution.projects.apps.releases.patch(
          GoogleFirebaseAppdistroV1Release(
            releaseNotes: GoogleFirebaseAppdistroV1ReleaseNotes(
              text: releaseNotes,
            ),
          ),
          releaseName,
          updateMask: 'release_notes.text',
        );
        stdout.writeln('Added release notes successfully');
      }
    }
  }

  Future<void> _distribute(String releaseName) async {
    if (!argResults!.wasParsed('groups')) {
      stdout.writeln('No testers or groups specified, skipping.');
      return;
    }

    final List<String> groups = argResults!['groups'] as List<String>;
    await appDistribution.projects.apps.releases.distribute(
      GoogleFirebaseAppdistroV1DistributeReleaseRequest(groupAliases: groups),
      releaseName,
    );

    stdout.writeln('Distributed to testers/groups successfully.');
  }

  @override
  FutureOr<dynamic> run() async {
    await initFirebase();

    final String path = _getPath();

    final String appId = await execute(_getAppId, 'Fetch application id');
    final String releaseName = await execute(() => _upload(path: path, appId: appId), 'Upload file');
    await execute(() => _updateReleaseNotes(releaseName), 'Add release notes');
    await execute(() => _distribute(releaseName), 'Distribute build');
    exit(0);
  }
}

class FadDeleteOldReleaseCommand extends UpcodeCommand with EnvironmentMixin, ApplicationMixin {
  FadDeleteOldReleaseCommand(Map<String, dynamic> config) : super(config) {
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
      ..addOption(
        'limit',
        abbr: 'l',
        help: 'The number of releases you want to keep',
        defaultsTo: '5',
      );
  }

  @override
  final String name = 'deleteOldReleases';

  @override
  final String description = 'Distribute app on Firebase App Distribution';

  @override
  FutureOr<dynamic> run() async {
    await initFirebase();

    String appId;
    if (argResults!['platform'] == 'android') {
      appId = (await getAndroidApp()).appId!;
    } else if (argResults!['platform'] == 'ios') {
      appId = (await getIosApp()).appId!;
    } else {
      throw ArgumentError('Unknown platform.');
    }

    final String appName = 'apps/$appId';
    final GoogleFirebaseAppdistroV1ListReleasesResponse response =
        await appDistribution.projects.apps.releases.list('$firebaseProjectName/$appName', pageSize: 1000);

    final int limit = int.tryParse(argResults!['limit']) ?? 5;

    final List<String> names = (response.releases ?? <GoogleFirebaseAppdistroV1Release>[])
        .skip(limit)
        .map((GoogleFirebaseAppdistroV1Release release) => release.name!)
        .toList();

    if (names.isNotEmpty) {
      stdout.writeln('Deleting releases: ${names.join('\n')}');
      await appDistribution.projects.apps.releases.batchDelete(
          GoogleFirebaseAppdistroV1BatchDeleteReleasesRequest(names: names), '$firebaseProjectName/$appName');
    }
  }
}
