// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:upcode_ci/src/commands/command.dart';

class FlutterFormatCommand extends UpcodeCommand {
  FlutterFormatCommand(Map<String, dynamic> config) : super(config) {
    argParser
      ..addFlag(
        'modify',
        defaultsTo: false,
        help:
            'If false it will only check if there are changes that need to be done and exits with non 0 code if so. If true it will format the code.',
      )
      ..addMultiOption('module', help: 'Select what modules you want to check.')
      ..addFlag(
        'changed',
        defaultsTo: false,
        help: 'Only the files git reports as uncommitted, instead of every file in the module.',
      )
      ..addOption(
        'since',
        help: 'Only the files changed against this ref, plus anything uncommitted. Implies --changed.',
      );
  }

  @override
  final String name = 'flutter:format';

  @override
  final String description = 'Runs the dart formatter and exits with a non 0 code when there are issues.';

  @override
  FutureOr<dynamic> run() async {
    final bool modify = argResults!['modify'] ?? false;

    List<String> modules;
    if (argResults!.wasParsed('module')) {
      modules = List<String>.from(argResults!['module']).map((String item) => item.dirName).toList();
    } else {
      modules = formattedModules;
    }

    // Formatting every file rewrites code nobody touched, and on a large module that is most of
    // the work. With --changed or --since only what git reports is formatted; an empty result means
    // nothing changed, and `slices` then yields no batch, so `dart format` is never called with no
    // paths, which would format the whole directory.
    final String? since = argResults!['since'] as String?;
    final Set<String>? changed = (argResults!['changed'] as bool? ?? false) || since != null
        ? changedFiles(since: since)
        : null;

    for (final String module in modules) {
      List<String> files = formattableFiles(module, formatExclude(module));
      if (changed != null) {
        files = onlyChanged(module, files, changed);
      }

      final List<List<String>> elements = files.slices(100).toList();

      for (final List<String> items in elements) {
        await execute(
          () => runCommand('dart', <String>[
            'format',
            '-l',
            '120',
            if (!modify) '--set-exit-if-changed',
            ...items,
          ], workingDirectory: module),
          description,
        );
      }
    }
  }
}
