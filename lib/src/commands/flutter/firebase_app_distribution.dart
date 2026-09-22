// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:googleapis/firebaseappdistribution/v1.dart';
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

/// Default test device. API 34: the App Testing agent could not type into text fields on the
/// API 36 emulator image (2026-09-06), while 33-35 logged in within a minute.
const String kDefaultAiTestDevice = 'model=MediumPhone.arm,version=34,locale=en,orientation=portrait';

final RegExp _bucketName = RegExp(r'^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$');

/// The `resultsBucket` value the release-tests API expects: a project-scoped
/// resource path, not a bare bucket name. Mirrors the Firebase CLI's
/// `getResultsBucket`. Null when no bucket is given, so Firebase uses its default.
String? resultsBucketResource(String? bucket, String appId) {
  if (bucket == null || bucket.isEmpty) {
    return null;
  }
  final String name = bucket.startsWith('gs://') ? bucket.substring(5) : bucket;
  if (!_bucketName.hasMatch(name)) {
    throw FormatException('Invalid results bucket name "$bucket".');
  }
  final List<String> parts = appId.split(':');
  if (parts.length < 2 || parts[1].isEmpty) {
    throw FormatException('Invalid Firebase app id "$appId".');
  }
  return 'projects/${parts[1]}/buckets/$name';
}

/// One test case as written in the YAML.
class AiTestDefinition {
  const AiTestDefinition({
    required this.displayName,
    required this.id,
    required this.prerequisiteTestCaseId,
    required this.steps,
  });

  final String? displayName;
  final String? id;
  final String? prerequisiteTestCaseId;
  final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps;

  AiTestDefinition withSteps(List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps) {
    return AiTestDefinition(
      displayName: displayName,
      id: id,
      prerequisiteTestCaseId: prerequisiteTestCaseId,
      steps: steps,
    );
  }
}

/// Parses the test-case YAML. Accepts both `successCriteria` and
/// `finalScreenAssertion` for the success text.
List<AiTestDefinition> parseAiTests(String yaml) {
  final dynamic doc = loadYaml(yaml);
  final List<dynamic> tests = (doc['tests'] as List<dynamic>?) ?? <dynamic>[];
  return tests.map((dynamic test) {
    final List<dynamic> steps = (test['steps'] as List<dynamic>?) ?? <dynamic>[];
    return AiTestDefinition(
      displayName: (test['displayName'] ?? test['name'])?.toString(),
      id: test['id']?.toString(),
      prerequisiteTestCaseId: test['prerequisiteTestCaseId']?.toString(),
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

/// Prepends each test's prerequisite chain to its own steps, outermost first,
/// the way the Firebase CLI's `parseTestFiles` does. Inline AI instructions
/// have no prerequisite concept, so a dependent test has to carry the steps
/// that put the app into the state it expects.
List<AiTestDefinition> flattenPrerequisites(List<AiTestDefinition> tests) {
  final Map<String, AiTestDefinition> byId = <String, AiTestDefinition>{
    for (final AiTestDefinition test in tests)
      if (test.id != null) test.id!: test,
  };
  return tests.map((AiTestDefinition test) {
    final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> prefix =
        <fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep>[];
    final Set<String> visited = <String>{};
    String? prerequisite = test.prerequisiteTestCaseId;
    while (prerequisite != null) {
      if (!visited.add(prerequisite)) {
        throw FormatException('Cycle in prerequisite test cases at "$prerequisite".');
      }
      final AiTestDefinition? dependency = byId[prerequisite];
      if (dependency == null) {
        throw FormatException(
          'Unknown prerequisiteTestCaseId "$prerequisite" on test "${test.displayName ?? test.id}".',
        );
      }
      prefix.insertAll(0, dependency.steps);
      prerequisite = dependency.prerequisiteTestCaseId;
    }
    return test.withSteps(<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep>[...prefix, ...test.steps]);
  }).toList();
}

/// Parses `model=<id>,version=<api>,locale=<locale>,orientation=<o>`; locale
/// and orientation default to the Firebase CLI's `en_US` and `portrait`.
fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice parseTestDevice(String spec) {
  final Map<String, String> parts = <String, String>{
    for (final String pair in spec.split(',')) pair.split('=').first.trim(): pair.split('=').last.trim(),
  };
  return fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice(
    model: parts['model'],
    version: parts['version'],
    locale: parts['locale'] ?? 'en_US',
    orientation: parts['orientation'] ?? 'portrait',
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
/// Every API call authenticates with the project's service account.
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
      ..addMultiOption(
        'device',
        help: 'Device(s) to test on, formatted as '
            'model=<id>,version=<api>,locale=<locale>,orientation=<portrait|landscape>. '
            'Repeat the flag for multiple devices.',
        splitCommas: false,
        defaultsTo: <String>[kDefaultAiTestDevice],
      )
      ..addOption(
        'results-bucket',
        help: 'GCS bucket for raw test artifacts (logs, video, screenshots), as a bare name '
            'or gs:// URL. When omitted, Firebase uses its default bucket.',
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

  /// Reads the YAML test cases and flattens each prerequisite chain into the test's steps.
  List<AiTestDefinition> _readTests() {
    return flattenPrerequisites(parseAiTests(File(argResults!['tests'] as String).readAsStringSync()));
  }

  /// Creates one release test via the generated v1alpha client. Retries on
  /// 5xx with exponential backoff (1s/2s/4s/8s, up to 5 attempts).
  Future<String> _createReleaseTest({
    required String releaseName,
    required String? displayName,
    required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps,
    required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices,
    required fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential,
    required String? resultsBucket,
  }) async {
    final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest request = buildReleaseTest(
      displayName: displayName,
      steps: steps,
      devices: devices,
      loginCredential: loginCredential,
      resultsBucket: resultsBucket,
    );
    final fad_v1alpha.FirebaseAppDistributionApi api = fad_v1alpha.FirebaseAppDistributionApi(googleClient!);

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
    final fad_v1alpha.FirebaseAppDistributionApi api = fad_v1alpha.FirebaseAppDistributionApi(googleClient!);
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

    final String path = _getPath();
    final String appId = await execute(() async => (await getAndroidApp()).appId!, 'Fetch application id');
    final String releaseName =
        await execute(() => _upload(path: path, appId: appId), 'Upload release (no distribution)');

    final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices =
        (argResults!['device'] as List<String>).map(parseTestDevice).toList();
    final fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential = _loginCredential();
    final List<AiTestDefinition> tests = _readTests();
    final String? resultsBucket = resultsBucketResource(argResults!['results-bucket'] as String?, appId);
    final bool wait = argResults!['wait'] as bool;
    final Duration? timeout =
        wait ? null : Duration(minutes: int.tryParse(argResults!['timeout'] as String) ?? 15);

    final Map<String, String> started = <String, String>{};
    await execute(
      () async {
        for (final AiTestDefinition test in tests) {
          final String testName = await _createReleaseTest(
            releaseName: releaseName,
            displayName: test.displayName,
            steps: test.steps,
            devices: devices,
            loginCredential: loginCredential,
            resultsBucket: resultsBucket,
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
