// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:args/src/arg_results.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis/firebaseappdistribution/v1.dart' hide ProjectsResource;
import 'package:googleapis/firestore/v1.dart' hide ProjectsResource;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_beta/firebase/v1beta1.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

AutoRefreshingAuthClient? googleClient;

abstract class UpcodeCommand extends Command<dynamic> {
  UpcodeCommand(this.baseConfig) {
    argParser
      ..addOption('flutter_dir', help: 'Specify the flutter module you want to run this command into.')
      ..addOption('private_dir', help: 'Specify the private module.')
      ..addOption('api_dir', help: 'Specify the api module.')
      ..addOption(
        'api_dockerfile_dir',
        help:
            'Specify the Dockerfile location used by the api module. This can be useful when the file needs to be outside of api_dir.',
      )
      ..addOption('protos_dir', help: 'Specify the protos module.')
      ..addOption('google_project_location', help: 'Specify the project location.');
  }

  final Map<String, dynamic> baseConfig;

  void init() {}

  Map<String, dynamic> get config => _config;

  Map<String, dynamic> get _config {
    init();
    final ArgResults argResults = this.argResults!;
    return <String, dynamic>{
      ...baseConfig,
      // override
      if (argResults.wasParsed('flutter_dir')) 'flutter_dir': argResults['flutter_dir'],
      if (argResults.wasParsed('private_dir')) 'private_dir': argResults['private_dir'],
      if (argResults.wasParsed('api_dir')) 'api_dir': argResults['api_dir'],
      if (argResults.wasParsed('api_dockerfile_dir')) 'api_dockerfile_dir': argResults['api_dockerfile_dir'],
      if (argResults.wasParsed('google_project_location'))
        'google_project_location': argResults['google_project_location'],
    };
  }

  Map<String, dynamic> get flutterConfig {
    final Map<String, dynamic> data = Map<String, dynamic>.from(_config['api_config'] ?? <String, dynamic>{});
    return <String, dynamic>{...data};
  }

  Map<String, dynamic> get apiConfig {
    final Map<String, dynamic> data = Map<String, dynamic>.from(_config['api'] ?? <String, dynamic>{});
    return <String, dynamic>{...data};
  }

  Future<void> initFirebase() async {
    if (googleClient == null) {
      await execute(
        () async {
          final String serviceAccount = join(privateDir, 'service_account.json').readAsStringSync();
          googleClient = await clientViaServiceAccount(
            ServiceAccountCredentials.fromJson(serviceAccount),
            <String>[
              FirebaseManagementApi.firebaseScope,
              FirebaseManagementApi.cloudPlatformScope,
              AndroidPublisherApi.androidpublisherScope,
              'https://www.googleapis.com/auth/userinfo.email',
              'https://www.googleapis.com/auth/firebase.database',
            ],
          );
        },
        'Initializing Firebase API',
      );
    }
  }

  static int _indent = -2;

  int get terminalColumns {
    try {
      return stdout.terminalColumns;
    } catch (_) {
      return 80;
    }
  }

  Future<T> execute<T>(FutureOr<T> Function() function, String message) async {
    final DateTime start = DateTime.now();
    _indent += 2;

    stdout
      ..writeln('-' * terminalColumns)
      ..write('  ' * _indent)
      ..write(bold)
      ..write(cyan)
      ..write('> ')
      ..write(reset)
      ..write(red)
      ..write(message)
      ..writeln(reset)
      ..writeln('-' * terminalColumns);
    final T result = await function();

    final String time = '>>> ${DateTime.now().difference(start)}|';
    if (result != null) {
      stdout //
        ..write('  ' * _indent)
        ..write(bold)
        ..write(cyan)
        ..write(time)
        ..write(reset)
        ..write(red)
        ..write(result)
        ..writeln(reset);
    } else {
      stdout //
        ..write('  ' * _indent)
        ..write(bold)
        ..write(cyan)
        ..write(time)
        ..write(reset);
    }

    stdout //
      ..writeln('-' * (terminalColumns - time.length - 2 * _indent))
      ..writeln('');
    _indent -= 2;
    return result;
  }

