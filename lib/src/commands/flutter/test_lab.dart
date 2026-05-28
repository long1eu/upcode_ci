// File created by
// Lung Razvan <long1eu>

import 'dart:async';
import 'dart:io';

import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis/testing/v1.dart' as testing;
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:uuid/uuid.dart';

class TestLabCommand extends UpcodeCommand with EnvironmentMixin {
  TestLabCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(TestLabRunCommand(config));
  }

  @override
  final String name = 'testlab';

  @override
  final String description = 'Run Android integration tests on Firebase Test Lab';
}

/// Runs the Patrol instrumentation APKs on Firebase Test Lab via the Cloud
/// Testing API.
///
/// Uploads the app + test APKs to the results bucket, then creates one test
/// matrix for the default network and one per configured network profile, all
/// concurrently. The command waits for every matrix and exits non-zero if any
/// of them does not report a `SUCCESS` outcome.
///
/// Devices, network profiles and the other matrix options come from the
/// `test_lab` section of `upcode.yaml` (with the usual per-environment
/// overrides); the APK paths are inferred from the flavor (`--env`).
class TestLabRunCommand extends UpcodeCommand with EnvironmentMixin {
  TestLabRunCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addOption('env', abbr: 'e', help: 'The flavor/environment whose Patrol APKs to test.')
      ..addOption('app-apk', help: 'Path to the app APK. Defaults to the patrol build output for the flavor.')
      ..addOption('test-apk', help: 'Path to the androidTest APK. Defaults to the patrol build output for the flavor.')
      ..addOption('results-bucket', help: 'GCS bucket for APKs and raw results. Defaults to test_lab.results_bucket.')
      ..addOption('timeout', help: 'Per-matrix timeout (e.g. 15m, 900s, or a bare number of minutes).');
  }

  @override
  final String name = 'run';

  @override
  final String description = 'Run a Patrol test matrix on Firebase Test Lab';

  Map<String, dynamic> get _testLab =>
      Map<String, dynamic>.from(config['test_lab'] as Map<dynamic, dynamic>? ?? const <String, dynamic>{});

  String get _flavor => env!;

  String get _appApk {
    if (argResults!.wasParsed('app-apk')) {
      return argResults!['app-apk'] as String;
    }
    return join(flutterDir, 'build', 'app', 'outputs', 'apk', _flavor, 'debug', 'app-$_flavor-debug.apk');
  }

  String get _testApk {
    if (argResults!.wasParsed('test-apk')) {
      return argResults!['test-apk'] as String;
    }
    return join(
        flutterDir, 'build', 'app', 'outputs', 'apk', 'androidTest', _flavor, 'debug', 'app-$_flavor-debug-androidTest.apk');
  }

  bool get _useOrchestrator => _testLab['use_orchestrator'] as bool? ?? true;

  bool get _clearPackageData => _testLab['clear_package_data'] as bool? ?? true;

  bool get _performanceMetrics => _testLab['performance_metrics'] as bool? ?? true;

  int get _flakyTestAttempts => _testLab['flaky_test_attempts'] as int? ?? 1;

  List<String> get _networkProfiles {
    return (_testLab['network_profiles'] as List<dynamic>?)?.map((dynamic e) => '$e').toList() ?? const <String>[];
  }

  String get _testTimeout {
    final String raw = (argResults!['timeout'] as String?) ?? '${_testLab['timeout'] ?? 15}';
    final String value = raw.trim();
    if (value.endsWith('s')) {
      return value;
    }
    if (value.endsWith('m')) {
      return '${int.parse(value.substring(0, value.length - 1)) * 60}s';
    }
    return '${int.parse(value) * 60}s';
  }

  List<testing.AndroidDevice> get _devices {
    final List<dynamic> devices = _testLab['devices'] as List<dynamic>? ?? const <dynamic>[];
    if (devices.isEmpty) {
      throw StateError('Add at least one device under `test_lab.devices` in upcode.yaml.');
    }
    return devices.map((dynamic device) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(device as Map<dynamic, dynamic>);
      return testing.AndroidDevice(
        androidModelId: data['model'] as String,
        androidVersionId: '${data['version']}',
        locale: (data['locale'] ?? 'en') as String,
        orientation: (data['orientation'] ?? 'portrait') as String,
      );
    }).toList();
  }

  Future<String> _upload(storage.StorageApi api, String bucket, String objectName, File file) async {
    await api.objects.insert(
      storage.Object(name: objectName),
      bucket,
      name: objectName,
      uploadMedia: storage.Media(file.openRead(), file.lengthSync()),
      uploadOptions: storage.ResumableUploadOptions(),
    );
    return 'gs://$bucket/$objectName';
  }

  testing.TestMatrix _matrix({
    required String appApkGcs,
    required String testApkGcs,
    required String resultsGcs,
    String? networkProfile,
  }) {
    return testing.TestMatrix(
      projectId: projectId,
      flakyTestAttempts: _flakyTestAttempts,
      testSpecification: testing.TestSpecification(
        testTimeout: _testTimeout,
        disablePerformanceMetrics: !_performanceMetrics,
        androidInstrumentationTest: testing.AndroidInstrumentationTest(
          appApk: testing.FileReference(gcsPath: appApkGcs),
          testApk: testing.FileReference(gcsPath: testApkGcs),
          orchestratorOption: _useOrchestrator ? 'USE_ORCHESTRATOR' : 'DO_NOT_USE_ORCHESTRATOR',
        ),
        testSetup: testing.TestSetup(
          networkProfile: networkProfile,
          environmentVariables: _clearPackageData
              ? <testing.EnvironmentVariable>[testing.EnvironmentVariable(key: 'clearPackageData', value: 'true')]
              : null,
        ),
      ),
      environmentMatrix: testing.EnvironmentMatrix(
        androidDeviceList: testing.AndroidDeviceList(androidDevices: _devices),
      ),
      resultStorage: testing.ResultStorage(
        googleCloudStorage: testing.GoogleCloudStorage(gcsPath: resultsGcs),
      ),
    );
  }

  Future<testing.TestMatrix> _runMatrix(testing.TestingApi api, String label, testing.TestMatrix request) async {
    testing.TestMatrix matrix = await api.projects.testMatrices.create(request, projectId);
    final String id = matrix.testMatrixId!;
    stdout.writeln('[$label] matrix $id created');

    const Set<String> terminal = <String>{'FINISHED', 'ERROR', 'INVALID', 'CANCELLED'};
    while (!terminal.contains(matrix.state)) {
      await Future<void>.delayed(const Duration(seconds: 10));
      matrix = await api.projects.testMatrices.get(projectId, id);
    }
    return matrix;
  }

  @override
  FutureOr<dynamic> run() async {
    if (!argResults!.wasParsed('env')) {
      throw StateError('--env is required (the flavor whose Patrol APKs to run).');
    }

    final String? bucket = (argResults!['results-bucket'] as String?) ?? _testLab['results_bucket'] as String?;
    if (bucket == null) {
      throw StateError('Provide --results-bucket or set `test_lab.results_bucket` in upcode.yaml.');
    }

    await initFirebase();
    final storage.StorageApi storageApi = storage.StorageApi(googleClient!);
    final testing.TestingApi testingApi = testing.TestingApi(googleClient!);

    final String prefix = const Uuid().v4();

    final List<String> apks = await execute(
      () async {
        final String app = await _upload(storageApi, bucket, '$prefix/${basename(_appApk)}', File(_appApk));
        final String test = await _upload(storageApi, bucket, '$prefix/${basename(_testApk)}', File(_testApk));
        return <String>[app, test];
      },
      'Upload APKs to gs://$bucket/$prefix',
    );

    final String resultsBase = 'gs://$bucket/$prefix/results';
    final List<({String label, testing.TestMatrix request})> jobs = <({String label, testing.TestMatrix request})>[
      (
        label: 'default',
        request: _matrix(appApkGcs: apks[0], testApkGcs: apks[1], resultsGcs: '$resultsBase/default'),
      ),
      for (final String profile in _networkProfiles)
        (
          label: profile,
          request: _matrix(
            appApkGcs: apks[0],
            testApkGcs: apks[1],
            resultsGcs: '$resultsBase/$profile',
            networkProfile: profile,
          ),
        ),
    ];

    final List<testing.TestMatrix> results = await execute(
      () => Future.wait(jobs.map((({String label, testing.TestMatrix request}) job) {
        return _runMatrix(testingApi, job.label, job.request);
      })),
      'Run ${jobs.length} test matrix/matrices concurrently',
    );

    bool allPassed = true;
    for (int i = 0; i < jobs.length; i++) {
      final testing.TestMatrix matrix = results[i];
      final bool passed = matrix.state == 'FINISHED' && matrix.outcomeSummary == 'SUCCESS';
      allPassed = allPassed && passed;
      final String details = matrix.invalidMatrixDetails != null ? ' (${matrix.invalidMatrixDetails})' : '';
      stdout.writeln('${passed ? green : red}${passed ? 'PASSED' : 'FAILED'}$reset  ${jobs[i].label}  '
          'state=${matrix.state} outcome=${matrix.outcomeSummary}$details');
    }

    exit(allPassed ? 0 : 1);
  }
}
