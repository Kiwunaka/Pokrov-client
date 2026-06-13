# Release Policy

Official public releases must be easy to verify and honest about their status.

## Source-Only Releases

Source-only releases, such as `v0.1.0-source`, should include:

- tag name
- commit SHA
- source archive checksum or reproducible checksum note
- source proof manifest from `scripts/prepare-source-release.ps1`
- current feature status
- known limitations
- explicit note that no APK, EXE, store release, or trusted-signed binary is
  shipped in that release

Use [releases/SOURCE_RELEASE_TEMPLATE.md](releases/SOURCE_RELEASE_TEMPLATE.md)
for GitHub Release bodies. Milestones that are implemented on `main` but not
tagged yet must be labeled `not tagged` or `pending tag`; do not present them as
published releases.

Run `scripts/prepare-source-release.ps1` on the exact source reference before
publishing release copy. The generated proof manifest is local evidence for the
commit SHA, archive SHA-256, source-only boundary, and absence of committed
binary/signing artifacts in the archived tree.

Use `scripts/render-source-release-notes.ps1` with that proof manifest to render
the first GitHub Release body draft. The renderer refuses manifests that do not
preserve the source-only flags, then prints the tag, commit SHA, archive
checksum, public proof manifest label, and release-honesty copy.

## Binary Release Requirements

Every official binary release should include:

- version label
- target platform
- artifact filename
- SHA-256 checksum
- source reference
- install note
- known limitations
- signing or store-trust status

## Beta Wording

Use `0.x.x-beta` labels until a stable release is approved.

Do not describe a release as stable, store-ready, trusted-signed, or production
complete unless current public evidence supports that claim.

## Artifact Names

Preferred artifact names:

- `pokrov-android-universal.apk`
- `pokrov-windows-setup-x64.exe`
- `pokrov-windows-portable-x64.zip`

Additional artifacts can be published when the release notes explain their
purpose.

## Official Source Reference

When the source snapshot exists, each binary release should point to the commit
or tag used to build it.

## Fork Releases

Fork maintainers are responsible for their own versioning, checksums, signing,
support, and release claims. Fork releases must not imply official POKROV
approval.
