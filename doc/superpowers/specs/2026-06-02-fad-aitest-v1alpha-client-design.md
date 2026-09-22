# Generate a typed v1alpha client for `fad ai-test`

**Date:** 2026-06-02
**Status:** Approved (Approach A)

## Problem

`upcode fad ai-test` drives the Firebase App Distribution **App Testing**
API by hand with raw `http` calls (`_createReleaseTest`, `_awaitResult` in
`lib/src/commands/flutter/firebase_app_distribution.dart`). It builds JSON
maps by hand, hard-codes the `v1alpha` host, and reads untyped response maps.
This is brittle: field names are stringly-typed and any schema drift is
silent.

The API lives at `firebaseappdistribution` **v1alpha**, which the published
`package:googleapis` (which only ships `firebaseappdistribution/v1`) does not
cover — hence the hand-rolled calls.

## Goal

Transform the v1alpha Google Discovery document into a typed Dart client and
use it to replace the two raw-http tests calls in `ai-test`. Auth behavior and
the raw media upload are unchanged.

## Feasibility (verified)

- The v1alpha discovery doc is published
  (`https://firebaseappdistribution.googleapis.com/$discovery/rest?version=v1alpha`,
  HTTP 200, ~94 KB) and describes the full surface `ai-test` uses:
  - methods `firebaseappdistribution.projects.apps.releases.tests.create`
    and `...tests.get`;
  - schemas `ReleaseTest`, `AiStep`, and fields `aiInstructions`,
    `loginCredential`, `deviceExecutions`, `successCriteria`, `resultsBucket`.
- The generator's git HEAD
  (`google/googleapis.dart` → `discoveryapis_generator`, `1.1.0-wip`,
  `sdk: ^3.9.0`) runs on the local Dart SDK (3.11.x). Published generator
  versions cap at `<3.0.0`, so the git ref is required.
- Generated googleapis-style clients depend on
  `package:_discoveryapis_commons` (1.0.7, Dart 3) and `package:http`
  (already a dependency).

## Approach

Vendor a generated v1alpha client (chosen over hand-writing a minimal model,
which would drift from the schema, and over a runtime `upcode discovery`
command, which is out of scope).

## Components

1. **Pinned input** — `tool/discovery/firebaseappdistribution_v1alpha.json`,
   the discovery doc committed so generation is reproducible.
2. **Regeneration script** — `tool/generate_clients.sh`:
   - `dart pub global activate --source git
     https://github.com/google/googleapis.dart --git-path discoveryapis_generator`
   - run the generator on the pinned JSON;
   - copy the emitted `v1alpha.dart` to the vendored location below.
   This is a rare dev task, not wired into any `upcode` command. The script
   sets `set -euo pipefail` and is shellcheck-clean.
3. **Vendored client** —
   `lib/src/generated/firebaseappdistribution/v1alpha.dart`, the full
   generated client (only the `tests` methods are used). Its
   `package:_discoveryapis_commons/...` and `package:http/http.dart` imports
   are used unchanged.
4. **New dependency** — `_discoveryapis_commons: ^1.0.7` added as a direct
   dependency (currently transitive via `googleapis`).

## Data flow / rewiring in `ai-test`

- A pure helper `_buildReleaseTest(test, devices, loginCredential,
  resultsBucket)` maps the YAML-derived maps into the generated `ReleaseTest`,
  `AiInstructions`, and `AiStep` model objects.
- `_createReleaseTest` calls
  `client.projects.apps.releases.tests.create(releaseTest, parent)`, keeping
  the existing retry: catch `DetailedApiRequestError` with `status >= 500` and
  back off (1s/2s/4s/8s, up to 5 attempts).
- `_awaitResult` calls `client.projects.apps.releases.tests.get(name)` and
  reads typed `deviceExecutions[].state` plus failure/inconclusive reasons.
- `_testClient` (the user **or** service-account client selected in `run()`)
  is passed as the generated client's `http.Client`. Auth is unchanged.
- Removed: the `_host` constant, manual `jsonEncode`/redaction, and the raw
  `http` POST/GET for tests. Kept: `_upload` (raw media upload) and the
  user/service-account client selection.

## Error handling

The generated client throws `DetailedApiRequestError` on non-2xx. Retry when
`status >= 500`; otherwise rethrow with the operation context. Login
credentials are not logged because the request is a typed model rather than a
raw map (this removes the need for the previous manual redaction).

## Testing

- `_buildReleaseTest` is pure and unit-tested (TDD): step fields
  (`goal`/`assertion`/`hint`/`successCriteria`), login-credential inclusion,
  device mapping, and `resultsBucket` inclusion/omission.
- The network calls (`create`/`get`) remain manually verified, consistent with
  the rest of this command and prior changes in this package.

## Out of scope

- Replacing the raw media upload (`_upload`) in `ai-test` or `fad upload`.
- A runtime `upcode discovery` command.
- Generating clients for any other API or version.
