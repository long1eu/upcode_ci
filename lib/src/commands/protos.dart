// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';

class ProtosCommand extends UpcodeCommand {
  ProtosCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'protos';

  @override
  final String description = 'Generate implementation files in dart from proto files.';

  void _deleteCurrent(List<String> dirs) {
    for (String dir in dirs) {
      final Directory outDir = Directory(dir);
      if (outDir.existsSync()) {
        outDir.deleteSync(recursive: true);
      }

      outDir.createSync(recursive: true);
    }
  }

  List<String> get _protoFiles => Directory(protoSrcDir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((element) => element.path.endsWith('.proto'))
      .map((element) => element.path)
      .toList();

  List<String> get _generatedDartFiles => Directory(dartProtoDir)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((File file) => file.path.endsWith('.dart'))
      .map((File file) => file.path.split(join('lib', 'generated'))[1])
      .where((String path) => !path.contains('${context.separator}struct.'))
      .map((String path) => "export '${path.split(context.separator).skip(1).join('/')}';")
      .toList()
        ..sort();

  void _buildDartImports() {
    File(join(flutterGeneratedDir, 'protos.dart')).writeAsStringSync('''// GENERATED FILE, DO NOT EDIT
// Last update ${DateFormat.yMMMMd().add_Hm().format(DateTime.now().toUtc())}

library protos;

${_generatedDartFiles.join('\n')}
''');
  }

  @override
  FutureOr<dynamic> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    final List<String> dirsToDelete = <String>[dartProtoDir];
    if (dirsToDelete.isNotEmpty) {
      execute(() => _deleteCurrent(dirsToDelete), 'Delete existing proto implementation');
    }

    await execute(
      () {
        return runCommand(
          'protoc',
          <String>[
            '--dart_out=grpc:$dartProtoDir',
            '--proto_path=$protoSrcDir',
            ..._protoFiles,
          ],
          workingDirectory: pwd,
        );
      },
      'Proto building dart implementation',
    );

    execute(_buildDartImports, 'Build Dart import file');
  }
}
