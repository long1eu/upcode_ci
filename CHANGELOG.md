## 0.10.29

`upcode fad ai-test`: fall back to the service account for the App Testing
release-tests API when no Firebase user token is provided. A user token
(`--token` or `FIREBASE_TOKEN`) is still used when present; without one the
command now uses the service-account client instead of failing.

## 0.10.28

Remove the deprecated `upcode flutter:fad` command; use `upcode fad upload`
instead. It has printed a removal warning since 0.10.x.

Consistency cleanup. Remove the stale `bin/main.dart` entrypoint, which
duplicated `bin/upcode.dart` but had drifted (it was missing the `testlab`
command); the published executable already points at `bin/upcode.dart`. Fix
copy-paste leftovers in command metadata: the `fad deleteOldReleases`
description (was the `upload` text), the `environment` group description, the
misleading `--env` help ("environment you want to create" on commands that only
select an existing one), and the `flutter:analyze` description/log (it runs
`flutter analyze`, not the dart analyzer). Correct the "exists"/"exits" typo
across the format/analyze descriptions. Complete the command barrel files
(`flutter`, `dart`, `google`, top-level `index.dart`) and import commands
through the barrel in the entrypoint.

## 0.10.27

Mark `upcode flutter:fad` as deprecated in its `--help` description so the
existing runtime warning is also visible when listing commands; use
`upcode fad upload` instead. Rename the `fcm send` command's implementation
class to `FcmSendCommand` (it was misnamed `DartAnalyzeCommand`) and correct
the `fcm` group description.

## 0.10.26

`upcode fad ai-test`: retry the App Testing `createReleaseTest` call with
exponential backoff (1s/2s/4s/8s, up to 5 attempts) on HTTP 5xx responses, so
transient Firebase server errors don't fail otherwise-healthy runs.

## 0.10.25

`upcode testlab run`: add `test_lab.network_devices`, a separate device list
used for network-profile matrices. Firebase Test Lab only honors network
profiles (traffic shaping) on physical devices, so the default `devices` list
typically stays on a virtual device for speed while `network_devices` points
at a physical model (e.g. `akita` / Pixel 8a). Falls back to `devices` when
absent, preserving previous behavior.

## 0.10.24

Add `upcode testlab run`: run the Patrol instrumentation APKs on Firebase Test
Lab via the Cloud Testing API. Uploads the app and androidTest APKs to the
results bucket, then creates one test matrix for the default network plus one
per configured network profile, all concurrently, and waits for every matrix —
exiting non-zero if any does not report a `SUCCESS` outcome. Devices, network
profiles and matrix options come from the `test_lab` section of `upcode.yaml`
(with per-environment overrides); APK paths are inferred from the flavor
(`--env`).

## 0.10.23

`upcode fad ai-test`: add `--credentials`, a JSON file with TEST_EMAIL and
TEST_PASSWORD (e.g. the dart-define `test_credentials.json`) used for automatic
login, as an alternative to `--username`/`--password`.

## 0.10.22

`upcode fad ai-test`: add `--results-bucket` to store raw test artifacts (logs,
video, screenshots) in a specific GCS bucket, and support an `assertion` field
on test steps — a verification-only step alongside `goal`/`successCriteria`.

## 0.10.21

Add `upcode fad ai-test`: run Firebase App Distribution AI tests on a freshly
uploaded, non-distributed release. The release is uploaded with the service
account, then the App Testing agent (`createReleaseTest`) is driven with a user
token (`--token`, or the `FIREBASE_TOKEN` env var) — the release-tests API does
not accept the service account. The agent logs in automatically from
`--username`/`--password`/`--password-file` and runs the natural-language steps
from a YAML file (`--tests`). Polls every device execution to completion and
exits non-zero if any test fails.

## 0.10.20

Batch files into chunks of 100 when running `dart format` on all platforms.
Previously the batching applied only on Windows.

## 0.10.19

Route `flutter` and `dart` invocations through `fvm` when the target project is
fvm-configured (has a `.fvmrc` file or `.fvm/` directory) and the `fvm` binary
is on `PATH`. Falls back to the bare executable otherwise.

