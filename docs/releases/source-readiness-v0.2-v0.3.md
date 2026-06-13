# Source Readiness: v0.2-v0.11

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

## Known Limitations Before the Next Tags

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
