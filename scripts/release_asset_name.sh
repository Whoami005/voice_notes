#!/bin/sh
set -eu

APP_SLUG=${APP_SLUG:-voice-notes}
ASSET_KIND=${ASSET_KIND:-android}
ASSET_EXT=${ASSET_EXT:-apk}
BUILD_NAME=${BUILD_NAME:-}
BUILD_NUMBER=${BUILD_NUMBER:-}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

[ -n "$BUILD_NAME" ] || fail "BUILD_NAME is required"
[ -n "$BUILD_NUMBER" ] || fail "BUILD_NUMBER is required"

printf '%s-%s-v%s-b%s.%s\n' "$APP_SLUG" "$ASSET_KIND" "$BUILD_NAME" "$BUILD_NUMBER" "$ASSET_EXT"
