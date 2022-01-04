// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:io';

import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/proto/remove_proto_references.dart';

class ProtosCommand extends UpcodeCommand {
  ProtosCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addFlag('all', defaultsTo: false, help: 'Build all files.')
      ..addFlag('js', defaultsTo: false, help: 'Build js proto files.')
      ..addFlag('dart', defaultsTo: false, help: 'Build dart proto files.')
      ..addFlag('descriptor', defaultsTo: false, help: 'Generate API descriptor for Cloud Endpoints.');
  }

  @override
  final String name = 'protos';

  @override
  final String description = 'Generate implementation files in dart and js, and the API descriptor from proto files.';

  void _deleteCurrent(List<String> dirs) {
    for (final String dir in dirs) {
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
      .where((File element) => element.path.endsWith('.proto'))
      .map((File element) => element.path)
      .toList();

  @override
  FutureOr<dynamic> run() async {
    if (!flutterGeneratedDir.dir.existsSync()) {
      flutterGeneratedDir.dir.createSync(recursive: true);
    }

    bool buildJs;
    bool buildDart;
    bool descriptor;
    if (!argResults!.wasParsed('js') && !argResults!.wasParsed('dart') && !argResults!.wasParsed('descriptor')) {
      buildJs = true;
      buildDart = true;
      descriptor = true;
    } else {
      final bool all = argResults!['all'];
      buildJs = argResults!['js'] || all;
      buildDart = argResults!['dart'] || all;
      descriptor = argResults!['descriptor'] || all;
    }

    if (!buildJs && !buildDart && !descriptor) {
      stdout.writeln('Nothing to build.');
      return;
    }

    final List<String> dirsToDelete = <String>[if (buildDart) dartProtoDir, if (buildJs) protoApiOutDir];
    if (dirsToDelete.isNotEmpty) {
      execute(() => _deleteCurrent(dirsToDelete), 'Delete existing proto implementation');
    }

    if (!protoApiOutDir.existsSync()) {
      Directory(protoApiOutDir).createSync(recursive: true);
    }
    if (!dartProtoDir.existsSync()) {
      Directory(dartProtoDir).createSync(recursive: true);
    }

    String? jsPluginPath;
    if (buildJs) {
      final ProcessResult result =
          Process.runSync(Platform.isWindows ? 'where' : 'which', <String>['grpc_tools_node_protoc_plugin']);
      jsPluginPath = '${result.stdout}'.split('\n').first;
    }

    await execute(
      () {
        return runCommand(
          'protoc',
          <String>[
            if (buildJs) ...<String>[
              '--js_out=import_style=commonjs,binary:$protoApiOutDir',
              '--ts_out=generate_package_definition:$protoApiOutDir',
              '--grpc_out=generate_package_definition,grpc_js:$protoApiOutDir',
              '--plugin=protoc-gen-grpc=$jsPluginPath',
            ],
            if (buildDart) '--dart_out=grpc:$dartProtoDir',
            if (descriptor) ...<String>[
              '--include_imports',
              '--include_source_info',
              '--descriptor_set_out=$apiDescriptor',
            ],
            '--proto_path=$protoSrcDir',
            ..._protoFiles
          ],
          workingDirectory: Directory.current.path,
        );
      },
      'Proto building: ${<String>[
        if (buildJs) 'js implementation',
        if (buildDart) 'dart implementation',
        if (descriptor) 'api descriptor',
      ].join(', ')}',
    );

    if (descriptor) {
      execute(() => removeProtoReferences(apiDescriptor),
          'Scrub google fields out of the api descriptor. See https://gist.github.com/kristiandrucker/d3a7c7b8e64f55ad4ebfa3634a96d5fe and https://issuetracker.google.com/issues/210014211');
    }
  }
}
