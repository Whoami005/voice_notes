#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
SCRIPT_PATH="$ROOT_DIR/scripts/validate_release_tag.sh"

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

OUTPUT=$(PUBSPEC_FILE="$TMP_PUBSPEC" "$SCRIPT_PATH" "v2.7.3")

EXPECTED=$(cat <<'EOF'
release_tag=v2.7.3
build_name=2.7.3
build_number=42
EOF
)

[ "$OUTPUT" = "$EXPECTED" ] || fail "Expected '$EXPECTED', got '$OUTPUT'"

cat >"$TMP_PUBSPEC" <<'EOF'
name: voice_notes
version: 2.7.3-rc.1+42
EOF

OUTPUT_PRERELEASE=$(PUBSPEC_FILE="$TMP_PUBSPEC" "$SCRIPT_PATH" "v2.7.3-rc.1")

EXPECTED_PRERELEASE=$(cat <<'EOF'
release_tag=v2.7.3-rc.1
build_name=2.7.3-rc.1
build_number=42
EOF
)

[ "$OUTPUT_PRERELEASE" = "$EXPECTED_PRERELEASE" ] || fail "Expected '$EXPECTED_PRERELEASE', got '$OUTPUT_PRERELEASE'"

if PUBSPEC_FILE="$TMP_PUBSPEC" "$SCRIPT_PATH" "v2.7.4" >/dev/null 2>&1; then
  fail "Expected mismatched tag validation to fail"
fi

INVALID_TAG_ERROR=$(
  PUBSPEC_FILE="$TMP_PUBSPEC" "$SCRIPT_PATH" "v2.7.3-rc.1+42" 2>&1 >/dev/null || true
)

EXPECTED_INVALID_TAG_ERROR="Release tag must match vX.Y.Z or vX.Y.Z-prerelease format"

[ "$INVALID_TAG_ERROR" = "$EXPECTED_INVALID_TAG_ERROR" ] || fail "Expected '$EXPECTED_INVALID_TAG_ERROR', got '$INVALID_TAG_ERROR'"

printf 'validate_release_tag_test: ok\n'
