# Android CI/CD and Release Process

This repository is configured for Android-focused CI/CD in GitHub Actions.

## What is automated

- `CI` workflow: runs on every `pull_request` to `main`, every `push` to `main`, and manual `workflow_dispatch`
- `Release Android` workflow: runs on tags matching `vX.Y.Z` and prerelease tags like `vX.Y.Z-rc.1`, then publishes a GitHub Release with signed Android assets
- Release artifacts:
  - signed `APK`
  - signed `AAB`

## Files involved

- `.github/workflows/ci.yml`
- `.github/workflows/release.yml`
- `Makefile`
- `scripts/validate_release_tag.sh`
- `scripts/release_asset_name.sh`

## Required GitHub secrets

Create these repository secrets before the first Android release:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Recommended way to prepare `ANDROID_KEYSTORE_BASE64` locally:

```bash
base64 -i android/voicenotes-release.jks | pbcopy
```

If your shell does not support `pbcopy`, print it instead:

```bash
base64 -i android/voicenotes-release.jks
```

## Required GitHub repository settings

1. In `Settings -> Actions -> General -> Workflow permissions`, enable `Read and write permissions` for `GITHUB_TOKEN`.
2. In `Settings -> Branches`, protect `main`.
3. Require the `CI` workflow to pass before merging into `main`.

Optional hardening:

- Add a GitHub Environment named `release` and require manual approval before publishing.
- Limit who can push tags matching `v*`.

## Release versioning rule

- Source of truth: `pubspec.yaml`
- Format: `version: X.Y.Z+N`
- Git tag must match the build name exactly: `vX.Y.Z` or `vX.Y.Z-prerelease`

Examples:

- `version: 1.4.0+17` -> release tag must be `v1.4.0`
- `version: 2.0.3+42` -> release tag must be `v2.0.3`
- `version: 2.1.0-rc.1+7` -> release tag must be `v2.1.0-rc.1`

The workflow validates this automatically and fails if the tag and `pubspec.yaml` do not match.

## Standard release flow

1. Update `version:` in `pubspec.yaml`.
2. Merge the release-ready commit into `main`.
3. Wait for the `CI` workflow on `main` to pass.
4. Create and push the release tag:

```bash
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

5. Wait for the `Release Android` workflow to finish.
6. Open the generated GitHub Release and verify that both assets are attached.

## Manual re-run for an existing tag

If the tag already exists and you need to rebuild or republish assets:

1. Open `Actions -> Release Android`
2. Click `Run workflow`
3. Enter the existing tag, for example `v1.0.0`

The workflow checks out that tag, rebuilds the Android assets, and creates or updates the matching GitHub Release.

## Future hardening to consider

- Decide whether Android releases must be allowed only for tags that point to commits reachable from `main`.
- This is not enforced by the current workflow yet, so the policy should be agreed separately before adding branch ancestry validation.

## Produced asset names

Release assets use deterministic names based on `pubspec.yaml` version metadata:

- `voice-notes-android-vX.Y.Z-bN.apk`
- `voice-notes-android-vX.Y.Z-bN.aab`
- `voice-notes-latest.apk`

Example:

- `voice-notes-android-v1.2.3-b45.apk`
- `voice-notes-android-v1.2.3-b45.aab`
- `voice-notes-android-v2.1.0-rc.1-b7.apk`

The versioned asset names remain useful for auditability and manual downloads. In addition, every release uploads a stable alias named `voice-notes-latest.apk`, which makes it safe to link the newest APK from `README.md`:

```text
https://github.com/Whoami005/voice_notes/releases/latest/download/voice-notes-latest.apk
```

## Local verification commands

Useful commands before pushing workflow changes:

```bash
make test-release-tag
make test-release-asset-name
make ci-check
```

For tag validation only:

```bash
make release-validate RELEASE_TAG=v1.2.3
```

## Current scope

- Android CI/CD is automated
- GitHub Releases are automated
- iOS build and distribution are intentionally out of scope for now
