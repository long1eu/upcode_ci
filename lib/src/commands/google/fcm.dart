// File created by
// Lung Razvan <long1eu>
// on 09/05/2020

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/fcm/v1.dart';
import 'package:upcode_ci/src/commands/command.dart';

class FcmCommand extends UpcodeCommand {
  FcmCommand(Map<String, dynamic> config) : super(config) {
    addSubcommand(DartAnalyzeCommand(config));
  }

  @override
  final String name = 'fcm';

  @override
  final String description = 'Adds or remove environments';
}

class DartAnalyzeCommand extends UpcodeCommand {
  DartAnalyzeCommand(Map<String, dynamic> config) : super(config) {
    argParser.addOption(
      'message',
      abbr: 'm',
      help:
          'File that contains the message object as described here: https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#Message',
    );
  }

  @override
  final String name = 'send';

  @override
  final String description = 'Send a notification to a device.';

  @override
  FutureOr<dynamic> run() async {
    await initFirebase();

    final File file = File(argResults!['message']);
    final Map<String, dynamic> data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    final ProjectsResource projects = FirebaseCloudMessagingApi(googleClient!).projects;
    final SendMessageRequest request = SendMessageRequest(message: Message.fromJson(data));

    try {
      final Message response = await projects.messages.send(request, firebaseProjectName);

      stdout.writeln(const JsonEncoder.withIndent('  ').convert(response.toJson()));
      exit(0);
    } catch (e) {
      if (e is DetailedApiRequestError) {
        stderr.writeln(e.jsonResponse);
      }

      rethrow;
    }
  }
}
