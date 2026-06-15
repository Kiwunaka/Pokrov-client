# Troubleshooting

Use this page when a source checkout, dependency bootstrap, Android host,
Windows host, or clean-clone proof fails. Keep reports public-safe: never paste
secrets, tokens, QR payloads, subscription URLs, personal connection links,
signing material, private backend details, or private file paths with usernames
you do not want public.

## First Check

Run the read-only contributor doctor from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1
```

For build issues, include redacted JSON output:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Json
```

If you are checking docs only or a CI source-boundary lane that intentionally
does not install Flutter/Dart, use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -SkipCommandChecks -Json
```

The doctor is diagnostic only. It does not install dependencies, run
`flutter pub get`, build APK/EXE artifacts, fetch runtime binaries, copy local
config, sign anything, or publish anything.

## Decision Tree

### PowerShell refuses to run scripts

Use `-ExecutionPolicy Bypass -File` for repository scripts:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1
```

Do not change global execution policy just to build this repository.

### Missing `git`, `python`, `flutter`, or `dart`

Run the doctor without `-SkipCommandChecks`. Install or repair only the missing
toolchain on your workstation, then open a new terminal so `PATH` refreshes.
For source import and docs-only work, Flutter/Dart may be unnecessary; for
Android or Windows app work they are expected.

### Dependency bootstrap fails

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-workspace.ps1
```

If network dependency resolution is unavailable but your local package cache is
already populated, try:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1 -OfflinePubGet
```

Do not commit generated package caches, local SDK paths, or machine-specific
files.

### Android host fails

Check Android Studio or Android SDK/JDK setup first. The public source tree
contains the Android host and Gradle wrapper. Android native Gradle unit tests
can run in the source-only stub lane without private runtime artifacts:

Useful checks:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Json
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\run-android-native-tests.ps1 -SourceOnly
```

The source-only stub lane does not fetch or commit libcore.aar and does not
prove APK, store, trusted signing, or runtime readiness. Only run Android
Gradle runtime-backed tests after fetching local runtime artifacts as described
in [Build from source](BUILD_FROM_SOURCE.md).

### Windows host fails

Check Visual Studio Desktop development workload and CMake availability. The
public source tree contains the Windows host CMake entrypoint, but Windows
runtime smoke needs local-only runtime artifacts and does not prove trusted
signing, installer readiness, or store readiness.

Start with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\doctor.ps1 -Json
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
```

### Clean-clone or source-boundary proof fails

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1 -SkipFlutterTests
```

Failures here usually mean a required public file is missing, a private file was
accidentally referenced, or source-import policy rejected a path. Keep fixes in
the public repo boundary; do not point the source-only client at private POKROV
backend files, signing material, private release artifacts, or operator
runbooks.

## Before Opening A Build Issue

Include:

- commit or tag
- platform: Android, Windows, or repository setup
- product track: Personal Key / Community Client, Operator / Company Client,
  Official POKROV Service Mode, or docs/process
- exact command
- redacted `scripts\doctor.ps1 -Json` output
- whether a clean clone required private files

Do not include:

- QR payloads
- subscription URLs
- private keys or tokens
- personal connection links
- signing files
- private backend endpoints or private operator data

Security vulnerabilities do not belong in public build issues. Use
[SECURITY.md](../SECURITY.md) instead.
