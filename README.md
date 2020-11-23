# Environments

In the context of Upcode, an environment is a collection of settings
that configures the services Upcode uses to be isolated from one another,
so that changes in `service A` in environment `x` will not affect in any way
the same `service A` but in `y`.


```
Provides useful automation tools

Usage: upcode <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  flutter:all            Generate all dart files needed to run the Flutter app. This includes `buildrunner`, `i18n` and `protos`
  flutter:analyze        Runs the dart analyzer and exists with a non 0 code when there are issues.
  flutter:buildrunner    Use build_runner to generate Flutter files.
  flutter:environment    Manage Flutter environments.
  flutter:fad            Distribute app on Firebase App Distribution
  flutter:fastlane       Distribute app on App and Play Store
  flutter:format         Runs the dart formatter and exists with a non 0 code when there are issues.
  flutter:i18n           Generate internalization file for Flutter app.
  flutter:releaseNotes   Save the latest commits as release notes
  flutter:test           Runs the all the test in the flutter module.
  flutter:version        Update the flutter app version base on the cloud version value.

Run "upcode help <command>" for more information about a command.
```