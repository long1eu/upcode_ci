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

# The `files` subcommand requires the output dir to live inside a package.
mkdir -p "$WORK/output"
cat >"$WORK/output/pubspec.yaml" <<'PUBSPEC'
name: generated_clients
environment:
  sdk: '>=3.0.0 <4.0.0'
PUBSPEC

fvm dart pub global run discoveryapis_generator:generate files \
  --input-dir="$WORK/input" --output-dir="$WORK/output"

DEST="$ROOT/lib/src/generated/firebaseappdistribution"
mkdir -p "$DEST"
GENERATED="$(find "$WORK/output" -name 'firebaseappdistribution.dart' | head -1)"
if [[ -z "$GENERATED" ]]; then
  echo "Could not find generated firebaseappdistribution.dart under $WORK/output" >&2
  find "$WORK/output" -name '*.dart' >&2
  exit 1
fi
cp "$GENERATED" "$DEST/v1alpha.dart"
echo "Vendored: $DEST/v1alpha.dart"
