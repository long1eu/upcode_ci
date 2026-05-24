// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/firebaseappdistribution/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/flutter/application_mixin.dart';
import 'package:yaml/yaml.dart';

class FadCommand extends UpcodeCommand with EnvironmentMixin, ApplicationMixin {
  FadCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(FadUploadCommand(config));
    addSubcommand(FadDeleteOldReleaseCommand(config));
    addSubcommand(FadAiTestCommand(config));
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
      )
      ..addOption(
        'path',
        help: 'The path to the apk, aab or ipa file to upload. '
            'The file type is inferred from the extension. '
            'If not provided, the default build output path will be used (apk for android, ipa for ios).',
      );
  }

  @override
  final String name = 'upload';

  @override
  final String description = 'Distribute app on Firebase App Distribution';

  String _getPath() {
    if (argResults!.wasParsed('path')) {
      return argResults!['path'] as String;
    }

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

    // Note: we need the project number not the project name
    final String projectId = appId.split(':')[1];
    final String appName = 'apps/$appId';
    final GoogleFirebaseAppdistroV1ListReleasesResponse response =
        await appDistribution.projects.apps.releases.list('projects/$projectId/$appName', pageSize: 1000);

    final int limit = int.tryParse(argResults!['limit']) ?? 5;

    final List<String> names = (response.releases ?? <GoogleFirebaseAppdistroV1Release>[])
        .skip(limit)
        .map((GoogleFirebaseAppdistroV1Release release) => release.name!)
        .toList();

    if (names.isNotEmpty) {
      stdout.writeln('Deleting releases: ${names.join('\n')}');
      await appDistribution.projects.apps.releases.batchDelete(
          GoogleFirebaseAppdistroV1BatchDeleteReleasesRequest(names: names), 'projects/$projectId/$appName');
    }
  }
}

