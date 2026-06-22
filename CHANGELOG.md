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
- Added a CODEOWNERS review-routing seed and gate for maintainer-led ownership
  across security, release, Android, Windows, runtime, operator, docs, CI, and
  source-boundary paths.
- Added a Dependabot and dependency update policy gate for GitHub Actions and
  Dart/Flutter pub workspaces with bounded PRs, labels, human review, license
  inventory, and source-only release boundaries.
- Added a required checks and branch-protection policy gate for CI job names,
  source-release gates, read-only workflow permissions, and no-claim release
  boundaries.
- Added a GitHub ruleset setup gate for repository ruleset or branch protection
  configuration, manual verification, and no-claim release boundaries.
- Added a read-only GitHub ruleset verifier for maintainers to audit remote
  rulesets or branch protection before claiming enforcement.
- Added a release evidence bundle helper that collects source preflight output,
  proof paths, source-only flags, and optional GitHub ruleset status.
- Added a source release publication dry-run validator that checks release
  evidence bundles and rendered release notes without publishing releases,
  pushing tags, or uploading assets.
- Added an enterprise boundary and seed-backed operator commercial-license
  guard for GPLv3, paid services, dual-license decisions, and fork
  distribution claims.
- Added safe support diagnostics copy/export so users can share redacted JSON
  without keys, subscription URLs, raw configs, or proxy links.
- Added a diagnostics export policy seed and docs gate for local-only,
  user-initiated, redacted support diagnostics and future log-export surfaces.
- Added a release blocker inventory seed and docs gate for source tag
  readiness, manual maintainer steps, and no-binary release boundaries.
- Added a source tag readiness command that reads blocker and readiness seeds,
  writes a local summary, and returns non-zero while required blockers remain.
- Added a release merge-order verifier that checks the local stacked PR
  manifest before manual merge or tag work.
- Added a release stack GitHub status verifier that checks a read-only PR
  status snapshot before manual merge or tag work.
- Added a release merge handoff helper that bundles local merge-order,
  GitHub-status, and tag-readiness summaries for maintainer review.
- Added an Android device validation checklist and local smoke precheck that
  writes a claim-safe `MANUAL_OWNER_TEST` summary without running ADB,
  installing builds, or mutating devices.
- Added operator API request header compliance so managed/operator client
  requests send per-request `X-Request-ID` and `X-Client-Version` metadata for
  compatibility gates and redacted support tracing.
- Added Android native Gradle unit tests to CI through a source-only stub lane
  that does not fetch or commit libcore.aar and does not prove APK, store,
  trusted signing, or runtime readiness.
- Added a Windows bundle verifier that writes source-only Windows bundle proof
  while refusing committed Windows binaries, archives, signing files, and local
  runtime artifacts; it does not build, sign, package, publish, or download
  runtime artifacts.
- Added Windows bundle verifier enforcement to CI and source-release preflight
  summaries so source-only release proof records the Windows shell boundary.
- Added release evidence bundle enforcement for Windows verifier proof so
  stale preflight summaries cannot produce complete release evidence.
- Added publication dry-run enforcement for Windows verifier proof so stale
  evidence bundles cannot reach manual GitHub Release review.
- Hardened local runtime archive fetching so archive entries are inspected
  before extraction or host sync and path traversal entries are refused.

### Changed

- Hardened community/operator/official variant boundaries.
- Hardened source-import policy and clean-clone verification.
- Updated source-release documentation to separate tagged releases from
  source-readiness milestones.
- Fixed the documented no-argument release merge handoff command so it uses the
  seed default input paths.
- Added release merge handoff enforcement for publication dry-run proof so the
  maintainer handoff cannot be ready without final no-publish review evidence.
- Added release merge handoff input fingerprints so maintainer handoff evidence
  records SHA-256 proofs for every release summary it consumed.
- Added source-only flags to the release merge handoff summary so the final
  maintainer artifact carries explicit no-binary release boundaries.
- Added canonical build input roots to the release merge handoff so the final
  maintainer artifact consumes only expected prerequisite summaries.
- Added generated-at checks to release merge handoff inputs so the final
  maintainer artifact records when each prerequisite summary was produced.
