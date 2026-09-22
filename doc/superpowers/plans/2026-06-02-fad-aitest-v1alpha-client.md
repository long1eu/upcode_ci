# Typed v1alpha client for `fad ai-test` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the two raw-`http` App Testing calls in `fad ai-test` (`_createReleaseTest`, `_awaitResult`) with a typed client generated from the `firebaseappdistribution` v1alpha Google Discovery document.

**Architecture:** Pin the v1alpha discovery doc in the repo, generate a googleapis-style Dart client with the git-HEAD `discoveryapis_generator`, vendor the generated file, and call its `projects.apps.releases.tests.create`/`.get` from `ai-test`. The generated client is imported with a prefix because it defines `FirebaseAppDistributionApi`, which collides with the `googleapis/.../v1.dart` import already used in the file.

**Tech Stack:** Dart 3.11, `discoveryapis_generator` (git HEAD, `1.1.0-wip`, run via `fvm dart`), `package:_discoveryapis_commons`, `package:http`, `package:test`.

---

## File structure

- Create `tool/discovery/firebaseappdistribution_v1alpha.json` — pinned discovery input.
- Create `tool/generate_clients.sh` — regeneration recipe (dev-only, not an `upcode` command).
- Create `lib/src/generated/firebaseappdistribution/v1alpha.dart` — vendored generated client (produced by the script).
- Modify `pubspec.yaml` — add `_discoveryapis_commons` dependency; bump version; add `dev_dependencies` note for the generator (git, not a pubspec entry).
- Modify `lib/src/commands/flutter/firebase_app_distribution.dart` — rewire `ai-test`.
- Create `test/fad_aitest_test.dart` — unit tests for the pure mapping helper.
- Modify `CHANGELOG.md`.

Generated-client mechanic not run firsthand (the generator activation requires approval at execution time): Task 2's copy step locates the emitted file with `find` so it tolerates the generator's exact output path.

---

### Task 1: Pin the discovery document and add the runtime dependency

**Files:**
- Create: `tool/discovery/firebaseappdistribution_v1alpha.json`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Download the pinned discovery doc**

Run:
```bash
mkdir -p tool/discovery
curl -fsS "https://firebaseappdistribution.googleapis.com/\$discovery/rest?version=v1alpha" \
  -o tool/discovery/firebaseappdistribution_v1alpha.json
```
Expected: file created, ~94 KB. Verify it is the right API:
```bash
grep -c '"firebaseappdistribution.projects.apps.releases.tests.create"' tool/discovery/firebaseappdistribution_v1alpha.json
```
Expected: `1`.

- [ ] **Step 2: Add `_discoveryapis_commons` as a direct dependency**

In `pubspec.yaml`, under `dependencies:`, add the line (alphabetical neighbours shown for placement):
```yaml
  collection: ^1.18.0
  _discoveryapis_commons: ^1.0.7
```

- [ ] **Step 3: Resolve dependencies**

Run: `fvm dart pub get`
Expected: resolves with `_discoveryapis_commons 1.0.7` (or compatible) as a direct dep; no errors.

- [ ] **Step 4: Commit**

```bash
git add tool/discovery/firebaseappdistribution_v1alpha.json pubspec.yaml pubspec.lock
git commit -m "fad ai-test: pin v1alpha discovery doc and add _discoveryapis_commons"
```

---

### Task 2: Generate and vendor the v1alpha client

**Files:**
- Create: `tool/generate_clients.sh`
- Create: `lib/src/generated/firebaseappdistribution/v1alpha.dart`

- [ ] **Step 1: Write the regeneration script**

