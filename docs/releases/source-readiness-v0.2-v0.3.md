# Source Readiness: v0.2-v0.48

This document records source readiness after `v0.1.0-source`. It is not a
GitHub Release by itself. Tags must be created separately after the release
checklist is run on the exact commit. The machine-readable readiness inventory
lives in
[`config/source-release-readiness.seed.json`](../../config/source-release-readiness.seed.json).

## v0.2.0-source Candidate

Status: not tagged.

Current evidence on `main`:

- dedicated community import hub and local profile polish
- open-client variant boundary enforcement
- hardened source-import policy and public-tree clean-clone checks

Required before tagging:

- choose the exact commit SHA
- run the full source release checklist
- record source archive SHA-256 in the GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.3.0-source Candidate

Status: not tagged.

Current evidence on `main`:

- operator fixture API contract and OpenAPI documentation
- gated Free VPN catalog seed and parser fixtures
- white-label color token seed, validation, and export helper
- manual, app-resume, and in-app foreground subscription refresh scheduler

Required before tagging:

- choose the exact commit SHA
- rerun `python -m pytest tests`
- rerun `powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1`
- rerun `powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1 -Source .`
- rerun `powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1`
- record source archive SHA-256 in the GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.4.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #23: native Android/Windows host brand-boundary hardening
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.5.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #24: community routing and WARP copy honesty hardening
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.6.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #25: dependency/license and generated-asset provenance inventory gates
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.7.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #26: source-release proof helper for archive SHA-256 and proof manifests
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- generate source proof with `scripts/prepare-source-release.ps1`; annotated
  tags are expected, and the proof records both the tag object SHA and peeled
  commit SHA
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.8.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #27: source readiness matrix for tracked source-only milestones, gates, and
  limitations
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.9.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #28: public onboarding and triage hardening for community users,
  operators, PRs, and issue templates
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.10.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #29: operator API contract hardening with request IDs, versioning,
  standard errors, retry headers, and fixture smoke coverage
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.11.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #30: gated Free VPN catalog cache actions for manual opt-in import, local
  third-party catalog profiles, refresh metadata, and clear scope
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.12.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #31: source-readiness synchronization for stacked source-only milestones
  through the Free VPN catalog cache action slice
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.13.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #32: manual Free VPN catalog import gated behind
  `OPEN_CLIENT_ENABLE_FREE_CATALOG` with default-disabled public builds
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.14.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #33: source-readiness synchronization through the default-disabled Free VPN
  catalog feature flag slice
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.15.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #34: operator support ticket path canonicalization across docs, OpenAPI,
  fixtures, smoke tests, and app adapter contracts
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.16.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #35: community local-access wording and model guards so Open Client local
  profiles are not presented as free POKROV service nodes
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.17.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #36: seed-backed variant command preview tooling for Android and Windows
  community, operator, and official POKROV build modes
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.18.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #38: proof-manifest-backed source release notes renderer that preserves
  source-only honesty flags before GitHub Release publication
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release checklist on that commit
- render and review the GitHub Release body from the proof manifest
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.19.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #39: annotated source tag enforcement for proof-manifest generation so
  lightweight tags cannot be used for source release publication
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- create an annotated source tag with `git tag -a`
- choose the exact commit SHA
- run the full source release checklist on that commit
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.20.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #40: end-to-end source-release smoke proving the generated proof manifest
  can render source-only GitHub Release notes without local path leakage
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- create an annotated source tag with `git tag -a`
- choose the exact commit SHA
- run the full source release checklist on that commit
- render and review the GitHub Release body from the generated proof manifest
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.21.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #41: self-documenting rendered source release notes; generated
  verification blocks include the renderer command with a public manifest label
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- create an annotated source tag with `git tag -a`
- choose the exact commit SHA
- run the full source release checklist on that commit
- render and review the GitHub Release body from the generated proof manifest
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.22.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #42: one-command source-release preflight that runs the release gate,
  creates proof artifacts, renders source-only notes, and writes a local summary
  without publishing binaries
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- create an annotated source tag with `git tag -a`
- choose the exact commit SHA
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.23.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #43: CI source-release preflight smoke coverage so pull requests exercise
  proof generation, release-note rendering, and summary output together
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- create an annotated source tag with `git tag -a`
- choose the exact commit SHA
- confirm GitHub Actions still runs the source-release preflight smoke on the
  release branch or tag
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.24.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #44: specialized GitHub triage templates for profile import problems,
  operator integration questions, and public security-report redirection
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm issue templates still collect track/variant, redaction, and security
  redirect context
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.25.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #45: canonical GitHub label catalog and triage policy for community,
  operator, platform, parser, runtime, release, and security-private routing
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm GitHub issue-template labels still exist in `.github/labels.yml`
- keep `security-private` as a redirect label, not a public vulnerability
  investigation lane
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.26.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #46: runtime artifact manifest gate for local-only libcore downloads,
  pending binary review metadata, SHA-256 verification hooks, and safe sync
  destinations
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `config/runtime-artifacts.seed.json` still records pending or
  approved license/binary review for each runtime archive
