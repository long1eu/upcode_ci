# Route `flutter` / `dart` through fvm when a project is fvm-configured

**Date:** 2026-05-16
**Status:** Approved

## Problem

The `upcode` CLI invokes the `flutter` and `dart` executables directly. When a
target Flutter project pins its SDK with [fvm](https://fvm.app), running the
bare `flutter`/`dart` from `PATH` uses the global SDK instead of the pinned one,
which can produce inconsistent build, analysis, and codegen results.

`upcode` should run `fvm flutter` / `fvm dart` when the project it operates on
is fvm-configured.

## Goal

When a command's working directory belongs to an fvm-configured project and the
`fvm` binary is available, route `flutter` and `dart` invocations through `fvm`.
Otherwise, behave exactly as today.

## Affected call sites

All go through `runCommand` in `lib/src/commands/command.dart:380`:

- `flutter` — `flutter:test`, `flutter:analyze`, `flutter:buildrunner`
- `dart` — `flutter:i18n`, `flutter:format`, `flutter:version`, `dart:analyze`,
  `dart:format`

`fastlane` and other executables are out of scope.

## Design

### Approach

Centralize the resolution in `runCommand`. It already receives both the
`executable` name and the `workingDirectory`, so it is the single chokepoint
that cannot miss a call site. No changes are needed in the individual command
files.

### Detection

Two pure checks, both cached:

- **`_isFvmConfigured(dir)`** — walk up from `dir` to the filesystem root;
  return `true` if any ancestor contains a `.fvmrc` file or a `.fvm/`
  directory. Walking up handles both layouts: the module *is* the Flutter
  project root, or it is a sub-package inside an fvm-configured repo
  (`modules` / `generatedModules` may point at separate sub-packages).
  Results are cached per directory to avoid repeated filesystem walks.

- **`_fvmOnPath()`** — return whether the `fvm` binary is resolvable on
  `PATH`. The boolean is cached for the process lifetime.

### Resolution

In `runCommand`, before `Process.start`:

```
if executable in {flutter, dart}
   and _fvmOnPath()
   and _isFvmConfigured(workingDirectory):
       arguments  = [executable, ...arguments]
       executable = 'fvm'
```

Otherwise `executable` and `arguments` are unchanged.

### Fallback behavior

If a project is fvm-configured but the `fvm` binary is not on `PATH`, fall back
to the bare `flutter`/`dart` executable. This matches the intent: use fvm *when
available*, never hard-fail because of it.

### Observability

The existing `RUNNING …` / `ELAPSED TIME` log lines derive their description
from `executable` + `arguments`. After resolution they naturally print
`fvm flutter pub get`, making the fvm routing visible without extra logging.

## Testing

The repository currently has no `test/` directory.

- `_isFvmConfigured` is pure and walk-based — add focused unit tests under a new
  `test/` directory covering: an fvm-configured project root, a sub-package
  nested inside an fvm-configured repo, and an unconfigured directory tree.
  Cover both the `.fvmrc` file and the `.fvm/` directory forms.
- `runCommand` spawns real processes, so it is out of scope for unit tests;
  verification of the end-to-end routing is manual.

## Out of scope

- Routing `fastlane` or any executable other than `flutter`/`dart`.
- An opt-out flag or upcode config setting — detection is automatic.
- Installing or managing fvm itself.