Create `tool/generate_clients.sh`:
```bash
#!/usr/bin/env bash
# Regenerates vendored Google API clients from pinned discovery docs.
# Dev-only; run manually when an API's discovery doc changes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The generator's published versions cap at Dart <3.0.0; the git HEAD
# (1.1.0-wip) supports Dart 3.9+, so it is run from git.
fvm dart pub global activate --source git \
  https://github.com/google/googleapis.dart --git-path discoveryapis_generator

mkdir -p "$WORK/input"
# Input files must be named <api>__<version>.json.
cp "$ROOT/tool/discovery/firebaseappdistribution_v1alpha.json" \
  "$WORK/input/firebaseappdistribution__v1alpha.json"

fvm dart pub global run discoveryapis_generator:generate generate \
  --input-dir="$WORK/input" --output-dir="$WORK/output"

DEST="$ROOT/lib/src/generated/firebaseappdistribution"
mkdir -p "$DEST"
GENERATED="$(find "$WORK/output" -path '*firebaseappdistribution/v1alpha.dart' | head -1)"
if [[ -z "$GENERATED" ]]; then
  echo "Could not find generated v1alpha.dart under $WORK/output" >&2
  find "$WORK/output" -name '*.dart' >&2
  exit 1
fi
cp "$GENERATED" "$DEST/v1alpha.dart"
echo "Vendored: $DEST/v1alpha.dart"
```

- [ ] **Step 2: Lint the script**

Run: `shellcheck tool/generate_clients.sh && shfmt -i 2 -d tool/generate_clients.sh`
Expected: no findings (fix any reported issues).

- [ ] **Step 3: Make it executable and run it**

Run:
```bash
chmod +x tool/generate_clients.sh
./tool/generate_clients.sh
```
Expected: prints `Vendored: .../lib/src/generated/firebaseappdistribution/v1alpha.dart`.
Note: activating the generator from git requires approval — approve when prompted. If the generator CLI flags differ for the installed HEAD, run `fvm dart pub global run discoveryapis_generator:generate --help` and adjust the `generate` invocation; the `find` step already tolerates output-path differences.

- [ ] **Step 4: Verify the vendored client analyzes and exposes the expected API**

Run: `fvm dart analyze lib/src/generated/firebaseappdistribution/v1alpha.dart`
Expected: `No issues found!`

Run:
```bash
grep -c 'class FirebaseAppDistributionApi' lib/src/generated/firebaseappdistribution/v1alpha.dart
grep -c 'class GoogleFirebaseAppdistroV1alphaReleaseTest' lib/src/generated/firebaseappdistribution/v1alpha.dart
grep -c 'class GoogleFirebaseAppdistroV1alphaAiStep' lib/src/generated/firebaseappdistribution/v1alpha.dart
```
Expected: each prints `1`.

- [ ] **Step 5: Commit**

```bash
git add tool/generate_clients.sh lib/src/generated/firebaseappdistribution/v1alpha.dart
git commit -m "fad ai-test: vendor generated firebaseappdistribution v1alpha client"
```

---

### Task 3: Add the pure mapping helper with a failing test

This task introduces `buildReleaseTest`, a pure function mapping parsed inputs into the generated `GoogleFirebaseAppdistroV1alphaReleaseTest`. It is the only unit-testable seam; the network calls in Task 4 are verified manually.

**Files:**
- Modify: `lib/src/commands/flutter/firebase_app_distribution.dart`
- Test: `test/fad_aitest_test.dart`

- [ ] **Step 1: Add the prefixed import**

In `lib/src/commands/flutter/firebase_app_distribution.dart`, add to the import block (keep imports alphabetised after the existing `package:` imports, before `package:upcode_ci/...`):
```dart
import 'package:upcode_ci/src/generated/firebaseappdistribution/v1alpha.dart' as fad_v1alpha;
```

- [ ] **Step 2: Write the failing test**

