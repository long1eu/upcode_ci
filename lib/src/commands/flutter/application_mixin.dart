import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:googleapis_beta/firebase/v1beta1.dart';
import 'package:path/path.dart';
import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/environment_mixin.dart';
import 'package:xml2json/xml2json.dart';

mixin ApplicationMixin on EnvironmentMixin {
  String androidApiKey() {
    final Map<String, dynamic> data =
        Map<String, dynamic>.from(jsonDecode(join(androidAppDir, 'google-services.json').readAsStringSync()));

    final List<Map<String, dynamic>> clients = List<Map<String, dynamic>>.from(data['client']);

    final Map<String, dynamic>? clientData = clients.firstWhereOrNull(
      (Map<String, dynamic> element) => element['client_info']['android_client_info']['package_name'] == androidAppId,
    );

    if (clientData == null) {
      throw StateError('There is no Android app for \'$rawEnv\', create the app first.');
    }

    final String? apiKey = clientData['api_key'][0]['current_key'];
    if (apiKey == null || apiKey.isNotEmpty) {
      throw StateError('There is no api key for\'$rawEnv\', create the app first.');
    }

    return apiKey;
  }

  Future<String> iosApiKey() async {
    final Xml2Json transformer = Xml2Json()
      ..parse(join(iosDir, 'Runner', 'GoogleService-Info.plist').readAsStringSync());

    final Map<String, dynamic> dict = jsonDecode(transformer.toGData())['plist']['dict'];
    final int index = List<Map<String, dynamic>>.from(dict['key'])
        .indexWhere((Map<String, dynamic> json) => json['\$t'] == 'API_KEY');
    final String apiKey = dict['string'][index]['\$t'];

    if (!RegExp('AIza[0-9A-Za-z-_]{35}').hasMatch(apiKey)) {
      throw ArgumentError('Unknown api key for iOS app.');
    }

    return apiKey;
  }

  Future<AndroidApp> getAndroidApp() async {
    final ListAndroidAppsResponse data = await androidAppsApi.list(firebaseProjectName);
    final AndroidApp? app = data.apps?.firstWhereOrNull((AndroidApp element) {
      return element.packageName == androidAppId;
    });
    if (app == null) {
      throw ArgumentError(
          'This environment has not been created yet. You need to first call: \nflutter:environment create --env $rawEnv');
    }
    return app;
  }

  Future<IosApp> getIosApp() async {
    final ListIosAppsResponse data = await iosAppsApi.list(firebaseProjectName);
    final IosApp? app = data.apps?.firstWhere((IosApp element) => element.bundleId == iosAppId);
    if (app == null) {
      throw ArgumentError(
          'This environment has not been created yet. You need to first call: \nflutter:environment create --env $rawEnv');
    }
    return app;
  }

  Future<void> saveAndroidConfig() async {
    final AndroidApp androidApp = await execute(getAndroidApp, 'Get Android app data from Firebase');
    final AndroidAppConfig config = await androidAppsApi.getConfig('${androidApp.name}/config');
    join(androidAppDir, config.configFilename).writeAsBytesSync(config.configFileContentsAsBytes);
  }

  Future<void> saveIosConfig() async {
    final IosApp iosApp = await execute(getIosApp, 'Get iOS app data from Firebase');
    final IosAppConfig config = await iosAppsApi.getConfig('${iosApp.name}/config');
    join(iosDir, 'Runner', config.configFilename).writeAsBytesSync(config.configFileContentsAsBytes);
  }
}
