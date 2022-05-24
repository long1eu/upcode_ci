// File created by
// Lung Razvan <long1eu>
// on 03/01/2021

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_beta/firebase/v1beta1.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:upcode_ci/src/commands/command.dart';

mixin VersionMixin on UpcodeCommand {
  String get versionType {
    return split(normalize(File(flutterDir).absolute.path)).last;
  }

  Future<Uri> getDatabaseUrl() async {
    await initFirebase();
    final FirebaseProject result = await projectsApi.get(firebaseProjectName);
    final String baseUrl = result.resources!.realtimeDatabaseInstance!;
    final String databaseKey = join(privateDir, 'firebase_database.key').readAsStringSync();

    return Uri.parse('https://$baseUrl.firebaseio.com/$versionType/.json?auth=$databaseKey');
  }

  Future<Map<String, dynamic>> getRawVersion() async {
    final Uri url = await getDatabaseUrl();
    final Response data = await get(url);
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
    final Uri url = await getDatabaseUrl();
    final Response data = await patch(url, body: jsonEncode(version));

    if (data.statusCode < 200 || data.statusCode >= 300) {
      throw StateError(data.body);
    }
  }
}
