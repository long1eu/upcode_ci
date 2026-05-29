# upcode_ci

[![pub package](https://img.shields.io/pub/v/upcode_ci.svg)](https://pub.dev/packages/upcode_ci)

A collection of CI/CD automation tools used by the Upcode team. It ships a
single `upcode` executable that wraps the repetitive Flutter, Google Cloud, and
Firebase tasks that surround a typical app: code generation, formatting,
analysis, versioning, environment management, protobuf compilation, and
distribution.

## Installation

```sh
dart pub global activate upcode_ci
```

This installs the `upcode` command globally. Make sure `~/.pub-cache/bin` is on
your `PATH`.

## Quick start

Every `upcode` command must be run from a directory that contains an
`upcode.yaml` file. The file describes where the Flutter app, API, and private
material live, and which Google Cloud project to target.

```sh
cd my-project        # directory containing upcode.yaml
upcode flutter:all   # run a command
upcode help          # list every command
upcode help <command>
```

If `upcode.yaml` is missing, the command exits with:

```
You need to call this command from the same directory as you upcode.yaml file.
```

### fvm support

When the target Flutter project is fvm-configured — it has a `.fvmrc` file or a
`.fvm/` directory in any parent directory — and the `fvm` binary is on `PATH`,
`upcode` runs `flutter` and `dart` through `fvm` so the pinned SDK is used. If
`fvm` is not installed it falls back to the bare `flutter`/`dart` executables.

## Configuration

`upcode.yaml` lives at the root of your repository. Keys may be overridden per
invocation with global options (see below).

```yaml
# Google Cloud
google_project_id: my-project
google_project_location: europe-west1

# Application identifiers
base_application_id: com.example.app
# Optional per-platform overrides; default to base_application_id
android_application_id: com.example.app.android
ios_application_id: com.example.app.ios

# Directories (paths relative to upcode.yaml)
private_dir: private          # holds service_account.json
flutter_dir: app              # the Flutter module
api_dir: api                  # the backend module
api_dockerfile_dir: api       # optional, defaults to api_dir
protos_dir: app/res/protos    # optional, defaults to <flutter_dir>/res/protos
protos_output_dir: generated  # optional

# Module lists (optional; default to [flutter_dir])
modules: [app, packages/core]
generated: [app]              # modules that run build_runner
analyzed: [app]               # modules analyzed by flutter:analyze
formatted: [app]              # modules formatted by flutter:format
tested: [app]                 # modules tested by flutter:test

# Nested maps consumed by the version commands
api: { ... }
api_config: { ... }
```

| Key | Required | Description |
| --- | --- | --- |
| `google_project_id` | yes | Google Cloud / Firebase project id. |
| `google_project_location` | for API commands | Cloud project location, e.g. `europe-west1`. |
| `base_application_id` | yes | Default application id; falls back for Android and iOS. |
| `android_application_id` | no | Overrides `base_application_id` for Android. |
| `ios_application_id` | no | Overrides `base_application_id` for iOS. |
| `private_dir` | for Google/Firebase commands | Directory containing `service_account.json`. |
| `flutter_dir` | yes | Path to the Flutter module. |
| `api_dir` | for API commands | Path to the backend module. A Dart backend is detected by a `pubspec.yaml` inside it. |
| `api_dockerfile_dir` | no | Dockerfile location when it lives outside `api_dir`. |
| `protos_dir` | no | Source `.proto` directory. |
| `protos_output_dir` | no | Generated protobuf output directory. |
| `modules` | no | Modules acted on by default. Defaults to `[flutter_dir]`. |
| `generated` / `analyzed` / `formatted` / `tested` | no | Per-task module overrides. |

### Authentication

Commands that talk to Google Cloud, Firebase, or the Play Store authenticate
with a service account. Place its key at `<private_dir>/service_account.json`.

### Global options

Every command accepts these options, which override the matching `upcode.yaml`
values for that run:

```
--flutter_dir            The Flutter module to run the command in.
--private_dir            The private module.
--api_dir                The API module.
--api_dockerfile_dir     Dockerfile location when outside api_dir.
--protos_dir             The protos module.
--google_project_location  The project location.
```

## Commands

Run `upcode help <command>` for the full options of any command.

### Flutter

| Command | Description |
| --- | --- |
| `flutter:all` | Generate every derived Dart file: runs `flutter:buildrunner`, `flutter:i18n`, and `protos`. |
| `flutter:buildrunner` | Run `build_runner` to generate Flutter files. |
| `flutter:i18n` | Generate the internationalization files. |
| `flutter:analyze` | Run the analyzer; exits non-zero on issues. |
| `flutter:format` | Run the formatter; exits non-zero when changes are needed. |
| `flutter:test` | Run the tests across the configured modules. |
| `flutter:version` | Manage the Flutter app version. Subcommands: `read`, `increment`, `set`. |
| `flutter:releaseNotes` | Save the latest commits as release notes. |

### Dart

| Command | Description |
| --- | --- |
| `dart:analyze` | Run the analyzer; exits non-zero on issues. |
| `dart:format` | Run the formatter; exits non-zero when changes are needed. |

### Distribution

| Command | Description |
| --- | --- |
| `fad` | Work with Firebase App Distribution. Subcommands: `upload`, `ai-test`, `deleteOldReleases`. |
| `testlab` | Run Android integration tests on Firebase Test Lab. Subcommand: `run`. |
| `flutter:fastlane` | Distribute the app on the App Store and Play Store. |

### Protobufs

| Command | Description |
| --- | --- |
| `protos` | Generate implementations and the API descriptor from `.proto` files. Flags: `--all`, `--flutter` (alias `--dart`), `--backend` (alias `--js`), `--descriptor`. |

### API

| Command | Description |
| --- | --- |
| `api:deploy` | Build and deploy the backend. Subcommands: `gcloud_build_image`, `endpoints`, `gateway`, `service`, `all`. |
| `api:environment` | Manage API environments. Subcommands: `create`, `set`. |
| `api:version` | Update the API version from the cloud version. Subcommands: `read`, `increment`. |

### Environments & Google

| Command | Description |
| --- | --- |
| `environment` | Set the active environment for both the API and Flutter app. Subcommand: `set`. |
| `flutter:environment` | Manage Flutter environments. Subcommand: `set`. |
| `google` | Google API operations, e.g. `google fcm send` to send a push notification. |

> An **environment** is a collection of settings that isolates the services
> `upcode` manages from one another, so that changes to a service in one
> environment never affect the same service in another.

## License

See [LICENSE](LICENSE).
