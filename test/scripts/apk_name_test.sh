#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT_PATH="$ROOT_DIR/scripts/apk_name.sh"

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

TMP_PUBSPEC=$(mktemp)
trap 'rm -f "$TMP_PUBSPEC"' EXIT

cat >"$TMP_PUBSPEC" <<'EOF'
name: voice_notes
version: 2.7.3+42
EOF

OUTPUT=$(
  PUBSPEC_FILE="$TMP_PUBSPEC" \
  APK_TIMESTAMP="2026-05-09_14-35-12" \
  GIT_SHA_SHORT="d491fc7" \
  "$SCRIPT_PATH"
)

EXPECTED="voice-notes-test-v2.7.3-b42-2026-05-09_14-35-12-gd491fc7.apk"

[ "$OUTPUT" = "$EXPECTED" ] || fail "Expected '$EXPECTED', got '$OUTPUT'"

printf 'apk_name_test: ok\n'
