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
      );
  }

  @override
  final String name = 'dart:format';

  @override
  final String description = 'Runs the dart formatter and exists with a non 0 code when there are issues.';

  @override
  FutureOr<dynamic> run() async {
    final bool modify = argResults!['modify'] ?? false;

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

      final List<List<String>> chunks = _chunkList(files, 50); // Adjust the chunk size as needed

      for (final List<String> chunk in chunks) {
        await execute(
              () => runCommand(
            'dart',
            <String>['format', '-l', '120', if (!modify) '--set-exit-if-changed', ...chunk],
            workingDirectory: module,
          ),
          description,
        );
      }
    }
  }

  List<List<String>> _chunkList(List<String> list, int chunkSize) {
    final List<List<String>> chunks = [];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }
}