- keep `PENDING_PUBLIC_BINARY_REVIEW` until a public binary release review
  records real archive SHA-256 values
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.27.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #47: source release copy-claims gate for release policy, checklist,
  source release template, renderer, and rendered GitHub Release drafts
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- rerun `scripts/check-source-release-copy.ps1 -ReleaseNotesPath <file>` after
  manually editing the GitHub Release body
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.28.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #48: Free VPN catalog provenance gate for reviewed feed hosts, attribution,
  license evidence, no-network CI, and required release-note boundaries
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `config/free-vpn-catalog.seed.json` still keeps network fetch disabled
  in CI and runtime fetch disabled by default
- confirm release notes that mention the catalog say: third-party public configs,
  not official POKROV nodes, user-initiated, and no speed, privacy, uptime,
  safety, legality, or availability promise
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.29.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #49: private security intake gate for public issue redirection, redaction
  boundaries, QR/subscription URL handling, and source-only security claims
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `config/security-intake.seed.json` still forbids public vulnerability
  issues and keeps blank public issues disabled
- confirm issue templates and docs still redirect vulnerabilities to private
  reporting and forbid public secrets, QR payloads, subscription URLs, signing
  material, and private backend details
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, and rendered GitHub Release body
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.30.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #50: changelog and release-history gate for source readiness milestone
  synchronization, evidence-honest public release notes, and source-only
  boundary copy
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `CHANGELOG.md` lists every source readiness milestone without
  presenting pending PRs as published tags
- confirm `config/changelog-policy.seed.json` still requires source-only
  boundary copy and forbids unsupported release claims
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.31.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #51: contributor doctor and docs index gate for read-only toolchain
  diagnostics, local bootstrap template coverage, build issue reporting, and
  source-only onboarding
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run `scripts\doctor.ps1` and confirm it remains read-only
- confirm build issues ask for redacted `scripts\doctor.ps1 -Json` output
- confirm `config/templates/device-overrides.seed.json` still exists for
  `bootstrap-local.ps1`
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.32.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #52: build troubleshooting router for source checkout, toolchain,
  Android, Windows, runtime-artifact, clean-clone, and redacted issue-report
  paths
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `docs/TROUBLESHOOTING.md` remains the canonical troubleshooting
  detail page instead of duplicating build instructions in every entrypoint
- confirm build issues still ask which troubleshooting step was tried and keep
  redacted `scripts\doctor.ps1 -Json` output separate from raw logs
- confirm CI runs only the source-boundary doctor smoke with
  `-SkipCommandChecks` in jobs that do not install Flutter/Dart
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.33.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #53: CODEOWNERS and review-routing gate for maintainer-led source-only
  ownership across security, release, Android, Windows, runtime, operator,
  docs, CI, and source-boundary paths
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `.github/CODEOWNERS` still covers security, release, Android,
  Windows, runtime, operator contract, docs, CI, and source-boundary paths
- confirm `config/codeowners-review.seed.json` still matches the CODEOWNERS
  routes and allowed owners
- confirm governance and triage docs still say CODEOWNERS is review routing,
  not an official-build, signing, store, or production-readiness claim
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.34.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #54: Dependabot and dependency update policy gate for GitHub Actions and
  Dart/Flutter pub workspaces with bounded PRs, labels, human review, license
  inventory, and source-only release boundaries
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `.github/dependabot.yml` still covers GitHub Actions and every
  Android/Windows/shared Dart pub workspace
- confirm `config/dependabot-policy.seed.json` still matches the configured
  ecosystems, pub directories, labels, and human-review gates
- confirm dependency update docs still say Dependabot PRs are review requests,
  not automatic release approval
- confirm `config/dependency-license-inventory.seed.json` is updated when
  `pubspec.lock` contents change
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.35.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #55: required checks and branch-protection policy gate for CI job names,
  source-release gates, read-only workflow permissions, and no-claim release
  boundaries
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `config/required-checks.seed.json` still matches
  `.github/workflows/ci.yml`
- confirm `docs/REQUIRED_CHECKS.md` still documents required check names without
  claiming remote GitHub branch protection is already enabled
