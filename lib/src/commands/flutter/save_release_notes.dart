// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';

class SaveReleaseNotesCommand extends UpcodeCommand {
  SaveReleaseNotesCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'flutter:releaseNotes';

  @override
  final String description = 'Save the latest commits as release notes';

  Uri get databaseUrl {
    final String databaseKey = join(privateDir, 'firebase_database.key').readAsStringSync();
    return Uri.parse('https://$projectId.firebaseio.com/.json?auth=$databaseKey');
  }

  Future<String> _getCommit() async {
    final Response data = await get(databaseUrl);
    final Map<dynamic, dynamic> values = jsonDecode(data.body) ?? <dynamic, dynamic>{};

    return values['commit'];
  }

  Future<void> _setCommit(String latestCommit) async {
    await patch(databaseUrl, body: '{"commit": "$latestCommit"}');
  }

  @override
  FutureOr<dynamic> run() async {
    final String latestCommit = await _getCommit();
    final List<List<String>> commits = await getLastCommits(latestCommit);

    final String releaseNotes =
        commits.isEmpty ? 'Nothing committed yet' : commits.map((List<String> it) => '${it[0]} - ${it[1]}').join('\n');
    if (commits.isNotEmpty) {
      _setCommit(commits.first.last);
    } else {
      print('No new commits.');
    }

    File(join(pwd, 'release_notes.txt')).writeAsStringSync(releaseNotes);
  }
}

Future<List<List<String>>> getLastCommits(String lastReleasedCommit) async {
  final Process getCommits = await Process.start('git', <String>['log', '--pretty=format:[\"%h\", \"%s\", \"%H\"]']);
  final List<String> commitsData = await getCommits.stdout //
      .transform(const Utf8Decoder())
      .transform(const LineSplitter())
      .toList();

  final List<List<String>> commits = commitsData.map((String json) => List<String>.from(jsonDecode(json))).toList();
  final int index = commits.indexWhere((List<String> it) => lastReleasedCommit == it[2]);
  return commits.sublist(0, index == -1 ? commits.length : index);
}