Create `test/fad_aitest_test.dart`:
```dart
import 'package:test/test.dart';
import 'package:upcode_ci/src/commands/flutter/firebase_app_distribution.dart';
import 'package:upcode_ci/src/generated/firebaseappdistribution/v1alpha.dart' as fad_v1alpha;

void main() {
  group('buildReleaseTest', () {
    final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices =
        <fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice>[
      fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice(
        model: 'MediumPhone.arm',
        version: '34',
        locale: 'en',
        orientation: 'portrait',
      ),
    ];

    test('maps steps, device executions, display name and results bucket', () {
      final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest result = buildReleaseTest(
        displayName: 'smoke',
        steps: <fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep>[
          fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep(goal: 'open app', successCriteria: 'home shown'),
        ],
        devices: devices,
        loginCredential: null,
        resultsBucket: 'gs://bucket',
      );

      expect(result.displayName, 'smoke');
      expect(result.resultsBucket, 'gs://bucket');
      expect(result.aiInstructions!.steps!.single.goal, 'open app');
      expect(result.deviceExecutions!.single.device!.model, 'MediumPhone.arm');
      expect(result.loginCredential, isNull);
    });

    test('omits results bucket and includes login credential when provided', () {
      final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest result = buildReleaseTest(
        displayName: null,
        steps: <fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep>[],
        devices: devices,
        loginCredential: fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential(username: 'a@b.c'),
        resultsBucket: null,
      );

      expect(result.displayName, isNull);
      expect(result.resultsBucket, isNull);
      expect(result.loginCredential!.username, 'a@b.c');
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `fvm dart test test/fad_aitest_test.dart`
Expected: FAIL — `buildReleaseTest` is undefined.

- [ ] **Step 4: Add the minimal implementation**

In `lib/src/commands/flutter/firebase_app_distribution.dart`, add this **top-level** function (after the imports, before `class FadCommand`):
```dart
/// Builds a v1alpha [fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest]
/// from already-parsed inputs. Pure: no I/O, so it is unit-tested directly.
fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest buildReleaseTest({
  required String? displayName,
  required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps,
  required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices,
  required fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential,
  required String? resultsBucket,
}) {
  return fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest(
    displayName: displayName,
    resultsBucket: resultsBucket,
    loginCredential: loginCredential,
    aiInstructions: fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiInstructions(steps: steps),
    deviceExecutions: devices
        .map((fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice device) =>
            fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution(device: device))
        .toList(),
  );
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `fvm dart test test/fad_aitest_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/src/commands/flutter/firebase_app_distribution.dart test/fad_aitest_test.dart
git commit -m "fad ai-test: add buildReleaseTest mapping helper"
```

---

### Task 4: Rewire `_createReleaseTest` and `_awaitResult` onto the typed client

Replaces the raw-`http` tests calls. The parsing helpers `_device`, `_loginCredential`, and the step extraction in `_readTests` now produce typed model objects instead of maps, feeding `buildReleaseTest`.

**Files:**
- Modify: `lib/src/commands/flutter/firebase_app_distribution.dart`

- [ ] **Step 1: Convert `_device` to return a typed device**

Replace the `_device` method (currently returns `Map<String, dynamic>`):
```dart
  fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice _device(String spec) {
    final Map<String, String> parts = <String, String>{
      for (final String pair in spec.split(',')) pair.split('=').first.trim(): pair.split('=').last.trim(),
    };
    return fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice(
      model: parts['model'],
      version: parts['version'],
      locale: parts['locale'] ?? 'en',
      orientation: parts['orientation'] ?? 'portrait',
    );
  }
```

- [ ] **Step 2: Convert `_loginCredential` to return a typed credential**

Replace the `_loginCredential` method:
```dart
  fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? _loginCredential() {
    String? username = argResults!['username'] as String?;
    String? password = argResults!['password'] as String?;
    if (argResults!.wasParsed('password-file')) {
      password = File(argResults!['password-file'] as String).readAsStringSync().trim();
    }
    if (argResults!.wasParsed('credentials')) {
      final Map<String, dynamic> credentials =
          jsonDecode(File(argResults!['credentials'] as String).readAsStringSync()) as Map<String, dynamic>;
      username ??= credentials['TEST_EMAIL'] as String?;
      password ??= credentials['TEST_PASSWORD'] as String?;
    }
    if (username == null && password == null) {
      return null;
    }
    return fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential(username: username, password: password);
  }
```

- [ ] **Step 3: Convert `_readTests` to return display name + typed steps**

Replace `_readTests` (and its return type). Each entry is a record of the display name and the typed steps:
```dart
  /// Reads the YAML into (displayName, steps) records. Accepts both
  /// `successCriteria` and `finalScreenAssertion` for the success text.
  List<({String? displayName, List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps})> _readTests() {
    final dynamic doc = loadYaml(File(argResults!['tests'] as String).readAsStringSync());
    final List<dynamic> tests = (doc['tests'] as List<dynamic>?) ?? <dynamic>[];
    return tests.map((dynamic test) {
      final List<dynamic> steps = (test['steps'] as List<dynamic>?) ?? <dynamic>[];
      return (
        displayName: (test['displayName'] ?? test['name'])?.toString(),
        steps: steps.map((dynamic step) {
          final dynamic success = step['successCriteria'] ?? step['finalScreenAssertion'];
          return fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep(
            goal: step['goal']?.toString(),
            assertion: step['assertion']?.toString(),
            hint: step['hint']?.toString(),
            successCriteria: success?.toString(),
          );
        }).toList(),
      );
    }).toList();
  }
```

- [ ] **Step 4: Replace `_createReleaseTest` with the typed call (keeping retry)**

Replace the entire `_createReleaseTest` method:
```dart
  /// Creates one release test via the generated v1alpha client. Retries on
  /// 5xx with exponential backoff (1s/2s/4s/8s, up to 5 attempts).
  Future<String> _createReleaseTest({
    required String releaseName,
    required String? displayName,
    required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps,
    required List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices,
    required fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential,
  }) async {
    final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest request = buildReleaseTest(
      displayName: displayName,
      steps: steps,
      devices: devices,
      loginCredential: loginCredential,
      resultsBucket: argResults!['results-bucket'] as String?,
    );
    final fad_v1alpha.FirebaseAppDistributionApi api = fad_v1alpha.FirebaseAppDistributionApi(_testClient);

    const int maxAttempts = 5;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest created =
            await api.projects.apps.releases.tests.create(request, releaseName);
        return created.name!;
      } on commons.DetailedApiRequestError catch (e) {
        if ((e.status ?? 0) < 500 || attempt == maxAttempts) {
          rethrow;
        }
        final Duration backoff = Duration(seconds: 1 << (attempt - 1));
        stderr.writeln('  createReleaseTest got ${e.status}, retrying in '
            '${backoff.inSeconds}s (attempt $attempt/$maxAttempts)');
        await Future<void>.delayed(backoff);
      }
    }
    throw StateError('unreachable');
  }
```

- [ ] **Step 5: Add the `commons` import used by the retry**

In the import block add:
```dart
import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
```

- [ ] **Step 6: Replace `_awaitResult` with the typed poll**

Replace the body that fetches and parses JSON. The method signature stays `Future<bool> _awaitResult(String testName, Duration timeout)`:
```dart
  /// Polls a release test until every device execution is terminal. Returns
  /// whether they all passed.
  Future<bool> _awaitResult(String testName, Duration timeout) async {
    final fad_v1alpha.FirebaseAppDistributionApi api = fad_v1alpha.FirebaseAppDistributionApi(_testClient);
    final DateTime deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final fad_v1alpha.GoogleFirebaseAppdistroV1alphaReleaseTest test =
          await api.projects.apps.releases.tests.get(testName);
      final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution> executions =
          test.deviceExecutions ?? <fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution>[];

      final bool done = executions.isNotEmpty &&
          executions.every((fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution e) =>
              (e.state ?? 'IN_PROGRESS') != 'IN_PROGRESS');
      if (done) {
        bool passed = true;
        for (final fad_v1alpha.GoogleFirebaseAppdistroV1alphaDeviceExecution execution in executions) {
          final String state = execution.state ?? 'INCONCLUSIVE';
          if (state != 'PASSED') {
            passed = false;
            final String reason = execution.failedReason ?? execution.inconclusiveReason ?? '';
            stdout.writeln('  $red$state on ${execution.device?.model}: $reason$reset');
          }
        }
        return passed;
      }
      await Future<void>.delayed(const Duration(seconds: 10));
    }
    stdout.writeln('  ${red}Timed out waiting for $testName$reset');
    return false;
  }
```

- [ ] **Step 7: Update the `run()` call site to pass typed values**

In `run()`, the block that builds `devices`, `tests`, and starts each test changes. Replace the relevant lines:
```dart
    final List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaTestDevice> devices =
        (argResults!['device'] as List<String>).map(_device).toList();
    final fad_v1alpha.GoogleFirebaseAppdistroV1alphaLoginCredential? loginCredential = _loginCredential();
    final List<({String? displayName, List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps})> tests =
        _readTests();
    final Duration timeout = Duration(minutes: int.tryParse(argResults!['timeout'] as String) ?? 15);

    final Map<String, String> started = <String, String>{};
    await execute(
      () async {
        for (final ({String? displayName, List<fad_v1alpha.GoogleFirebaseAppdistroV1alphaAiStep> steps}) test
            in tests) {
          final String testName = await _createReleaseTest(
            releaseName: releaseName,
            displayName: test.displayName,
            steps: test.steps,
            devices: devices,
            loginCredential: loginCredential,
          );
          started[test.displayName ?? testName] = testName;
        }
      },
      'Start ${tests.length} AI test(s)',
    );
```

- [ ] **Step 8: Remove the now-dead `_host` constant and unused imports**

Delete the `static const String _host = ...;` field. Remove `import 'dart:convert';` only if no longer referenced — check first:
```bash
grep -nE "jsonDecode|jsonEncode|Utf8Decoder|JsonDecoder|utf8|_host|http\." lib/src/commands/flutter/firebase_app_distribution.dart
```
Keep `dart:convert` and `package:http` if `_upload`/`_loginCredential` still use them (`jsonDecode` is still used by `_loginCredential`; `_upload` uses `Utf8Decoder`/`JsonDecoder` and raw `HttpClient`). Remove only genuinely unused imports.

- [ ] **Step 9: Analyze**

Run: `fvm dart analyze lib/src/commands/flutter/firebase_app_distribution.dart`
Expected: `No issues found!` (fix any unused-import or type warnings).

- [ ] **Step 10: Run the full test suite**

Run: `fvm dart test`
Expected: all tests pass (the existing `test/fvm_test.dart` plus `test/fad_aitest_test.dart`).

- [ ] **Step 11: Commit**

```bash
git add lib/src/commands/flutter/firebase_app_distribution.dart
git commit -m "fad ai-test: drive App Testing API via generated v1alpha client"
```

---

### Task 5: Version bump and changelog

**Files:**
- Modify: `pubspec.yaml`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Bump the version**

In `pubspec.yaml`, change `version:` to the next patch (e.g. `0.10.30` if current is `0.10.29`; confirm the current value first with `grep '^version:' pubspec.yaml`).

- [ ] **Step 2: Add a changelog entry**

Prepend to `CHANGELOG.md` (use the version chosen in Step 1):
```markdown
## 0.10.30

`upcode fad ai-test`: drive the App Testing release-tests API through a typed
client generated from the firebaseappdistribution v1alpha discovery document,
replacing the hand-rolled http calls. Adds the pinned discovery doc and a
`tool/generate_clients.sh` regeneration script.

```

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml CHANGELOG.md
git commit -m "Release: typed v1alpha client for fad ai-test"
```

---

## Verification checklist (run before opening a PR)

- [ ] `fvm dart analyze` is clean across the package.
- [ ] `fvm dart test` passes.
- [ ] `grep -n "_host\|firebaseappdistribution.googleapis.com/v1alpha" lib/src/commands/flutter/firebase_app_distribution.dart` returns nothing (raw v1alpha host removed).
- [ ] The raw media upload `_upload` and the user/service-account client selection are unchanged.
- [ ] A real `ai-test` run against a test project is manually verified (network behavior is not unit-tested).
