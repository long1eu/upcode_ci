// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:upcode_ci/src/commands/command.dart';

class DartFormatCommand extends UpcodeCommand {
  DartFormatCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addFlag(
        'modify',
        defaultsTo: false,
        help:
        'If false it will only check if there are changes that need to be done and exists with non 0 code if so. If true it will format the code.',
      )
      ..addMultiOption(
        'module',
        help: 'Select what modules you want to check.',
      )
      ..addFlag(
        'chunks',
        defaultsTo: false,
        help: 'If true, the command will run in chunks to avoid command length limits (mainly on Windows).',
      );
  }

  @override
  final String name = 'dart:format';

  @override
  final String description = 'Runs the dart formatter and exists with a non 0 code when there are issues.';

  @override
  FutureOr<dynamic> run() async {
    final bool modify = argResults!['modify'] ?? false;
    bool chunks = argResults!['chunks'] ?? false;

    if (Platform.isWindows) {
      chunks = true;
    }

    List<String> modules;
    if (argResults!.wasParsed('module')) {
      modules = List<String>.from(argResults!['module']).map((String item) => item.dirName).toList();
    } else {
      modules = formattedModules;
    }

    for (final String module in modules) {
      final List<String> files = Directory(module)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .map((File it) => it.path.split('$module${path.separator}')[1])
          .where(fileFilter)
          .toList();

      if (chunks) {
        final List<List<String>> fileChunks = _chunkList(files, 100);

        for (final List<String> chunk in fileChunks) {
          await execute(
                () => runCommand(
              'dart',
              <String>['format', '-l', '120', if (!modify) '--set-exit-if-changed', ...chunk],
              workingDirectory: module,
            ),
            description,
          );
        }
      } else {
        await execute(
              () => runCommand(
            'dart',
            <String>['format', '-l', '120', if (!modify) '--set-exit-if-changed', ...files],
            workingDirectory: module,
          ),
          description,
        );
      }
    }
  }

  List<List<String>> _chunkList(List<String> list, int chunkSize) {
    final List<List<String>> chunks = <List<String>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
}