  ProjectsResource get projectsApi {
    return FirebaseManagementApi(googleClient!).projects;
  }

  ProjectsAndroidAppsResource get androidAppsApi {
    return FirebaseManagementApi(googleClient!).projects.androidApps;
  }

  ProjectsIosAppsResource get iosAppsApi {
    return FirebaseManagementApi(googleClient!).projects.iosApps;
  }

  OperationsResource get operationsApi {
    return FirebaseManagementApi(googleClient!).operations;
  }

  ProjectsDatabasesDocumentsResource get firestoreDocuments {
    return FirestoreApi(googleClient!).projects.databases.documents;
  }

  ProjectsDatabasesResource get databases {
    return FirestoreApi(googleClient!).projects.databases;
  }

  FirebaseAppDistributionApi get appDistribution {
    return FirebaseAppDistributionApi(googleClient!);
  }

  InappproductsResource get inappproducts {
    return AndroidPublisherApi(googleClient!).inappproducts;
  }

  String get projectId => _config['google_project_id'];

  String get firebaseProjectName => 'projects/$projectId';

  String get baseAppId => _config['base_application_id'];

  String get androidAppId => _config['android_application_id'] ?? _config['base_application_id'];

  String get iosAppId => _config['ios_application_id'] ?? _config['base_application_id'];

  String get pwd => _config['pwd'];

  // .idea
  String get ideaDir => path.join(pwd, '.idea');

  String get workspaceIdea => path.join(ideaDir, 'workspace.xml');

  String get privateDir => _config['private_dir'].replaceAll('/', path.separator);

  // flutter
  String get flutterDir => _config['flutter_dir'].replaceAll('/', path.separator);

  List<String> get modules {
    if (_config.containsKey('modules')) {
      return List<String>.from(_config['modules']).map((String item) => item.dirName).toList();
    } else {
      return <String>[flutterDir.dirName];
    }
  }

  List<String> get generatedModules {
    if (_config.containsKey('generated')) {
      return List<String>.from(_config['generated']).map((String item) => item.dirName).toList();
    } else {
      return <String>[];
    }
  }

  List<String> get analyzedModules {
    if (_config.containsKey('analyzed')) {
      return List<String>.from(_config['analyzed']).map((String item) => item.dirName).toList();
    } else {
      return modules;
    }
  }

  List<String> get formattedModules {
    if (_config.containsKey('formatted')) {
      return List<String>.from(_config['formatted']).map((String item) => item.dirName).toList();
    } else {
      return modules;
    }
  }

  List<String> get testedModules {
    if (_config.containsKey('tested')) {
      return List<String>.from(_config['tested']).map((String item) => item.dirName).toList();
    } else {
      return modules;
    }
  }

  String get androidDir => path.join(flutterDir, 'android');

  String get androidAppDir => path.join(androidDir, 'app');

  String get androidPropertiesDir => path.join(androidDir, 'properties');

  String get iosDir => path.join(flutterDir, 'ios');

  String get macosDir => path.join(flutterDir, 'macos');

  String get flutterResDir => path.join(flutterDir, 'res');

  String get flutterGeneratedDir => path.join(flutterDir, 'lib', 'generated');

  String get flutterProtoDir => path.join(flutterGeneratedDir, 'protos');

  // tools
  String get toolsDir => path.join(pwd, 'ci', 'other_tools');

  // api
  String get apiDir => _config['api_dir'].replaceAll('/', path.separator);

  String get apiDockerfileDir => _config['api_dockerfile_dir'] ?? apiDir;

  String get projectLocation => _config['google_project_location'];

  String get apiConfigFile => path.join(apiDir, 'api_config.yaml');

  String get dartApiGeneratedDir => path.join(apiDir, 'lib', 'generated');

