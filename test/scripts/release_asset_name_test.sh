#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT_PATH="$ROOT_DIR/scripts/release_asset_name.sh"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

OUTPUT=$(
  BUILD_NAME="2.7.3" \
  BUILD_NUMBER="42" \
  "$SCRIPT_PATH"
)

EXPECTED="voice-notes-android-v2.7.3-b42.apk"

[ "$OUTPUT" = "$EXPECTED" ] || fail "Expected '$EXPECTED', got '$OUTPUT'"

OUTPUT_AAB=$(
  BUILD_NAME="2.7.3" \
  BUILD_NUMBER="42" \
  ASSET_EXT="aab" \
  "$SCRIPT_PATH"
)

EXPECTED_AAB="voice-notes-android-v2.7.3-b42.aab"

[ "$OUTPUT_AAB" = "$EXPECTED_AAB" ] || fail "Expected '$EXPECTED_AAB', got '$OUTPUT_AAB'"

if BUILD_NUMBER="42" "$SCRIPT_PATH" >/dev/null 2>&1; then
  fail "Expected missing BUILD_NAME to fail"
fi

printf 'release_asset_name_test: ok\n'
