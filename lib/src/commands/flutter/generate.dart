// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';

import 'package:upcode_ci/src/commands/command.dart';

class FlutterGenerateCommand extends UpcodeCommand {
  FlutterGenerateCommand(Map<String, dynamic> config) : super(config);

  @override
  final String name = 'flutter:all';

  @override
  final String description =
      'Generate all dart files needed to run the Flutter app. This includes `buildrunner`, `i18n` and `protos`';

  @override
  FutureOr<void> run() async {
    await runner!.run(<String>['flutter:i18n']);
    await runner!.run(<String>['flutter:buildrunner']);
  }
}