  String get protoSrcDir {
    return _config['protos_dir'].replaceAll('/', path.separator) ?? path.join(flutterResDir, 'protos');
  }

  String get protoApiOutDir {
    if (_config.containsKey('protos_output_dir')) {
      return _config['protos_output_dir'].replaceAll('/', path.separator);
    }

    if (isDartBackend) {
      return path.join(apiDir, 'lib', 'generated', 'protos');
    } else {
      return path.join(apiDir, 'src', 'proto');
    }
  }

  String get apiOutDir {
    if (isDartBackend) {
      return path.join(apiDir, 'lib', 'generated');
    } else {
      return path.join(apiDir, 'src');
    }
  }

  String get apiDescriptor => join(protoSrcDir, 'api_descriptor.pb');

  bool get isDartBackend {
    return Directory(apiDir).listSync().any((FileSystemEntity file) => path.basename(file.path) == 'pubspec.yaml');
  }
}

extension FileString on String {
  String readAsStringSync() => File(this).readAsStringSync();

  List<String> readAsLinesSync() => File(this).readAsLinesSync();

  Map<String, String> readPropertiesFile() {
    return Map<String, String>.fromEntries(readAsLinesSync() //
        .map((String e) => e.split('='))
        .map((List<String> e) => MapEntry<String, String>(e[0], e[1])));
  }

  void writeAsStringSync(String content) => File(this).writeAsStringSync(content);

  void writeAsBytesSync(List<int> content) => File(this).writeAsBytesSync(content);

  bool existsSync() => File(this).existsSync();

  void deleteSync() => File(this).deleteSync();

  Directory get dir => Directory(this);

  String get dirName {
    return path.normalize(dir.absolute.path);
  }
}

extension UpdateVersion on Version {
  int get versionCode => patch + minor * 1000 + major * 100000;

  String get versionName => toString();

  Version patchVersion() {
    if (minor >= 99) {
      return nextMajor;
    } else if (patch >= 999) {
      return nextMinor;
    } else {
      return nextPatch;
    }
  }

  Version releaseVersion() {
    return nextMinor;
  }
}

extension GradleProperties on Map<String, dynamic> {
  String get asProperties {
    final StringBuffer buffer = StringBuffer();
    for (final MapEntry<String, dynamic> entry in entries) {
      buffer
        ..write(entry.key)
        ..write('=')
        ..writeln(entry.value);
    }
    return buffer.toString();
  }
}

final bool hasColor = stdout.supportsAnsiEscapes;

final String bold = hasColor ? '\x1B[1m' : ''; // used for shard titles
final String red = hasColor ? '\x1B[31m' : ''; // used for errors
final String green = hasColor ? '\x1B[32m' : ''; // used for section titles, commands
final String yellow = hasColor ? '\x1B[33m' : ''; // unused
final String cyan = hasColor ? '\x1B[36m' : ''; // used for paths
final String reverse = hasColor ? '\x1B[7m' : ''; // used for clocks
final String reset = hasColor ? '\x1B[0m' : '';
final String redLine = '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';

bool fileFilter(String it) =>
    it.endsWith('.dart') && //
    !it.startsWith('.dart_tool${path.separator}') &&
    !it.startsWith('lib${path.separator}generated') &&
    !it.startsWith('lib${path.separator}src${path.separator}generated') &&
    !it.endsWith('.g.dart') &&
    !it.endsWith('.freezed.dart') &&
    !it.endsWith('.chopper.dart') &&
    !it.endsWith('.gr.dart') &&
    !it.endsWith('.config.dart') &&
    !it.endsWith('.test_coverage.dart');

