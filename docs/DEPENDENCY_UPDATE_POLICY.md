# Dependency Update Policy

This repository uses Dependabot for public source dependency visibility. A
Dependabot pull request is a review request, not an automatic approval to merge
or release.

The machine-readable policy is
[`config/dependabot-policy.seed.json`](../config/dependabot-policy.seed.json).
The active Dependabot configuration is
[`.github/dependabot.yml`](../.github/dependabot.yml).

## Covered Ecosystems

Dependabot watches:

- GitHub Actions workflow dependencies at the repository root.
- Dart/Flutter `pub` dependencies for the Android shell.
- Dart/Flutter `pub` dependencies for the Windows shell.
- Dart/Flutter `pub` dependencies for shared packages:
  - `packages/app_shell`
  - `packages/core_domain`
  - `packages/platform_contracts`
  - `packages/runtime_engine`
  - `packages/support_context`

Updates are scheduled weekly and have bounded open pull request limits so
source-maintenance work stays reviewable.

## Review Rules

Before merging a dependency update:

1. Confirm the changed package is still compatible with the repository license
   policy in [Dependency license audit](DEPENDENCY_LICENSE_AUDIT.md).
2. Update `config/dependency-license-inventory.seed.json` when `pubspec.lock`
   contents change.
3. Run the Python contract tests.
4. Run the Flutter workspace tests for affected packages or hosts.
5. Preserve source-only release wording: dependency updates do not imply APK,
   EXE, store, trusted-signing, or official binary readiness.
6. Keep runtime binaries separate. Updating Flutter/Dart dependencies does not
   approve `libcore` archives or other local-only runtime artifacts.

## Labels And Triage

Dependabot pull requests use the `dependencies` label plus a route-specific
label such as `android`, `windows`, `runtime`, or `source-boundary`.

Security-sensitive dependency findings still follow [SECURITY.md](../SECURITY.md)
when they require private vulnerability details. Do not post exploit details,
private endpoints, account data, QR payloads, subscription URLs, signing
material, or private backend details in public dependency issues.

## Release Boundary

Dependency updates can improve source freshness, but they do not create a
source tag, binary release, signed installer, store submission, or official
POKROV build. Release notes must keep the same source-only claim boundaries as
[Release policy](RELEASE_POLICY.md).
