// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:googleapis/androidpublisher/v3.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_beta/firebase/v1beta1.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';

AutoRefreshingAuthClient googleClient;

abstract class UpcodeCommand extends Command<dynamic> {
  UpcodeCommand(this._config);

  final Map<String, dynamic> _config;

  Map<String, dynamic> get config {
    final Map<String, dynamic> data = Map<String, dynamic>.from(_config['api_config'] ?? <String, dynamic>{});
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
              FirebaseApi.FirebaseScope,
              FirebaseApi.CloudPlatformScope,
              AndroidpublisherApi.AndroidpublisherScope,
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

  ProjectsAndroidAppsResourceApi get androidAppsApi {
    return FirebaseApi(googleClient).projects.androidApps;
  }

  ProjectsIosAppsResourceApi get iosAppsApi {
    return FirebaseApi(googleClient).projects.iosApps;
  }

  OperationsResourceApi get operationsApi {
    return FirebaseApi(googleClient).operations;
  }

  ProjectsDatabasesDocumentsResourceApi get firestoreDocuments {
    return FirestoreApi(googleClient).projects.databases.documents;
  }

  ProjectsDatabasesResourceApi get databases {
    return FirestoreApi(googleClient).projects.databases;
  }

  InappproductsResourceApi get inappproducts {
    return AndroidpublisherApi(googleClient).inappproducts;
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

  String get privateDir => _config['private_dir'];

  // flutter
  String get flutterDir => _config['flutter_dir'];

  List<String> get modules {
    if (_config.containsKey('modules')) {
      return List<String>.from(_config['modules']);
    } else {
      return <String>[flutterDir];
    }
  }

  List<String> get generatedModules {
    if (_config.containsKey('generated')) {
      return List<String>.from(_config['generated']);
    } else {
      return <String>[];
    }
  }

  List<String> get analyzedModules {
    if (_config.containsKey('analyzed')) {
      return List<String>.from(_config['analyzed']);
    } else {
      return modules;
    }
  }

  List<String> get formattedModules {
    if (_config.containsKey('formatted')) {
      return List<String>.from(_config['formatted']);
    } else {
      return modules;
    }
  }

  List<String> get testedModules {
    if (_config.containsKey('tested')) {
      return List<String>.from(_config['tested']);
    } else {
      return modules;
    }
  }

  String get androidDir => path.join(flutterDir, 'android');

  String get androidAppDir => path.join(androidDir, 'app');

  String get androidPropertiesDir => path.join(androidDir, 'properties');

  String get iosDir => path.join(flutterDir, 'ios');

  String get flutterResDir => path.join(flutterDir, 'res');

  String get flutterGeneratedDir => path.join(flutterDir, 'lib', 'generated');

  // tools
  String get toolsDir => path.join(pwd, 'ci', 'other_tools');
}

extension FileString on String {
  String readAsStringSync() => File(this).readAsStringSync();

  List<String> readAsLinesSync() => File(this).readAsLinesSync();

  Map<String, String> readPropertiesFile() {
    return Map<String, String>.fromEntries(this
        .readAsLinesSync() //
        .map((e) => e.split('='))
        .map((e) => MapEntry(e[0], e[1])));
  }

  void writeAsStringSync(String content) => File(this).writeAsStringSync(content);

  void writeAsBytesSync(List<int> content) => File(this).writeAsBytesSync(content);

  bool existsSync() => File(this).existsSync();

  void deleteSync() => File(this).deleteSync();
}

extension UpdateVersion on Version {
  int get versionCode => this.patch + this.minor * 1000 + this.major * 100000;

  String get versionName => this.toString();

  Version increment() {
    if (this.minor >= 99) {
      return nextMajor;
    } else if (this.patch >= 999) {
      return nextMinor;
    } else {
      return nextPatch;
    }
  }
}

extension GradleProperties on Map<String, dynamic> {
  String get asProperties {
    final StringBuffer buffer = StringBuffer();
    for (var entry in entries) {
      buffer
        ..write(entry.key)
        ..write('=')
        ..writeln(entry.value);
    }
    return buffer.toString();
  }
}

Future<Operation> wait(OperationsResourceApi operationsApi, String operationName) async {
  Operation operation = await operationsApi.get(operationName);
  while (!(operation.done ?? false)) {
    operation = await operationsApi.get(operationName);
    await Future.delayed(const Duration(seconds: 1));
  }
  return operation;
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
    it != '.dart_tool/build/entrypoint/build.dart' &&
    !it.startsWith('lib/generated') &&
    !it.startsWith('lib/src/generated') &&
    !it.endsWith('.g.dart') &&
    !it.endsWith('.freezed.dart') &&
    !it.endsWith('.chopper.dart') &&
    !it.endsWith('.test_coverage.dart');

Future<void> runCommand(
  String executable,
  List<String> arguments, {
  String workingDirectory,
  Map<String, String> environment,
  bool expectNonZeroExit = false,
  int expectedExitCode,
  String failureMessage,
  OutputMode outputMode = OutputMode.print,
  CapturedOutput output,
  bool skip = false,
  bool Function(String) removeLine,
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
  );

  Future<List<List<int>>> savedStdout, savedStderr;
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
  String stdout;
  String stderr;
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
