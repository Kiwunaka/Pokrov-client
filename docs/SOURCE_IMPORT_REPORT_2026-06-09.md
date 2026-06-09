# Source Import Report: 2026-06-09

This report records the first sanitized public source snapshot preparation.

## Scope

Imported source areas:

- Android Flutter host and Android native runtime bridge
- Windows Flutter host and Windows runner source
- shared Flutter packages
- public seed configuration
- local bootstrap, validation, runtime-fetch, and test scripts
- public brand assets used by the client shells

Not imported:

- private git history
- backend, billing, admin, deployment, node-management, and operator runbook
  material
- signing keys, certificates, env files, local generated config, release
  handoff manifests, and private release evidence
- bundled native runtime binaries such as DLL, EXE, and AAR files
- Apple host source in this snapshot

## Tooling Evidence

Source-import guardrails were landed first in PR #5.

Local preparation used a copied client snapshot outside the production checkout.
The public source import tool was then run with the checked-in policy.

Result:

- dry-run: `included=128`, `blocked=1`
- expected block: `config/release-handoff.seed.json`
- staging apply: `included=128`, `blocked=1`
- staging rescan: `included=128`, `blocked=0`
- forbidden runtime/signing/env extension search on staging: no matches
- public repository rescan after import: `included=128`, `blocked=0`
- `python -m pytest tests/test_source_import.py`: passed
- `powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-workspace.ps1`:
  passed
- `powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1`: passed
  for the default Flutter lane; Android Gradle native tests are opt-in because
  runtime binaries are intentionally not committed

## Review Notes

The public root README was preserved. The private-lane root `README.md` and old
root `DESIGN.md` were intentionally excluded from the import policy to avoid
overwriting the public project identity and to avoid stale wording rules.

Native runtime artifacts are fetched through
`scripts/fetch-libcore-assets.ps1` from the public `hiddify/hiddify-core`
release recorded in `config/runtime-artifacts.seed.json`; downloaded artifacts
are ignored and are not part of this source snapshot.

## Follow-Ups

- run the opt-in Android Gradle native test lane on a workstation with Android
  SDK/JDK compatibility after fetching `libcore.aar`
- add CI for source import tests, Flutter analysis, and package tests
- complete the dependency license audit with exact transitive dependency output
- add operator/company mode and personal-key mode documentation as code paths
  are split from the current official POKROV service flow
- keep optional public config catalogs disabled until parser, license,
  attribution, freshness, and safety gates are complete
