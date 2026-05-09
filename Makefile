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

.PHONY: help get fmt analyze test test-apk-name check gen l10n icons splash clean run apk-debug apk-release apk-name apk-test

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make get            - flutter pub get' \
		'  make fmt            - dart format .' \
		'  make analyze        - flutter analyze' \
		'  make test           - flutter test' \
		'  make test-apk-name  - verify APK naming script' \
		'  make check          - analyze + tests + APK naming test' \
		'  make gen            - build_runner code generation' \
		'  make l10n           - flutter gen-l10n' \
		'  make icons          - regenerate launcher icons' \
		'  make splash         - regenerate splash assets' \
		'  make run            - flutter run' \
		'  make apk-debug      - build debug APK' \
		'  make apk-release    - build release APK' \
		'  make apk-name       - print current test APK filename' \
		'  make apk-test       - build release APK and copy it with test filename' \
		'  make clean          - flutter clean'

get:
	flutter pub get

fmt:
	dart format .

analyze:
	flutter analyze

test:
	flutter test

test-apk-name:
	sh test/scripts/apk_name_test.sh

check: analyze test test-apk-name

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

apk-name:
	@printf '%s\n' "$(APK_NAME)"

# make apk-test BUILD_NAME=1.0.1 BUILD_NUMBER=2 TEST_ID=qa-smoke
apk-test:
	@mkdir -p "$(APK_OUTPUT_DIR)"
	flutter build apk --release $(BUILD_FLAGS)
	cp "$(APK_SOURCE)" "$(APK_OUTPUT_PATH)"
	@printf 'Created %s\n' "$(APK_OUTPUT_PATH)"
