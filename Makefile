SHELL := /bin/sh

.DEFAULT_GOAL := help

APP_SLUG ?= voice-notes
BUILD_CHANNEL ?= test
BUILD_NAME ?=
BUILD_NUMBER ?=
TEST_ID ?=
GIT_SHA_SHORT ?=
APK_TIMESTAMP ?=
APK_OUTPUT_DIR ?= build/apk
APK_SOURCE ?= build/app/outputs/flutter-apk/app-release.apk

APK_NAME := $(shell APP_SLUG="$(APP_SLUG)" BUILD_CHANNEL="$(BUILD_CHANNEL)" BUILD_NAME="$(BUILD_NAME)" BUILD_NUMBER="$(BUILD_NUMBER)" TEST_ID="$(TEST_ID)" GIT_SHA_SHORT="$(GIT_SHA_SHORT)" APK_TIMESTAMP="$(APK_TIMESTAMP)" /bin/sh ./scripts/apk_name.sh)
APK_OUTPUT_PATH := $(APK_OUTPUT_DIR)/$(APK_NAME)
BUILD_FLAGS := $(if $(BUILD_NAME),--build-name $(BUILD_NAME)) $(if $(BUILD_NUMBER),--build-number $(BUILD_NUMBER))

.PHONY: help get fmt fmt-check analyze test test-apk-name test-release-tag test-release-asset-name check ci-check gen l10n icons splash clean run apk-debug apk-release aab-release apk-name apk-test release-validate

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make get            - flutter pub get' \
		'  make fmt            - dart format .' \
		'  make fmt-check      - verify dart formatting without changing files' \
		'  make analyze        - flutter analyze' \
		'  make test           - flutter test' \
		'  make test-apk-name  - verify APK naming script' \
		'  make test-release-tag - verify release tag validation script' \
		'  make test-release-asset-name - verify deterministic release asset naming' \
		'  make check          - analyze + tests + APK naming test' \
		'  make ci-check       - format check + analyze + tests + release helper checks' \
		'  make gen            - build_runner code generation' \
		'  make l10n           - flutter gen-l10n' \
		'  make icons          - regenerate launcher icons' \
		'  make splash         - regenerate splash assets' \
		'  make run            - flutter run' \
		'  make apk-debug      - build debug APK' \
		'  make apk-release    - build release APK' \
		'  make aab-release    - build release Android App Bundle' \
		'  make apk-name       - print current test APK filename' \
		'  make apk-test       - build release APK and copy it with test filename' \
		'  make release-validate RELEASE_TAG=v1.2.3 - ensure tag matches pubspec version' \
		'  make clean          - flutter clean'

get:
	flutter pub get

fmt:
	dart format .

fmt-check:
	dart format --output=show --set-exit-if-changed . >/dev/null

analyze:
	flutter analyze

test:
	flutter test

test-apk-name:
	sh test/scripts/apk_name_test.sh

test-release-tag:
	sh test/scripts/validate_release_tag_test.sh

test-release-asset-name:
	sh test/scripts/release_asset_name_test.sh

check: analyze test test-apk-name

ci-check: fmt-check analyze test test-apk-name test-release-tag test-release-asset-name

gen:
	dart run build_runner build --delete-conflicting-outputs

l10n:
	flutter gen-l10n

icons:
	dart run flutter_launcher_icons

splash:
	dart run flutter_native_splash:create

clean:
	flutter clean

run:
	flutter run

apk-debug:
	flutter build apk --debug $(BUILD_FLAGS)

apk-release:
	flutter build apk --release $(BUILD_FLAGS)

aab-release:
	flutter build appbundle --release $(BUILD_FLAGS)

apk-name:
	@printf '%s\n' "$(APK_NAME)"

# make apk-test BUILD_NAME=1.0.1 BUILD_NUMBER=2 TEST_ID=qa-smoke
apk-test:
	@mkdir -p "$(APK_OUTPUT_DIR)"
	flutter build apk --release $(BUILD_FLAGS)
	cp "$(APK_SOURCE)" "$(APK_OUTPUT_PATH)"
	@printf 'Created %s\n' "$(APK_OUTPUT_PATH)"

release-validate:
	sh ./scripts/validate_release_tag.sh "$(RELEASE_TAG)"