## 0.10.18

Add `--path` option to `upcode fad upload` to override the default apk/ipa
location. Supports uploading aab bundles by passing a `.aab` path.

## 0.10.17

Add support for backend deadline parameter ([Reference](https://docs.cloud.google.com/endpoints/docs/openapi/openapi-extensions#deadline))

## 0.10.16+2

Fix breaking change: Add the [module] parameter back for the `upcode dart:format` and `upcode flutter:format` commands.

## 0.10.16+1

Fix breaking change: Split files when formating on windows(dart).

## 0.10.15

Ensure the most recent valid tag version is selected when parsing the tag versions.

## 0.10.14

Handle cases when the tag version cannot be parsed

## 0.10.13

Split files when formating on windows.

## 0.10.12

Only replace the first iteration of version.

## 0.10.11

Drop the use of legacy firebase database key.

## 0.10.10

Add option to send fcm notification using a json file that contains a
message. https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages#Message

## 0.10.9

Support Web only apps.

## 0.10.8

Add version for dart api.

## 0.10.7

Add `dart:format` and `dart:analyze` same as `flutter` command.
You can also pass a list of `module` to specify the folders you want to check.

## 0.10.6

Added a new optional 'api_dockerfile_dir'
that can be used to specify the Dockerfile's location for cases when it needs to be other that within the 'api_dir'.

## 0.10.5

* specify proto output directory with `protos_output_dir`

## 0.10.4

* fix to camel case when settings env

## 0.10.3

* fix reading wrong project id

## 0.10.2

* fix missing command

* ## 0.10.1

* fix save release notes

## 0.10.0

**Breaking change info:**

This deprecates `upcode flutter:fad` but it doesn't remove it yet. Make sure to update to `upcode fad upload`.

Updates:

* implement firebase app distribution in dart. This allows us not to install the node-js firebase-tools package.
* add `update fad deleteOldReleases` where you can delete old releases on firebase app distribution.
* update dependencies

## 0.10.1+beta

* fix wrong dependency on http

## 0.10.0+beta

**Breaking change info:**

This deprecates `upcode flutter:fad` but it doesn't remove it yet. Make sure to update to `upcode fad upload`.

Updates:

* implement firebase app distribution in dart. This allows us not to install the node-js firebase-tools package.
* add `update fad deleteOldReleases` where you can delete old releases on firebase app distribution.
* update dependencies

## 0.9.3

Reverts 0.9.1 from using the current fvm installation since it doesn't work with CI/CD.
A workaround can be found here https://github.com/kuhnroyal/flutter-fvm-config-action for GitHub Actions.

## 0.9.2

Fix gateway deployment.

## 0.9.1

Add support for using fvm to resolve dart or flutter commands for flutter only.

## 0.9.0

* convert the gcloud_build_image script to dart so we can run in on Windows also.
  (https://github.com/GoogleCloudPlatform/esp-v2/blob/master/docker/serverless/gcloud_build_image)
  **Breaking**
    * Since _gcloud_build_image_ can be removed and will not be used, if you previously had a custom _ESPv2_ARGS_ set
      inside the _gcloud_build_image_, you need to set it as an api config value with name _esp_args_ otherwise this
      will be the default:
      `^++^--cors_preset=basic++--cors_allow_headers="keep-alive,user-agent,cache-control,content-type,content-transfer-encoding,x-accept-content-transfer-encoding,x-accept-response-streaming,x-user-agent,x-grpc-web,grpc-timeout,DNT,X-Requested-With,If-Modified-Since,Range,Authorization,x-api-key"++--cors_expose_headers="grpc-status,grpc-message"`
* set runInShell true for Windows when running commands.
* remove unnecessary Idea folder.

## 0.8.13

Use dart format instead flutter format

## 0.8.12

Add support for Dart backends

## 0.8.11

Don't override the min instance on api deploy for the gateway

## 0.8.10

Fix previous update that would crash when trying to get the environment

## 0.8.8

Fixes a bug with version management when the database url was not correct

## 0.8.7

Get the realtime database url for versioning from the firebase management api

## 0.8.6

Exclude from formatting .gr and .config files

## 0.8.5

Update version env argument to be used as a valid build name by replacing "_" with "-"

## 0.8.4

Generate client stubs for node proto

## 0.8.3

Fix version set ignoring the env argument

## 0.8.2

Fix generator not finding the API Key

## 0.8.1

Fix google proto files not being included in generation

## 0.8.0

Add null-safety, let me know if you have any errors, and I'll make sure to fix them ass soon as possible

## 0.7.1

Scrub google fields out of the api descriptor.
See https://gist.github.com/kristiandrucker/d3a7c7b8e64f55ad4ebfa3634a96d5fe
and https://issuetracker.google.com/issues/210014211

## 0.7.0

* Breaking Change: require `grpc_tools_node_protoc_plugin` and `grpc-tools` be globally installed using `npm install -g`

## 0.6.6

* update proto js definition from grpc to grpc-js

## 0.6.5

* skip version in api deploy if we can't read it

## 0.6.4

* allow the use of environment without firebase

## 0.6.3

* respect the deployService flag when deploying all on api

## 0.6.2

* allow setting min instances for cloud run

## 0.6.1

* allow the ability to add multiple images for the api
* allow specifying a list of Cloud SQL instances that you want to link to all images or to just one. If the
  `cloudsql_instances` is use at the image level the top level values will be ignored

```yaml
api:
  cloudsql_instances:
    - project:region:name
  images:
    - name:
      selector: "*"
    - name: name
      selector: domain.v1.Service.*
      cloudsql_instances:
        - project:region:name01
```

## 0.6.0+1

* throw is we are not able to read the version

## 0.6.0+3

* add analysis options
* update dependencies

## 0.6.0

* allow the user to specify a version incrementation algorithm

## 0.5.1+2

* add cmd to protoc ts tools

## 0.5.1+1

* add cmd to protoc ts compiler

## 0.5.1

* use os path separator on upcode.yaml paths

## 0.5.0

* BREAKING CHANGE: don't increment the version when deploying api, just
  read the current one

## 0.4.7

* allow setting the version back to cloud with version set

## 0.4.6

* allow setting the version type

## 0.4.5+1

* print version when reading it

## 0.4.5

* remove yarn dependency

## 0.4.4

* read database url from google-services.json

## 0.4.3

* don't generate the import files anymore

## 0.4.2

* use an absolute path for modules when iterating over them

## 0.4.1

* update fad to accept a firebase token

## 0.4.0

* add api implementation

## 0.3.6

* add release notes for firebase app distribution

## 0.3.5+1

* normalize flutter module dirname

## 0.3.5

* add option to set a specific version

## 0.3.4

* add support for setting the env in the version name

## 0.3.3

* remove env name restriction

## 0.3.2

* add protobuf generation

## 0.3.1+1

* remove debug flag from firebase app distribution

## 0.3.1

* override configurations base on envs

## 0.3.0

* **Breaking** the way the version is saved in FRDB has changed, now the
  version is saved under the same name as the flutter module
* add ability to specify flutter and private folder when
  invoking any command

## 0.2.5

* add coverage to tests

## 0.2.4

* use system separator

## 0.2.3+1

* add different app id for android and ios
* the environment command doesn't need env anymore, this command will be split up into config and env

## 0.2.3

* add different app id for android and ios
* the environment command doesn't need env anymore, this command will be split up into config and env

## 0.2.2

* pub get before testing

## 0.2.1

* exclude chopper from formatting

## 0.2.0

* remove `formatted_modules` and `analyzed_modules`
* add `formatted`, `analyzed`, `tested` and `generated`

## 0.1.5

* add config based on environment

## 0.1.4+1

* fix `formatted_modules`

## 0.1.4

* add `formatted_modules` and `analyzed_modules`

## 0.1.3

* pub get before running the generator

## 0.1.2

* add `generated_modules`

## 0.1.1+1

* update readme

## 0.1.1

* add executable

## 0.1.0

* initial release