/// Runs Firebase App Distribution AI tests against a freshly uploaded release.
///
/// The APK is uploaded but never distributed to testers. Each test in the YAML
/// becomes a release test driven by the App Testing agent
/// (`POST {release}/tests`, v1alpha), with the agent logging in automatically
/// from the supplied credentials before running the natural-language steps.
class FadAiTestCommand extends UpcodeCommand with EnvironmentMixin, ApplicationMixin {
  FadAiTestCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption('env', abbr: 'e', help: 'The environment whose build artifact to test.')
      ..addOption(
        'path',
        help: 'Path to the APK to upload and test. Defaults to the dev release apk.',
      )
      ..addOption('tests', help: 'Path to the YAML file describing the AI test cases.')
      ..addOption('username', help: 'Username used for automatic login during the tests.')
      ..addOption('password', help: 'Password used for automatic login. Prefer --password-file.')
      ..addOption('password-file', help: 'Path to a plain-text file containing the login password.')
      ..addOption(
        'token',
        abbr: 't',
        help: 'A Firebase user refresh token (from `firebase login:ci`). Required: the App Testing '
            'release-tests API only accepts a user identity, not the service account. Falls back to '
            r'the FIREBASE_TOKEN environment variable.',
      )
      ..addMultiOption(
        'device',
        help: 'Device(s) to test on, formatted as '
            'model=<id>,version=<api>,locale=<locale>,orientation=<portrait|landscape>. '
            'Repeat the flag for multiple devices.',
        splitCommas: false,
        defaultsTo: <String>['model=MediumPhone.arm,version=34,locale=en,orientation=portrait'],
      )
      ..addOption(
        'results-bucket',
        help: 'GCS bucket for raw test artifacts (logs, video, screenshots). '
            'Defaults to the App Distribution results bucket.',
      )
      ..addOption('timeout', help: 'Minutes to wait for results before giving up.', defaultsTo: '15');
  }

  @override
  final String name = 'ai-test';

  @override
  final String description =
      'Run Firebase App Distribution AI tests (with auto-login) on a freshly uploaded, non-distributed release';

  static const String _host = 'https://firebaseappdistribution.googleapis.com';

  /// The firebase-tools OAuth client (id/secret) used to refresh the user token
  /// supplied via --token (issued by `firebase login:ci`). Read from upcode.yaml
  /// so the credentials aren't baked into the package source.
  ClientId get _firebaseToolsClient {
    final String? id = config['firebase_client_id'] as String?;
    final String? secret = config['firebase_client_secret'] as String?;
    if (id == null || secret == null) {
      throw StateError('Set `firebase_client_id` and `firebase_client_secret` in upcode.yaml. '
          'These are the firebase-tools OAuth client used to refresh the `firebase login:ci` token.');
    }
    return ClientId(id, secret);
  }

  /// Auto-refreshing client for the user identity (the release-tests API
  /// rejects the service account). The service-account [googleClient] is still
  /// used for fetching the app and uploading the release.
  late final AutoRefreshingAuthClient _testClient;

  AutoRefreshingAuthClient _userClient(String refreshToken) {
    final AccessCredentials credentials = AccessCredentials(
      AccessToken('Bearer', '', DateTime.now().toUtc().subtract(const Duration(hours: 1))),
      refreshToken,
      <String>['https://www.googleapis.com/auth/cloud-platform'],
    );
    return autoRefreshingClient(_firebaseToolsClient, credentials, http.Client());
  }

  String _getPath() {
    if (argResults!.wasParsed('path')) {
      return argResults!['path'] as String;
    }
    final String fileName = argResults!.wasParsed('env') ? 'app-$env-release.apk' : 'app-release.apk';
    return join(flutterDir, 'build', 'app', 'outputs', 'flutter-apk', fileName);
  }

  /// Uploads [path] and returns the release resource name. Does not distribute.
  Future<String> _upload({required String path, required String appId}) async {
    final String projectId = appId.split(':')[1];
    final String appName = Uri.encodeFull('projects/$projectId/apps/$appId');

    final File file = File(path);
    final Uri uri = Uri.parse('$_host/upload/v1/$appName/releases:upload');

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
    final GoogleFirebaseAppdistroV1Release release =
        GoogleFirebaseAppdistroV1Release.fromJson(operationResult!.response!['release']! as Map<String, dynamic>);
    return release.name!;
  }

  Map<String, dynamic>? _loginCredential() {
    final String? username = argResults!['username'] as String?;
    String? password = argResults!['password'] as String?;
    if (argResults!.wasParsed('password-file')) {
      password = File(argResults!['password-file'] as String).readAsStringSync().trim();
    }
    if (username == null && password == null) {
      return null;
    }
    return <String, dynamic>{
      if (username != null) 'username': username,
      if (password != null) 'password': password,
    };
  }

  Map<String, dynamic> _device(String spec) {
    final Map<String, String> parts = <String, String>{
      for (final String pair in spec.split(',')) pair.split('=').first.trim(): pair.split('=').last.trim(),
    };
    return <String, dynamic>{
      'model': parts['model'],
      'version': parts['version'],
      'locale': parts['locale'] ?? 'en',
      'orientation': parts['orientation'] ?? 'portrait',
    };
  }

  /// Reads the YAML into plain (JSON-encodable) test maps with `aiInstructions`
  /// steps. Accepts both `successCriteria` and `finalScreenAssertion` keys.
  List<Map<String, dynamic>> _readTests() {
    final dynamic doc = loadYaml(File(argResults!['tests'] as String).readAsStringSync());
    final List<dynamic> tests = (doc['tests'] as List<dynamic>?) ?? <dynamic>[];
    return tests.map<Map<String, dynamic>>((dynamic test) {
      final List<dynamic> steps = (test['steps'] as List<dynamic>?) ?? <dynamic>[];
      return <String, dynamic>{
        'displayName': (test['displayName'] ?? test['name'])?.toString(),
        'steps': steps.map<Map<String, dynamic>>((dynamic step) {
          final dynamic success = step['successCriteria'] ?? step['finalScreenAssertion'];
          return <String, dynamic>{
            if (step['goal'] != null) 'goal': step['goal'].toString(),
            if (step['assertion'] != null) 'assertion': step['assertion'].toString(),
            if (step['hint'] != null) 'hint': step['hint'].toString(),
            if (success != null) 'successCriteria': success.toString(),
          };
        }).toList(),
      };
    }).toList();
  }

  Future<String> _createReleaseTest({
    required String releaseName,
    required Map<String, dynamic> test,
    required List<Map<String, dynamic>> devices,
    Map<String, dynamic>? loginCredential,
  }) async {
    final String? resultsBucket = argResults!['results-bucket'] as String?;
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'deviceExecutions': devices.map((Map<String, dynamic> device) => <String, dynamic>{'device': device}).toList(),
      if (loginCredential != null) 'loginCredential': loginCredential,
      'aiInstructions': <String, dynamic>{'steps': test['steps']},
      if (test['displayName'] != null) 'displayName': test['displayName'],
      if (resultsBucket != null) 'resultsBucket': resultsBucket,
    };
    final http.Response response = await _testClient.post(
      Uri.parse('$_host/v1alpha/$releaseName/tests'),
      headers: <String, String>{'content-type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    if (response.statusCode >= 400) {
      final Map<String, dynamic> redacted = <String, dynamic>{
        ...requestBody,
        if (requestBody.containsKey('loginCredential')) 'loginCredential': '<redacted>',
      };
      throw StateError('Failed to create release test: ${response.statusCode} ${response.body}\n'
          'Request: ${jsonEncode(redacted)}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['name'] as String;
  }

  /// Polls a release test until every device execution is terminal. Returns
  /// whether they all passed.
  Future<bool> _awaitResult(String testName, Duration timeout) async {
    final DateTime deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final http.Response response = await _testClient.get(Uri.parse('$_host/v1alpha/$testName'));
      final Map<String, dynamic> body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> executions = (body['deviceExecutions'] as List<dynamic>?) ?? <dynamic>[];

      final bool done = executions.isNotEmpty &&
          executions.every((dynamic e) => ((e['state'] as String?) ?? 'IN_PROGRESS') != 'IN_PROGRESS');
      if (done) {
        bool passed = true;
        for (final dynamic execution in executions) {
          final String state = (execution['state'] as String?) ?? 'INCONCLUSIVE';
          if (state != 'PASSED') {
            passed = false;
            final String reason = (execution['failedReason'] ?? execution['inconclusiveReason'] ?? '') as String;
            stdout.writeln('  $red$state on ${execution['device']?['model']}: $reason$reset');
          }
        }
        return passed;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
    stdout.writeln('  ${red}Timed out waiting for $testName$reset');
    return false;
  }

  @override
  FutureOr<dynamic> run() async {
    final String? refreshToken = (argResults!['token'] as String?) ?? Platform.environment['FIREBASE_TOKEN'];
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('A user token is required (--token or FIREBASE_TOKEN). The App Testing '
          'release-tests API does not accept the service account. Generate one with `firebase login:ci`.');
    }
    _testClient = _userClient(refreshToken);

    await initFirebase();

    final String path = _getPath();
    final String appId = await execute(() async => (await getAndroidApp()).appId!, 'Fetch application id');
    final String releaseName =
        await execute(() => _upload(path: path, appId: appId), 'Upload release (no distribution)');

    final List<Map<String, dynamic>> tests = _readTests();
    final List<Map<String, dynamic>> devices = (argResults!['device'] as List<String>).map(_device).toList();
    final Map<String, dynamic>? loginCredential = _loginCredential();
    final Duration timeout = Duration(minutes: int.tryParse(argResults!['timeout'] as String) ?? 15);

    final Map<String, String> started = <String, String>{};
    await execute(
      () async {
        for (final Map<String, dynamic> test in tests) {
          final String testName = await _createReleaseTest(
            releaseName: releaseName,
            test: test,
            devices: devices,
            loginCredential: loginCredential,
          );
          started[(test['displayName'] as String?) ?? testName] = testName;
        }
      },
      'Start ${tests.length} AI test(s)',
    );

    bool allPassed = true;
    await execute(
      () async {
        for (final MapEntry<String, String> entry in started.entries) {
          final bool passed = await _awaitResult(entry.value, timeout);
          stdout.writeln('${passed ? green : red}${passed ? 'PASSED' : 'FAILED'}$reset  ${entry.key}');
          allPassed = allPassed && passed;
        }
      },
      'Wait for AI test results',
    );

    exit(allPassed ? 0 : 1);
  }
}
