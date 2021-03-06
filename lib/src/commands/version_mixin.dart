// File created by
// Lung Razvan <long1eu>
// on 03/01/2021

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';

mixin VersionMixin on UpcodeCommand {
  String get versionType {
    return split(normalize(File(flutterDir).absolute.path)).last;
  }

  Uri get databaseUrl {
    final String databaseKey = join(privateDir, 'firebase_database.key').readAsStringSync();
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(jsonDecode(join(androidAppDir, 'google-services.json').readAsStringSync()));

    if (data['project_info'] != null && data['project_info']['firebase_url'] != null) {
      return Uri.parse('${data['project_info']['firebase_url']}/$versionType/.json?auth=$databaseKey');
    }

    return Uri.parse('https://$projectId.firebaseio.com/$versionType/.json?auth=$databaseKey');
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
