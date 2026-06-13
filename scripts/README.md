# Scripts

This folder is for non-destructive local helpers only.

Current helpers:

- `validate-seed.ps1`: checks the public Android/Windows scaffold, shared packages, and JSON config seeds
- `bootstrap-workspace.ps1`: runs `flutter pub get` across the clean-room packages and available host entrypoints; pass `-OfflinePubGet` when an old Flutter/Dart pub advisory fetch breaks online dependency resolution but the local package cache is already populated
- `run-tests.ps1`: bootstraps the workspace and runs the shared shell widget tests; accepts `-OfflinePubGet` and forwards it to bootstrap
- `run-operator-fixture-smoke.ps1`: starts the local operator API fixture on a smoke-only port, checks session/profile/apps/support/error-mode responses, then stops the fixture
- `bootstrap-local.ps1`: copies example config seeds into `config/local/` without touching production paths unless explicitly forced
- `prepare-oss-import.ps1`: runs the source-import tests and safe importer against a temporary snapshot/stage pair; rejects staging inside this public repo

Native runtime and release helpers remain local-only. They do not create a
trusted-signed public release, `MSIX`, store submission, or deploy hook.