- Added release merge handoff input schema and read-only checks so maintainer
  handoffs refuse malformed or non-read-only prerequisite summaries.
- Added release merge handoff stack-count consistency checks so maintainer
  handoffs reject mixed merge-order and GitHub-status stack snapshots.
- Added release merge handoff input-error checks so maintainer handoffs reject
  prerequisite summaries that still report upstream errors.
- Added release merge handoff tag-readiness input-error coverage so
  prerequisite errors from source tag readiness are also blocked.
- Added release merge handoff tag-readiness blocker-count consistency checks
  so stale blocker summaries cannot reach maintainer handoff as ready.
- Added release merge handoff tag-readiness blocker entry-shape checks so
  malformed blocker entries cannot reach maintainer handoff as ready.
- Added release merge handoff tag-readiness ready/tag-allowed flag consistency
  checks so summaries cannot claim tag creation while blockers remain.
- Added release merge handoff tag-readiness blocker-absence consistency checks
  so summaries cannot deny tag creation after blockers are gone.
- Added source tag-readiness open-blocker evidence fields and handoff checks
  so maintainer summaries keep blocker evidence attached.
- Added release merge handoff tag-readiness latest stacked PR consistency
  checks so stale tag-readiness summaries cannot describe an older PR.
- Added release merge handoff seed validation so default tag-readiness and
  publication dry-run input paths track the blocker inventory latest candidate.
- Added release merge handoff blocker-inventory runtime checks so a handoff
  cannot be marked ready for an older candidate or PR than the blocker
  inventory tracks.
- Added source tag-readiness stale-tag rejection so the readiness command
  blocks requested tags outside the blocker inventory latest candidate.
- Added source tag-readiness milestone evidence checks so the readiness command
  blocks evidence that points at a different stacked PR than blocker inventory.
- Added source tag-readiness milestone source-only flag checks so unsafe
  milestone binary/store/trusted-signing claims block readiness summaries.
- Added source tag-readiness blocker-inventory source-only flag checks so unsafe
  inventory binary/store/trusted-signing claims block readiness summaries.
- Added source tag-readiness open-blocker evidence checks so missing blocker
  evidence is reported before release merge handoff review.
- Added source tag-readiness open-blocker identifier checks so malformed
  blockers are reported before release merge handoff review.
- Added source tag-readiness open-blocker status checks so malformed blockers
  are reported before release merge handoff review.
- Added source tag-readiness required-before-tag checks so release blockers
  cannot silently disappear from tag-readiness summaries.
- Added source tag-readiness milestone status checks so malformed
  source-readiness entries block release summaries.
- Added source tag-readiness milestone evidence checks so malformed
  source-readiness proof entries block release summaries.
- Added source tag-readiness milestone scope checks so release summaries cannot
  omit what the selected source-readiness milestone actually covers.
- Added source tag-readiness read-only summary output so release merge handoff
  can consume the real tag-readiness JSON directly.
- Added source tag-readiness input fingerprints so release evidence can prove
  which blocker inventory and source-readiness seeds produced the summary.
- Added release merge handoff tag-readiness input fingerprint checks so
  maintainer handoff evidence carries the seed fingerprints from source tag
  readiness.
- Added publication dry-run input fingerprints so maintainer handoff evidence
  carries the evidence-bundle and release-notes hashes.
- Added release evidence bundle input fingerprints and propagated the source
  preflight hash through publication dry-run and release merge handoff evidence.
- Added source preflight artifact fingerprints for proof manifest, release
  notes, source archive, and Windows verifier summary, then propagated them
  through release evidence, publication dry-run, and handoff evidence.
