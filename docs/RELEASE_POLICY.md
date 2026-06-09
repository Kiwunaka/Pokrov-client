# Release Policy

Official public releases must be easy to verify and honest about their status.

## Source-Only Releases

Source-only releases, such as `v0.1.0-source`, should include:

- tag name
- commit SHA
- source archive checksum or reproducible checksum note
- current feature status
- known limitations
- explicit note that no APK, EXE, store release, or trusted-signed binary is
  shipped in that release

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
