#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PUBSPEC_FILE=${PUBSPEC_FILE:-"$ROOT_DIR/pubspec.yaml"}
RELEASE_TAG=${1:-${RELEASE_TAG:-}}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -n "$RELEASE_TAG" ] || fail "Release tag is required"

printf '%s\n' "$RELEASE_TAG" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+(\.[0-9A-Za-z]+)*)?$' ||
  fail "Release tag must match vX.Y.Z or vX.Y.Z-prerelease format"

version_line=$(sed -n 's/^version:[[:space:]]*//p' "$PUBSPEC_FILE" | head -n 1)
[ -n "$version_line" ] || fail "Could not find 'version:' in $PUBSPEC_FILE"

build_name=$version_line
build_number=0

case "$version_line" in
  *+*)
    build_name=${version_line%%+*}
    build_number=${version_line#*+}
    ;;
esac

expected_tag="v$build_name"
[ "$RELEASE_TAG" = "$expected_tag" ] || fail "Expected release tag '$expected_tag', got '$RELEASE_TAG'"

printf 'release_tag=%s\n' "$RELEASE_TAG"
printf 'build_name=%s\n' "$build_name"
printf 'build_number=%s\n' "$build_number"
