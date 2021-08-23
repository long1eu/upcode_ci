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

  Future<Map<String, dynamic>> getRawVersion() async {
    final Response data = await get(databaseUrl);
    if (data.statusCode < 200 || data.statusCode >= 300) {
      throw StateError(data.body);
    }

    final Map<String, dynamic> values = jsonDecode(data.body) ?? <String, dynamic>{};
    return values;
  }

  Future<Version> getVersion() async {
    final Map<dynamic, dynamic> values = await getRawVersion();
    return Version.parse(values['versionName'] ?? '0.0.0');
  }

  Future<void> setVersion(Version version) async {
    await setRawVersion(<String, dynamic>{
      'versionCode': version.versionCode,
      'versionName': version.versionName,
    });
  }

  Future<void> setRawVersion(Map<String, dynamic> version) async {
    final Response data = await patch(databaseUrl, body: jsonEncode(version));

    if (data.statusCode < 200 || data.statusCode >= 300) {
      throw StateError(data.body);
    }
  }
}
