# Scripts

This folder is for non-destructive local helpers only.

Current helpers:

- `doctor.ps1`: read-only contributor diagnostic for required public files,
  PowerShell version, and local `git`/`python`/`flutter`/`dart` commands; pass
  `-Json` for build issues or `-SkipCommandChecks` for docs-only validation
- `validate-seed.ps1`: checks the public Android/Windows scaffold, shared packages, and JSON config seeds
- `bootstrap-workspace.ps1`: runs `flutter pub get` across the clean-room packages and available host entrypoints; pass `-OfflinePubGet` when an old Flutter/Dart pub advisory fetch breaks online dependency resolution but the local package cache is already populated
- `run-tests.ps1`: bootstraps the workspace and runs the shared shell widget tests; accepts `-OfflinePubGet` and forwards it to bootstrap
- `run-operator-fixture-smoke.ps1`: starts the local operator API fixture on a smoke-only port, checks session/profile/apps/support/error-mode responses, then stops the fixture; pass `-Port` to avoid local or CI collisions
- `android-device-smoke.ps1`: runs the Android device validation local
  precheck against public source files and writes a claim-safe
  `MANUAL_OWNER_TEST` summary under ignored
  `build/android-device-validation/`; it does not run ADB, install builds, or
  mutate a device
- `bootstrap-local.ps1`: copies example config seeds into `config/local/` without touching production paths unless explicitly forced
- `prepare-oss-import.ps1`: runs the source-import tests and safe importer against a temporary snapshot/stage pair; rejects staging inside this public repo
- `prepare-source-release.ps1`: creates a source-only archive proof manifest with commit SHA, SHA-256, and explicit no-APK/no-EXE/no-store/no-signing flags
- `render-source-release-notes.ps1`: renders a source-only GitHub Release body from a `prepare-source-release.ps1` proof manifest and refuses manifests that do not preserve source-only honesty flags
- `check-source-release-copy.ps1`: checks the release policy, checklist, template, renderer, and optionally a rendered release note for source-only claim boundaries
- `source-release-preflight.ps1`: runs the source release gate, creates the proof archive/manifest, renders source-only release notes, checks release-copy boundaries, and writes a local preflight summary; `-SkipTestCommands` is only for smoke tests, not publishing
- `prepare-release-evidence-bundle.ps1`: writes a local release evidence bundle
  from a source preflight summary and optional GitHub ruleset report; output is
  under ignored `build/release-evidence/` and nothing is published
- `validate-source-release-publication.ps1`: validates a release evidence
  bundle and rendered release notes as a local publication dry-run; writes
  ignored `build/source-release-publication/` output and does not publish, push
  tags, or upload assets
- `check-source-tag-readiness.ps1`: reads the release blocker inventory and
  source readiness list, then writes a local source tag readiness summary under
  ignored `build/source-tag-readiness/`; returns a non-zero exit code while
  required manual maintainer blockers remain open
- `check-release-merge-order.ps1`: checks the local release merge order
  manifest for a linear stacked PR base-to-head chain; writes ignored
  `build/release-merge-order/` output and does not merge, push, or publish
  anything
- `check-release-stack-github-status.ps1`: checks a read-only release stack GitHub status
  snapshot against the local merge-order manifest; writes ignored
  `build/release-stack-github-status/` output and does not merge, push, or
  publish anything
- `prepare-release-merge-handoff.ps1`: creates a release merge handoff report
  by bundling release merge order, release stack GitHub status, and source tag
  readiness summaries into an ignored
  `build/release-merge-handoff/` maintainer handoff report without merging,
  tagging, pushing, publishing, or uploading anything
- `check-github-ruleset.ps1`: read-only GitHub settings verifier for repository
  rulesets or branch protection; uses `gh api`, supports `-ReportOnly -Json`,
  and does not create, edit, or delete remote settings
- `print-build-variant-command.ps1`: prints a PowerShell `flutter run` or `flutter build` command from `config/variants/*.seed.json`; preview-only, no files are changed
- `export-white-label-color-tokens.ps1`: validates `config/white-label-color-tokens.seed.json` and writes local JSON, Dart, and CSS color-token exports under ignored `build/white_label_tokens/`

Native runtime and release helpers remain local-only. They do not create a
trusted-signed public release, `MSIX`, store submission, or deploy hook.