- Updated source-readiness tracking through the green stacked PR sequence up to
  `v0.89.0-source` candidates.

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
| `v0.33.0-source` | Pending stacked PR, not tagged | PR #53 |
| `v0.34.0-source` | Pending stacked PR, not tagged | PR #54 |
| `v0.35.0-source` | Pending stacked PR, not tagged | PR #55 |
| `v0.36.0-source` | Pending stacked PR, not tagged | PR #56 |
| `v0.37.0-source` | Pending stacked PR, not tagged | PR #57 |
| `v0.38.0-source` | Pending stacked PR, not tagged | PR #58 |
| `v0.39.0-source` | Pending stacked PR, not tagged | PR #59 |
| `v0.40.0-source` | Pending stacked PR, not tagged | PR #60 |
| `v0.41.0-source` | Pending stacked PR, not tagged | PR #61 |
| `v0.42.0-source` | Pending stacked PR, not tagged | PR #62 |
| `v0.43.0-source` | Pending stacked PR, not tagged | PR #63 |
| `v0.44.0-source` | Pending stacked PR, not tagged | PR #64 |
| `v0.45.0-source` | Pending stacked PR, not tagged | PR #65 |
| `v0.46.0-source` | Pending stacked PR, not tagged | PR #66 |
| `v0.47.0-source` | Pending stacked PR, not tagged | PR #67 |
| `v0.48.0-source` | Pending stacked PR, not tagged | PR #68 |
| `v0.49.0-source` | Pending stacked PR, not tagged | PR #69 |
| `v0.50.0-source` | Pending stacked PR, not tagged | PR #70 |
| `v0.51.0-source` | Pending stacked PR, not tagged | PR #71 |
| `v0.52.0-source` | Pending stacked PR, not tagged | PR #72 |
| `v0.53.0-source` | Pending stacked PR, not tagged | PR #73 |
| `v0.54.0-source` | Pending stacked PR, not tagged | PR #74 |
| `v0.55.0-source` | Pending stacked PR, not tagged | PR #75 |
| `v0.56.0-source` | Pending stacked PR, not tagged | PR #76 |
| `v0.57.0-source` | Pending stacked PR, not tagged | PR #77 |
| `v0.58.0-source` | Pending stacked PR, not tagged | PR #78 |
| `v0.59.0-source` | Pending stacked PR, not tagged | PR #79 |
| `v0.60.0-source` | Pending stacked PR, not tagged | PR #80 |
| `v0.61.0-source` | Pending stacked PR, not tagged | PR #81 |
| `v0.62.0-source` | Pending stacked PR, not tagged | PR #82 |
| `v0.63.0-source` | Pending stacked PR, not tagged | PR #83 |
| `v0.64.0-source` | Pending stacked PR, not tagged | PR #84 |
| `v0.65.0-source` | Pending stacked PR, not tagged | PR #85 |
| `v0.66.0-source` | Pending stacked PR, not tagged | PR #86 |
| `v0.67.0-source` | Pending stacked PR, not tagged | PR #87 |
| `v0.68.0-source` | Pending stacked PR, not tagged | PR #88 |
| `v0.69.0-source` | Pending stacked PR, not tagged | PR #89 |
| `v0.70.0-source` | Pending stacked PR, not tagged | PR #90 |
| `v0.71.0-source` | Pending stacked PR, not tagged | PR #91 |
| `v0.72.0-source` | Pending stacked PR, not tagged | PR #92 |
| `v0.73.0-source` | Pending stacked PR, not tagged | PR #93 |
| `v0.74.0-source` | Pending stacked PR, not tagged | PR #94 |
| `v0.75.0-source` | Pending stacked PR, not tagged | PR #95 |
| `v0.76.0-source` | Pending stacked PR, not tagged | PR #96 |
| `v0.77.0-source` | Pending stacked PR, not tagged | PR #97 |
| `v0.78.0-source` | Pending stacked PR, not tagged | PR #98 |
| `v0.79.0-source` | Pending stacked PR, not tagged | PR #99 |
| `v0.80.0-source` | Pending stacked PR, not tagged | PR #100 |
| `v0.81.0-source` | Pending stacked PR, not tagged | PR #101 |
| `v0.82.0-source` | Pending stacked PR, not tagged | PR #102 |
| `v0.83.0-source` | Pending stacked PR, not tagged | PR #103 |
| `v0.84.0-source` | Pending stacked PR, not tagged | PR #104 |
| `v0.85.0-source` | Pending stacked PR, not tagged | PR #105 |
| `v0.86.0-source` | Pending stacked PR, not tagged | PR #107 |
| `v0.87.0-source` | Pending stacked PR, not tagged | PR #108 |
| `v0.88.0-source` | Pending stacked PR, not tagged | PR #109 |
| `v0.89.0-source` | Pending stacked PR, not tagged | PR #110 |

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
