// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:googleapis/firebaseappdistribution/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:upcode_ci/src/commands/flutter/application_mixin.dart';
import 'package:upcode_ci/src/generated/firebaseappdistribution/v1alpha.dart' as fad_v1alpha;
import 'package:yaml/yaml.dart';

/// Builds a v1alpha [fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest]
/// from already-parsed inputs. Pure: no I/O, so it is unit-tested directly.
fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest buildReleaseTest({
  required String? displayName,
  required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps,
  required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices,
  required fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential,
  required String? resultsBucket,
}) {
  return fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest(
    displayName: displayName,
    resultsBucket: resultsBucket,
    loginCredential: loginCredential,
    aiInstructions: fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiInstructions(steps: steps),
    deviceExecutions: devices
        .map((fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice device) =>
            fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution(device: device))
        .toList(),
  );
}

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
        help: 'The name of the environment to use.',
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
        help: 'The name of the environment to use.',
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
  final String description = 'Delete old Firebase App Distribution releases, keeping the most recent --limit.';

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
        'credentials',
        help: 'Path to a JSON file with TEST_EMAIL/TEST_PASSWORD for automatic login '
            '(e.g. the dart-define test_credentials.json). Explicit --username/--password take precedence.',
      )
      ..addOption(
        'token',
        abbr: 't',
        help: 'A Firebase user refresh token (from `firebase login:ci`) for the App Testing '
            'release-tests API. Falls back to the FIREBASE_TOKEN environment variable, then to '
            'the service account when neither is set.',
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
      ..addOption('timeout', help: 'Minutes to wait for results before giving up.', defaultsTo: '15')
      ..addFlag(
        'wait',
        defaultsTo: false,
        help: 'Wait until every test reaches a terminal state, ignoring --timeout.',
      );
  }

  @override
  final String name = 'ai-test';

  @override
  final String description =
      'Run Firebase App Distribution AI tests (with auto-login) on a freshly uploaded, non-distributed release';

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

  /// Client used for the App Testing release-tests API. Prefers the user
  /// identity from `--token`/`FIREBASE_TOKEN`, falling back to the
  /// service-account [googleClient] (also used for fetching the app and
  /// uploading the release) when no token is provided.
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
    final GoogleFirebaseAppdistroV1Release release =
        GoogleFirebaseAppdistroV1Release.fromJson(operationResult!.response!['release']! as Map<String, dynamic>);
    return release.name!;
  }

  fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? _loginCredential() {
    String? username = argResults!['username'] as String?;
    String? password = argResults!['password'] as String?;
    if (argResults!.wasParsed('password-file')) {
      password = File(argResults!['password-file'] as String).readAsStringSync().trim();
    }
    if (argResults!.wasParsed('credentials')) {
      final Map<String, dynamic> credentials =
          jsonDecode(File(argResults!['credentials'] as String).readAsStringSync()) as Map<String, dynamic>;
      username ??= credentials['TEST_EMAIL'] as String?;
      password ??= credentials['TEST_PASSWORD'] as String?;
    }
    if (username == null && password == null) {
      return null;
    }
    return fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential(username: username, password: password);
  }

  fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice _device(String spec) {
    final Map<String, String> parts = <String, String>{
      for (final String pair in spec.split(',')) pair.split('=').first.trim(): pair.split('=').last.trim(),
    };
    return fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice(
      model: parts['model'],
      version: parts['version'],
      locale: parts['locale'] ?? 'en',
      orientation: parts['orientation'] ?? 'portrait',
    );
  }

  /// Reads the YAML into (displayName, steps) records. Accepts both
  /// `successCriteria` and `finalScreenAssertion` for the success text.
  List<({String? displayName, List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps})> _readTests() {
    final dynamic doc = loadYaml(File(argResults!['tests'] as String).readAsStringSync());
    final List<dynamic> tests = (doc['tests'] as List<dynamic>?) ?? <dynamic>[];
    return tests.map((dynamic test) {
      final List<dynamic> steps = (test['steps'] as List<dynamic>?) ?? <dynamic>[];
      return (
        displayName: (test['displayName'] ?? test['name'])?.toString(),
        steps: steps.map((dynamic step) {
          final dynamic success = step['successCriteria'] ?? step['finalScreenAssertion'];
          return fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep(
            goal: step['goal']?.toString(),
            assertion: step['assertion']?.toString(),
            hint: step['hint']?.toString(),
            successCriteria: success?.toString(),
          );
        }).toList(),
      );
    }).toList();
  }

  /// Creates one release test via the generated v1alpha client. Retries on
  /// 5xx with exponential backoff (1s/2s/4s/8s, up to 5 attempts).
  Future<String> _createReleaseTest({
    required String releaseName,
    required String? displayName,
    required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps,
    required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices,
    required fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential,
  }) async {
    final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest request = buildReleaseTest(
      displayName: displayName,
      steps: steps,
      devices: devices,
      loginCredential: loginCredential,
      resultsBucket: argResults!['results-bucket'] as String?,
    );
    final fad_v1alpha.FirebaseAppDistributionApi api = fad_v1alpha.FirebaseAppDistributionApi(_testClient);

    const int maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest created =
            await api.projects.apps.releases.tests.create(request, releaseName);
        return created.name!;
      } on commons.DetailedApiRequestError catch (e) {
        if ((e.status ?? 0) < 500 || attempt == maxAttempts) {
          rethrow;
        }
        final Duration backoff = Duration(seconds: 1 << (attempt - 1));
        stderr.writeln('  createReleaseTest got ${e.status}, retrying in '
            '${backoff.inSeconds}s (attempt $attempt/$maxAttempts)');
        await Future<void>.delayed(backoff);
      }
    }
    throw StateError('unreachable');
  }

  /// Polls a release test until every device execution is terminal. Returns
  /// whether they all passed. A null [timeout] waits indefinitely.
  Future<bool> _awaitResult(String testName, Duration? timeout) async {
    final fad_v1alpha.FirebaseAppDistributionApi api = fad_v1alpha.FirebaseAppDistributionApi(_testClient);
    final DateTime? deadline = timeout == null ? null : DateTime.now().add(timeout);
    while (deadline == null || DateTime.now().isBefore(deadline)) {
      final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest test =
          await api.projects.apps.releases.tests.get(testName);
      final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution> executions =
          test.deviceExecutions ?? <fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution>[];

      final bool done = executions.isNotEmpty &&
          executions.every((fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution e) =>
              (e.state ?? 'IN_PROGRESS') != 'IN_PROGRESS');
      if (done) {
        bool passed = true;
        for (final fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution execution in executions) {
          final String state = execution.state ?? 'INCONCLUSIVE';
          if (state != 'PASSED') {
            passed = false;
            final String reason = execution.failedReason ?? execution.inconclusiveReason ?? '';
            stdout.writeln('  $red$state on ${execution.device?.model}: $reason$reset');
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
    await initFirebase();

    final String? refreshToken = (argResults!['token'] as String?) ?? Platform.environment['FIREBASE_TOKEN'];
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _testClient = _userClient(refreshToken);
    } else {
      stdout.writeln('No Firebase user token (--token / FIREBASE_TOKEN); '
          'using the service account for the App Testing release-tests API.');
      _testClient = googleClient!;
    }

    final String path = _getPath();
    final String appId = await execute(() async => (await getAndroidApp()).appId!, 'Fetch application id');
    final String releaseName =
        await execute(() => _upload(path: path, appId: appId), 'Upload release (no distribution)');

    final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices =
        (argResults!['device'] as List<String>).map(_device).toList();
    final fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential = _loginCredential();
    final List<({String? displayName, List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps})> tests =
        _readTests();
    final bool wait = argResults!['wait'] as bool;
    final Duration? timeout =
        wait ? null : Duration(minutes: int.tryParse(argResults!['timeout'] as String) ?? 15);

    final Map<String, String> started = <String, String>{};
    await execute(
      () async {
        for (final ({String? displayName, List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps}) test
            in tests) {
          final String testName = await _createReleaseTest(
            releaseName: releaseName,
            displayName: test.displayName,
            steps: test.steps,
            devices: devices,
            loginCredential: loginCredential,
          );
          started[test.displayName ?? testName] = testName;
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
