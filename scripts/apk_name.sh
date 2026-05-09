#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PUBSPEC_FILE=${PUBSPEC_FILE:-"$ROOT_DIR/pubspec.yaml"}
APP_SLUG=${APP_SLUG:-voice-notes}
BUILD_CHANNEL=${BUILD_CHANNEL:-test}
APK_EXT=${APK_EXT:-apk}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

version_line=$(sed -n 's/^version:[[:space:]]*//p' "$PUBSPEC_FILE" | head -n 1)
[ -n "$version_line" ] || fail "Could not find 'version:' in $PUBSPEC_FILE"

default_build_name=$version_line
default_build_number=0

case "$version_line" in
  *+*)
    default_build_name=${version_line%%+*}
    default_build_number=${version_line#*+}
    ;;
esac

BUILD_NAME=${BUILD_NAME:-$default_build_name}
BUILD_NUMBER=${BUILD_NUMBER:-$default_build_number}
APK_TIMESTAMP=${APK_TIMESTAMP:-$(date +"%Y-%m-%d_%H-%M-%S")}

build_id=${TEST_ID-}
if [ -z "$build_id" ]; then
  git_sha=${GIT_SHA_SHORT-}

  if [ -z "$git_sha" ]; then
    git_sha=$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || true)
  fi

  if [ -n "$git_sha" ]; then
    build_id="g$git_sha"
  fi
fi

file_name="${APP_SLUG}-${BUILD_CHANNEL}-v${BUILD_NAME}-b${BUILD_NUMBER}-${APK_TIMESTAMP}"

if [ -n "$build_id" ]; then
  file_name="${file_name}-${build_id}"
fi

printf '%s.%s\n' "$file_name" "$APK_EXT"