Future<void> runCommand(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  Map<String, String>? environment,
  bool expectNonZeroExit = false,
  int? expectedExitCode,
  String? failureMessage,
  OutputMode outputMode = OutputMode.print,
  CapturedOutput? output,
  bool skip = false,
  bool Function(String)? removeLine,
}) async {
  assert(
      (outputMode == OutputMode.capture) == (output != null),
      'The output parameter must be non-null with and only with '
      'OutputMode.capture');

  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);
  if (skip) {
    printProgress('SKIPPING', relativeWorkingDir, commandDescription);
    return;
  }
  printProgress('RUNNING', relativeWorkingDir, commandDescription);

  final Stopwatch time = Stopwatch()..start();
  final Process process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    runInShell: Platform.isWindows,
  );

  late Future<List<List<int>>> savedStdout, savedStderr;
  final Stream<List<int>> stdoutSource = process.stdout
      .transform<String>(const Utf8Decoder())
      .transform(const LineSplitter())
      .where((String line) => removeLine == null || !removeLine(line))
      .map((String line) => '$line\n')
      .transform(const Utf8Encoder());
  switch (outputMode) {
    case OutputMode.print:
      final Completer<void> completer1 = Completer<void>();
      final Completer<void> completer2 = Completer<void>();
      stdoutSource.listen(stdout.add, onDone: completer1.complete);
      process.stderr.listen(stderr.add, onDone: completer2.complete);

      await Future.wait<void>(<Future<void>>[completer1.future, completer2.future]);
      break;
    case OutputMode.capture:
    case OutputMode.discard:
      savedStdout = stdoutSource.toList();
      savedStderr = process.stderr.toList();
      break;
  }

  final int exitCode = await process.exitCode;
  print(
      '$clock ELAPSED TIME: ${prettyPrintDuration(time.elapsed)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset');

  if (output != null) {
    output
      ..stdout = _flattenToString(await savedStdout)
      ..stderr = _flattenToString(await savedStderr);
  }

  if ((exitCode == 0) == expectNonZeroExit || (expectedExitCode != null && exitCode != expectedExitCode)) {
    if (failureMessage != null) {
      print(failureMessage);
    }

    // Print the output when we get unexpected results (unless output was
    // printed already).
    switch (outputMode) {
      case OutputMode.print:
        break;
      case OutputMode.capture:
      case OutputMode.discard:
        stdout.writeln(_flattenToString(await savedStdout));
        stderr.writeln(_flattenToString(await savedStderr));
        break;
    }
    print('$redLine\n'
        '${bold}ERROR: ${red}Last command exited with $exitCode (expected: ${expectNonZeroExit ? (expectedExitCode ?? 'non-zero') : 'zero'}).$reset\n'
        '${bold}Command: $green$commandDescription$reset\n'
        '${bold}Relative working directory: $cyan$relativeWorkingDir$reset\n'
        '$redLine');
    exit(1);
  }
}

/// Flattens a nested list of UTF-8 code units into a single string.
String _flattenToString(List<List<int>> chunks) => utf8.decode(chunks.expand<int>((List<int> ints) => ints).toList());

/// Specifies what to do with command output from [runCommand].
enum OutputMode { print, capture, discard }

/// Stores command output from [runCommand] when used with [OutputMode.capture].
class CapturedOutput {
  late String stdout;
  late String stderr;
}

String get clock {
  final DateTime now = DateTime.now();
  return '$reverse▌'
      '${now.hour.toString().padLeft(2, "0")}:'
      '${now.minute.toString().padLeft(2, "0")}:'
      '${now.second.toString().padLeft(2, "0")}'
      '▐$reset';
}

void printProgress(String action, String workingDir, String command) {
  print('$clock $action: cd $cyan$workingDir$reset; $green$command$reset');
}

String prettyPrintDuration(Duration duration) {
  String result = '';
  final int minutes = duration.inMinutes;
  if (minutes > 0) {
    result += '${minutes}min ';
  }
  final int seconds = duration.inSeconds - minutes * 60;
  final int milliseconds = duration.inMilliseconds - (seconds * 1000 + minutes * 60 * 1000);
  return result += '$seconds.${milliseconds.toString().padLeft(3, "0")}s';
}
