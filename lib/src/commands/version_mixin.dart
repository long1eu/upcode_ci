// File created by
// Lung Razvan <long1eu>
// on 03/01/2021

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';

mixin VersionMixin on UpcodeCommand {
  String get versionType => split(flutterDir).last;

  String get databaseUrl {
    final String databaseKey = join(privateDir, 'firebase_database.key').readAsStringSync();
    return 'https://$projectId.firebaseio.com/$versionType/.json?auth=$databaseKey';
  }

  Future<Version> getVersion() async {
    final Response data = await get(databaseUrl);
    final Map<dynamic, dynamic> values = jsonDecode(data.body) ?? <dynamic, dynamic>{};

    return Version.parse(values['versionName'] ?? '0.0.0');
  }

  Future<void> setVersion(Version version) async {
    await patch(
      databaseUrl,
      body: jsonEncode(
        <String, dynamic>{
          'versionCode': version.versionCode,
          'versionName': version.versionName,
        },
      ),
    );
  }
}