- confirm release docs still forbid using `-SkipTestCommands` for public source
  release publication
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.36.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #56: GitHub ruleset setup gate for repository ruleset or branch protection
  configuration, manual verification, and no-claim release boundaries
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `config/github-ruleset.seed.json` still matches
  `docs/GITHUB_RULESET_SETUP.md` and `config/required-checks.seed.json`
- confirm `docs/GITHUB_RULESET_SETUP.md` still says it is setup guidance, not
  proof of remote GitHub enforcement
- if public copy claims branch protection/rulesets are enforced, confirm the
  repository settings were configured and observed in GitHub first
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.37.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #57: read-only GitHub ruleset verifier for maintainers to audit remote
  rulesets or branch protection before claiming enforcement
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `scripts/check-github-ruleset.ps1` remains read-only and does not
  create, edit, or delete remote GitHub settings
- run `scripts/check-github-ruleset.ps1 -ReportOnly -Json` to record current
  remote GitHub settings status
- before claiming remote enforcement, run `scripts/check-github-ruleset.ps1`
  without `-ReportOnly` and confirm it passes
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the preflight summary, proof manifest, rendered GitHub Release body,
  and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.38.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #58: release evidence bundle helper that collects source preflight output,
  proof paths, source-only flags, and optional GitHub ruleset status
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- optionally run `scripts/check-github-ruleset.ps1 -ReportOnly -Json` and keep
  the report with the handoff
- run `scripts/prepare-release-evidence-bundle.ps1` with the exact preflight
  summary and optional ruleset report
- confirm the release evidence bundle keeps source-only flags true and keeps
  GitHub enforcement claims disabled when the ruleset report is failing or
  missing
- review the preflight summary, proof manifest, rendered GitHub Release body,
  release evidence bundle, and changelog section for the exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.39.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #59: source release publication dry-run validator for checking the release
  evidence bundle and rendered release notes before manual GitHub Release
  publication
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- run `scripts/prepare-release-evidence-bundle.ps1` with the exact preflight
  summary and optional ruleset report
- run `scripts/validate-source-release-publication.ps1` with the exact release
  evidence bundle and rendered release notes
- confirm the publication dry-run keeps `publish_performed=false` and
  `tag_push_performed=false`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.40.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #60: enterprise boundary and operator commercial-license guard for GPLv3,
  paid service, dual-license, and fork distribution claims
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `docs/ENTERPRISE.md` still says it is not legal advice, does not
  change `LICENSE`, does not waive GPLv3 obligations, and does not offer a
  commercial license by default
- confirm operator docs still say operators bring their own backend, billing,
  support, signing, privacy policy, release channels, checksums, release notes,
  and source-compliance path
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.41.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #61: safe support diagnostics copy/export for redacted JSON without keys,
  subscription URLs, raw configs, or proxy links
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm support diagnostics copy/export still uses the shared redactor and
  does not include proxy links, subscription URLs, raw configs, token/secret
  fields, WARP private material, or private backend details
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.42.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #62: privacy-first diagnostics export policy gate for local-only,
  user-initiated, redacted support diagnostics and future log-export surfaces
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `config/diagnostics-export-policy.seed.json` and
  `docs/DIAGNOSTICS_EXPORT_POLICY.md` still require local-only,
  user-initiated, redacted exports by default
- confirm new diagnostics or log export surfaces are listed in the policy seed,
  documented, tested, and do not include raw configs, subscription URLs, proxy
  links, token/secret fields, WARP private material, signing material, or
  private backend details
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.43.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #63: release blocker inventory for source tag readiness, manual
  maintainer steps, and no-binary release boundaries
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- confirm `config/release-blocker-inventory.seed.json` and
  `docs/RELEASE_BLOCKERS.md` still mark the line as not ready for tag until
  every required manual maintainer step is cleared for the exact source
  candidate
- confirm the blocker inventory still requires full source preflight, release
  evidence bundle review, release-note review, no-binary copy review, and
  catalog/diagnostics boundary review
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.44.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #64: source tag readiness command that reads blocker and readiness seeds,
  writes a local summary, and returns non-zero while required blockers remain
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run `scripts/check-source-tag-readiness.ps1 -Tag <tag>` and confirm the
  generated summary matches the exact source candidate and blocker inventory
- clear every required manual maintainer blocker before treating the command as
  ready
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.45.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #65: release merge-order verifier that checks the local stacked PR
  manifest before manual merge or tag work
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run `scripts/check-release-merge-order.ps1` and confirm the generated summary
  records a linear base-to-head chain for the exact stacked PR sequence
