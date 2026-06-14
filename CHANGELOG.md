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
- Added a source release notes renderer that turns a proof manifest into a
  source-only GitHub Release body and refuses binary-claim manifests.
- Added an annotated-tag guard so source-release proof generation refuses
  lightweight source tags.
- Added an end-to-end source-release smoke proving generated proof manifests
  render source-only release notes without local path leakage.
- Added the release-note renderer command to generated source-only verification
  blocks so release bodies document their own rendering step.
- Added a source-release preflight helper that runs the local release gate,
  prepares proof artifacts, renders source-only release notes, and writes a
  local summary without publishing binaries.
- Added CI source-release preflight smoke coverage so pull requests exercise
  the proof-to-notes helper path automatically.
- Added specialized GitHub issue templates for profile import problems,
  operator integration questions, and public security-report redirection.
- Added a canonical GitHub label catalog and triage policy for community,
  operator, platform, parser, runtime, release, and security-private routing.
- Added runtime artifact manifest review gates for local-only libcore downloads,
  pending binary review metadata, SHA-256 verification hooks, and safe sync
  destinations.
- Added a source release copy-claims checker for policy, checklist, template,
  renderer, and rendered GitHub Release drafts.
- Added Free VPN catalog provenance gates for reviewed feed hosts, attribution,
  license evidence, no-network CI, and required release-note boundaries.
- Added a private security intake seed and validation gate for public issue
  redirection, secret redaction, QR/subscription URL handling, and source-only
  release claim safety.
- Added a changelog policy seed and release-history gate so source readiness
  milestones stay synchronized with public release notes.
- Added a read-only contributor doctor, docs index, and build-issue reporting
  hook so source contributors can share redacted toolchain diagnostics without
  installing dependencies or creating artifacts.
- Added a build troubleshooting router for source checkout, toolchain,
  Android, Windows, runtime-artifact, clean-clone, and redacted issue-report
  paths.

### Changed

- Hardened community/operator/official variant boundaries.
- Hardened source-import policy and clean-clone verification.
- Updated source-release documentation to separate tagged releases from
  source-readiness milestones.
- Updated source-readiness tracking through the green stacked PR sequence up to
  `v0.32.0-source` candidates.

### Source Readiness Candidates

| Milestone | Changelog status | Evidence |
| --- | --- | --- |
| `v0.1.0-source` | Tagged | `docs/releases/v0.1.0-source.md` |
| `v0.2.0-source` | Not tagged | `docs/releases/source-readiness-v0.2-v0.3.md` |
| `v0.3.0-source` | Not tagged | `docs/releases/source-readiness-v0.2-v0.3.md` |
| `v0.4.0-source` | Pending stacked PR, not tagged | PR #23 |
| `v0.5.0-source` | Pending stacked PR, not tagged | PR #24 |
| `v0.6.0-source` | Pending stacked PR, not tagged | PR #25 |
| `v0.7.0-source` | Pending stacked PR, not tagged | PR #26 |
| `v0.8.0-source` | Pending stacked PR, not tagged | PR #27 |
| `v0.9.0-source` | Pending stacked PR, not tagged | PR #28 |
| `v0.10.0-source` | Pending stacked PR, not tagged | PR #29 |
| `v0.11.0-source` | Pending stacked PR, not tagged | PR #30 |
| `v0.12.0-source` | Pending stacked PR, not tagged | PR #31 |
| `v0.13.0-source` | Pending stacked PR, not tagged | PR #32 |
| `v0.14.0-source` | Pending stacked PR, not tagged | PR #33 |
| `v0.15.0-source` | Pending stacked PR, not tagged | PR #34 |
| `v0.16.0-source` | Pending stacked PR, not tagged | PR #35 |
| `v0.17.0-source` | Pending stacked PR, not tagged | PR #36 |
| `v0.18.0-source` | Pending stacked PR, not tagged | PR #38 |
| `v0.19.0-source` | Pending stacked PR, not tagged | PR #39 |
| `v0.20.0-source` | Pending stacked PR, not tagged | PR #40 |
| `v0.21.0-source` | Pending stacked PR, not tagged | PR #41 |
| `v0.22.0-source` | Pending stacked PR, not tagged | PR #42 |
| `v0.23.0-source` | Pending stacked PR, not tagged | PR #43 |
| `v0.24.0-source` | Pending stacked PR, not tagged | PR #44 |
| `v0.25.0-source` | Pending stacked PR, not tagged | PR #45 |
| `v0.26.0-source` | Pending stacked PR, not tagged | PR #46 |
| `v0.27.0-source` | Pending stacked PR, not tagged | PR #47 |
| `v0.28.0-source` | Pending stacked PR, not tagged | PR #48 |
| `v0.29.0-source` | Pending stacked PR, not tagged | PR #49 |
| `v0.30.0-source` | Pending stacked PR, not tagged | PR #50 |
| `v0.31.0-source` | Pending stacked PR, not tagged | PR #51 |
| `v0.32.0-source` | Pending stacked PR, not tagged | PR #52 |

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
