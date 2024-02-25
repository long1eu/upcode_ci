// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'package:upcode_ci/src/commands/command.dart';
import 'package:upcode_ci/src/commands/google/fcm.dart';

class GoogleCommand extends UpcodeCommand {
  GoogleCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(FcmCommand(config));
  }

  @override
  final String name = 'google';

  @override
  final String description = 'Google API operations.';
}
