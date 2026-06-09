# Dependency License Audit

This file tracks dependency and asset license review before the client source
snapshot becomes public.

## Status

Current status: first source snapshot imported, transitive dependency inventory
still pending.

The table below records the first direct dependency pass. Exact transitive
dependency output should be added after a clean public bootstrap.

| Package or asset | Version | Use | License | Bundled | GPL compatible | Action |
| --- | --- | --- | --- | --- | --- | --- |
| Flutter SDK | project SDK | app framework | BSD-3-Clause | no | yes | verify installed SDK in CI |
| Dart SDK | `>=3.0.0 <4.0.0` | language/runtime tooling | BSD-3-Clause | no | yes | verify installed SDK in CI |
| `path_provider` | `^2.1.5` | app support paths | BSD-3-Clause | no | yes | confirm transitive licenses |
| `url_launcher` | `^6.3.1` | external handoff links | BSD-3-Clause | no | yes | confirm transitive licenses |
| `ffi` | `^2.1.3` | desktop runtime FFI | BSD-3-Clause | no | yes | confirm transitive licenses |
| `path` | `^1.9.0` | path operations | BSD-3-Clause | no | yes | confirm transitive licenses |
| `win32` | `^5.10.1` | Windows interop | BSD-3-Clause | no | yes | confirm transitive licenses |
| `tray_manager` | `^0.5.2` | Windows tray integration | MIT | no | yes | confirm transitive licenses |
| `window_manager` | `^0.5.1` | Windows window controls | MIT | no | yes | confirm transitive licenses |
| `flutter_lints` | `^4.0.0` | linting | BSD-3-Clause | no | yes | dev dependency |
| Gradle wrapper | wrapper from source snapshot | Android build bootstrap | Apache-2.0 | wrapper jar committed | yes | verify checksum during CI setup |
| POKROV client brand PNGs | source snapshot | app shell identity | governed by `BRAND.md` | yes | restricted trademark use | keep official-build boundary |
| `hiddify/hiddify-core` runtime artifacts | `v3.1.8` seed | runtime bridge testing | see upstream project | downloaded, not committed | pending | verify before public binary release |

## Review Checklist

- Flutter and Dart packages.
- Android native dependencies.
- Windows native dependencies.
- Runtime binaries.
- Icons and logos.
- Fonts.
- Generated images and other generated assets.
- Build tools and GitHub Actions.

## Rules

- Do not add unknown-license assets.
- Do not add private or generated media without source notes.
- Do not bundle GPL-incompatible dependencies into public client releases.
- Keep official POKROV brand assets governed by `BRAND.md`.
