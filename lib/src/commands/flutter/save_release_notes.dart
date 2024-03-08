// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/version_mixin.dart';

const String _hashKey = 'hash';
const String _commitKey = 'commit';
const String _messageKey = 'message';

class SaveReleaseNotesCommand extends UpcodeCommand with VersionMixin {
  SaveReleaseNotesCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'flutter:releaseNotes';

  @override
  final String description = 'Save the latest commits as release notes';

  Future<String> _getCommit() async {
    final Response data = await get(await getDatabaseUrl());
    final Map<dynamic, dynamic> values = jsonDecode(data.body) ?? <dynamic, dynamic>{};

    return values['commit'] ?? '';
  }

  Future<void> _setCommit(String latestCommit) async {
    await patch(await getDatabaseUrl(), body: '{"commit": "$latestCommit"}');
  }

  @override
  FutureOr<dynamic> run() async {
    final String latestCommit = await _getCommit();
    final List<Map<String, dynamic>> commits = await getLastCommits(latestCommit);

    final String releaseNotes = commits.isEmpty
        ? 'Nothing committed yet'
        : commits.map((Map<String, dynamic> it) => '${it[_hashKey]} - ${it[_messageKey]}').join('\n');
    if (commits.isNotEmpty) {
      _setCommit(commits.first[_commitKey]);
    } else {
      print('No new commits.');
    }

    File(join(pwd, 'release_notes.txt')).writeAsStringSync(releaseNotes);
  }
}

Future<List<Map<String, dynamic>>> getLastCommits(String lastReleasedCommit) async {
  final Process getCommits = await Process.start(
    'git',
    <String>[
      'log',
      '--pretty=format:{\"$_hashKey\": \"%h\", \"$_commitKey\": \"%H\", \"$_messageKey\": \"%f\"}',
    ],
  );

  final List<Map<String, dynamic>> commits = await getCommits.stdout //
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .map(jsonDecode)
      .cast<Map<String, dynamic>>()
      .toList();

  final int index = commits.indexWhere((Map<String, dynamic> it) => lastReleasedCommit == it[_commitKey]);
  return commits.sublist(0, index == -1 ? commits.length : index);
}