- run `scripts/check-source-tag-readiness.ps1 -Tag <tag>` and confirm the
  generated summary matches the exact source candidate and blocker inventory
- clear every required manual maintainer blocker before treating the line as
  ready
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.46.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #66: release stack GitHub status verifier that checks a read-only PR
  status snapshot before manual merge or tag work
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run `scripts/check-release-merge-order.ps1` and confirm the generated summary
  records a linear base-to-head chain for the exact stacked PR sequence
- run `scripts/check-release-stack-github-status.ps1` and confirm the generated
  summary records matching base/head refs, non-draft PRs, clean merge state,
  and successful required CI checks for the exact stacked PR sequence
- run `scripts/check-source-tag-readiness.ps1 -Tag <tag>` and confirm the
  generated summary matches the exact source candidate and blocker inventory
- clear every required manual maintainer blocker before treating the line as
  ready
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.47.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #67: release merge handoff helper that bundles local merge-order,
  GitHub-status, and tag-readiness summaries for maintainer review
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run `scripts/check-release-merge-order.ps1` and confirm the generated summary
  records a linear base-to-head chain for the exact stacked PR sequence
- run `scripts/check-release-stack-github-status.ps1` and confirm the generated
  summary records matching base/head refs, non-draft PRs, clean merge state,
  and successful required CI checks for the exact stacked PR sequence
- run `scripts/check-source-tag-readiness.ps1 -Tag <tag>` and confirm the
  generated summary matches the exact source candidate and blocker inventory
- run `scripts/prepare-release-merge-handoff.ps1` with those exact summaries
  and review the handoff before manual merge or tag work
- clear every required manual maintainer blocker before treating the line as
  ready
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## v0.48.0-source Candidate

Status: stacked PR green, not tagged.

Current evidence:

- PR #68: Android device validation checklist and local smoke precheck plus
  release merge handoff default-path regression fix
- GitHub CI green on the stacked PR

Required before tagging:

- merge the stacked PR sequence through `main`
- choose the exact commit SHA
- run `scripts/android-device-smoke.ps1` and review the generated
  `MANUAL_OWNER_TEST` summary
- run `scripts/prepare-release-merge-handoff.ps1` without custom paths after
  generating the prerequisite default summaries
- clear every required manual maintainer blocker before treating the line as
  ready
- run the full source release preflight on that commit with
  `scripts/source-release-preflight.ps1 -RequireTag`
- review the publication dry-run, release evidence bundle, preflight summary,
  proof manifest, rendered GitHub Release body, and changelog section for the
  exact release
- keep explicit source-only wording: no APK, EXE, store release, or trusted
  signing claim

## Known Limitations Before the Next Tags

- Android device validation is a public checklist and local precheck only. It
  does not run ADB, install builds, mutate a device, replace the release-build
  audit, or prove APK, store, trusted signing, production, or official binary
  readiness.
- The release merge handoff helper now supports the documented no-argument
  command, but it still depends on prerequisite default summaries and does not
  merge PRs, create tags, push refs, publish releases, or clear manual
  blockers.
- The release merge handoff helper is a local summary builder only. It does not
  merge PRs, choose a release commit, create annotated tags, push refs, publish
  GitHub Releases, upload assets, clear manual blockers, or authorize binary
  claims.
- The release stack GitHub status verifier checks a read-only PR status
  snapshot. It does not merge PRs, create tags, push refs, publish GitHub
  Releases, upload assets, or prove that maintainers completed the manual merge
  sequence after the snapshot was captured.
- The release merge-order verifier checks the local stack manifest only. It
  does not merge PRs, query GitHub state, push refs, create tags, or prove the
  remote repository was merged in that order.
- The source tag readiness command is a local review helper. It does not merge
  PRs, create tags, push refs, publish GitHub Releases, upload assets, run the
  full source preflight, or approve release copy by itself.
- The release blocker inventory is a planning and review guardrail. It does
  not merge PRs, create tags, run the maintainer preflight, publish releases,
  or make the source line ready for tag by itself.
- The diagnostics export policy is a source guardrail. It does not make support
  upload automatic, prove runtime connectivity, approve raw log export, or
  replace manual review of accidental secrets.
- Safe diagnostics export is a support aid only. It does not upload logs,
  prove runtime connectivity, include raw configs, or replace maintainer review
  for accidental secrets.
- Free VPN catalog remains disabled by default and is not an official POKROV
  service.
- No OS background subscription refresh is claimed.
- Native Android/Windows host artifact metadata now has neutral source defaults
  and brand-boundary tests; downstream binary releases still own signing,
  package identifiers, store metadata, and operator review.
