# Scripts

This folder is for non-destructive local helpers only.

Current helpers:

- `validate-seed.ps1`: checks the public Android/Windows scaffold, shared packages, and JSON config seeds
- `bootstrap-workspace.ps1`: runs `flutter pub get` across the clean-room packages and available host entrypoints; pass `-OfflinePubGet` when an old Flutter/Dart pub advisory fetch breaks online dependency resolution but the local package cache is already populated
- `run-tests.ps1`: bootstraps the workspace and runs the shared shell widget tests; accepts `-OfflinePubGet` and forwards it to bootstrap
- `run-operator-fixture-smoke.ps1`: starts the local operator API fixture on a smoke-only port, checks session/profile/apps/support/error-mode responses, then stops the fixture; pass `-Port` to avoid local or CI collisions
- `bootstrap-local.ps1`: copies example config seeds into `config/local/` without touching production paths unless explicitly forced
- `prepare-oss-import.ps1`: runs the source-import tests and safe importer against a temporary snapshot/stage pair; rejects staging inside this public repo
- `prepare-source-release.ps1`: creates a source-only archive proof manifest with commit SHA, SHA-256, and explicit no-APK/no-EXE/no-store/no-signing flags
- `render-source-release-notes.ps1`: renders a source-only GitHub Release body from a `prepare-source-release.ps1` proof manifest and refuses manifests that do not preserve source-only honesty flags
- `print-build-variant-command.ps1`: prints a PowerShell `flutter run` or `flutter build` command from `config/variants/*.seed.json`; preview-only, no files are changed
- `export-white-label-color-tokens.ps1`: validates `config/white-label-color-tokens.seed.json` and writes local JSON, Dart, and CSS color-token exports under ignored `build/white_label_tokens/`

Native runtime and release helpers remain local-only. They do not create a
trusted-signed public release, `MSIX`, store submission, or deploy hook.
