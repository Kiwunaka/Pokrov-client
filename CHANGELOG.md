# Changelog

All notable public changes to this repository should be recorded here.

This project uses evidence-honest release notes. Do not claim store
availability, stable releases, trusted signing, raw device-audit proof, or
production readiness without matching public evidence.

## Unreleased

### Added

- Added operator fixture API contract, OpenAPI documentation, and smoke tests.
- Added gated Free VPN catalog parser metadata and fixtures for reviewed
  public feeds.
- Added white-label color token seed, validation, and export helpers for
  operator forks.
- Added foreground in-app subscription refresh scheduling for community
  subscription URLs.
- Added gated Free VPN catalog import/cache/clear actions for reviewed
  third-party public configs, still opt-in and disabled by default.
- Added `OPEN_CLIENT_ENABLE_FREE_CATALOG=false` as the default build gate for
  manual third-party catalog imports.
- Added an operator support-contract guard so docs, OpenAPI, fixture seeds, and
  smoke tests use the same `/api/tickets` paths as the app support adapter.
- Added community local-access wording and model guards so Open Client does not
  present local profiles as a free POKROV node or Telegram-bonus service lane.
- Added a variant command preview helper that prints seed-backed Android and
  Windows `flutter run` / `flutter build` commands without mutating the tree.

### Changed

- Hardened community/operator/official variant boundaries.
- Hardened source-import policy and clean-clone verification.
- Updated source-release documentation to separate tagged releases from
  source-readiness milestones.
- Updated source-readiness tracking through the green stacked PR sequence up to
  `v0.17.0-source` candidates.

### Still Source-Only

- No APK, EXE, store release, trusted signing, or official binary claim is made
  by this changelog section.

## v0.1.0-source - 2026-06-09

- Tagged the first source-only Android and Windows snapshot.
- Added local community profile import for supported key schemes.
- Added subscription URL import and manual/foreground refresh foundation.
- Added QR import foundation through shared local parser flows.
- Added clean-clone source-boundary proof.
- Shipped no APK, EXE, store release, trusted signing, or official binary.

## Repository Foundation

- Added the public open-source repository foundation.
- Added contribution, security, support, brand, release, and issue-template
  documents.
- Added English and Russian README entrypoints.
- Added imagegen raster repository visuals for the README and architecture
  boundary.
- Added governance and source-import playbook documentation.