- WARP public copy for community local profiles now stays product-first and
  avoids official-service wording; route-mode copy still does not prove
  network-level routing quality, speed, privacy, or availability.
- Dependency/license inventory and generated asset provenance are now covered
  for the public source tree; runtime binary, native-store, installer, signing,
  and platform metadata review remain binary release gates.
- Gated Free VPN catalog cache actions are still opt-in and third-party; they
  do not imply official POKROV nodes, default public config fetches, binary
  readiness, or safety/speed/privacy guarantees.
- Manual third-party catalog import now requires
  `OPEN_CLIENT_ENABLE_FREE_CATALOG=true`; default source builds keep the action
  visible as a disabled preview instead of fetching public feeds.
- Community access UI and seed context now present local user-owned profiles
  instead of a free POKROV node, trial, or Telegram-bonus service lane.
- Variant command previews are generated from public seed files only; they do
  not build, sign, package, upload, or create release artifacts.
- Source release notes rendering is a draft helper only; maintainers must still
  review feature status, known limitations, and the exact source reference
  before publishing a GitHub Release.
- Source release proof generation now refuses lightweight tags; maintainers must
  create annotated source tags before running the final proof command.
- The proof-to-notes smoke validates the generated source release manifest and
  rendered release body shape; maintainers still own final feature-status and
  limitation wording before publication.
- Rendered verification blocks now document the release-note renderer command,
  but maintainers still choose the final public proof-manifest attachment name
  and release-note file name before publication.
- The source-release preflight helper ties the local gate together, but
  `-SkipTestCommands` remains smoke-only and must not be used for a public
  source release.
- CI runs the source-release preflight in smoke mode after the Python contract
  tests; release publication still requires the full local preflight without
  `-SkipTestCommands`.
- GitHub issue templates now route profile-import problems, operator
  integration questions, and public security-report redirects separately, but
  maintainers must still moderate accidental public secrets or vulnerability
  details.
- GitHub labels now have a canonical catalog, but maintainers still apply
  `good first issue` only after checking the task is small, public, and does not
  require private POKROV access.
- Runtime artifact metadata now has source-only review gates and SHA-256 hooks,
  but `hiddify/hiddify-core` archives remain local-only downloads until a
  separate public binary review records exact hashes and redistribution notes.
- Source release copy now has a dedicated checker, but maintainers still own
  the final human review of feature status and known limitations before
  publishing a GitHub Release.
- Free VPN catalog provenance now records reviewed feed hosts, license evidence,
  attribution, no-network CI, and required release-note boundaries; it still
  remains disabled by default and must not become an official POKROV node pool.
- Private security intake now has a seed-backed gate, but maintainers still
  must close, redact, or redirect accidental public vulnerability details,
  secrets, QR payloads, subscription URLs, signing material, and private
  backend details.
- Changelog and release-history policy is now seed-backed, but maintainers
  still own exact release-date and final feature-status edits when a real
  source tag is published.
- Contributor doctor is a read-only diagnostic helper. It does not install
  dependencies, fetch runtime binaries, build artifacts, copy local config, or
  prove Android SDK, Visual Studio, signing, store, or runtime binary readiness.
- Troubleshooting docs route common local failures, but they do not replace
  platform SDK setup, private operator support, runtime binary review, signing,
  store submission, or official POKROV release gates.
- CODEOWNERS review routing is maintainer-led and source-only. It does not
  grant official binary authority, trusted signing, store readiness, production
  support, or private backend access.
- Dependabot update routing improves source dependency visibility, but it does
  not replace human license review, runtime binary review, source-release
  proof, signing, store submission, or official binary approval.
- Required-checks policy documents the expected CI and release gates, but remote
  GitHub branch protection/ruleset enforcement still has to be configured and
  observed in repository settings before public copy can claim it is enforced.
- GitHub ruleset setup is now seed-backed, but actual remote repository
  rulesets or branch protection still require maintainer configuration and
  observation in GitHub settings before public copy can claim enforcement.
- The GitHub ruleset verifier is read-only. A failing verifier records missing
  remote enforcement; it does not configure repository settings by itself.
- The release evidence bundle is a local handoff artifact. It does not publish
  GitHub Releases, push tags, upload binaries, or replace maintainer review.
- The publication dry-run validates local release evidence and rendered notes,
  but maintainers still perform the actual GitHub Release creation manually.
- Enterprise boundary docs are operational guidance, not legal advice. They do
  not change GPLv3, offer a commercial license by default, waive operator
  source obligations, or make operator builds official POKROV builds.
