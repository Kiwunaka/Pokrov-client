# Dependency License Audit

This file tracks dependency and asset license review before source or binary
releases.

## Status

Current status: first source snapshot imported and the public source-tree
dependency inventory is recorded for source release review. The machine-readable
source inventory lives in
[`config/dependency-license-inventory.seed.json`](../config/dependency-license-inventory.seed.json)
and is verified against locally generated `pubspec.lock` files when present by
[`tests/test_release_provenance.py`](../tests/test_release_provenance.py).

The table below records the first direct dependency pass. The inventory file is
the source-release gate for exact transitive Dart/Flutter package names and
versions.

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
| `mobile_scanner` | `^7.2.0` | Android QR camera scanning | BSD-3-Clause | no | yes | Android camera import |
| `camera` | `^0.11.0` | Windows QR camera capture abstraction | BSD-3-Clause | no | yes | Windows QR import |
| `camera_windows` | `^0.2.6+2` | Windows camera plugin | BSD-3-Clause | no | yes | used instead of `camera_desktop` because current Dart SDK is below 3.11 |
| `image` | `^4.5.4` | decode captured camera frames before QR parsing | Apache-2.0 | no | yes | Windows QR import |
| `zxing2` | `^0.2.4` | decode QR payloads from captured frames | Apache-2.0 | no | yes | Windows QR import |
| `flutter_lints` | `^4.0.0` | linting | BSD-3-Clause | no | yes | dev dependency |
| `AvenCores/goida-vpn-configs` | catalog candidate | optional third-party public config feeds | GPL-3.0 | no | yes | disabled by default; attribution required |
| Gradle wrapper | wrapper from source snapshot | Android build bootstrap | Apache-2.0 | wrapper jar committed | yes | verify checksum during CI setup |
| POKROV client brand PNGs | source snapshot | app shell identity | governed by `BRAND.md` | yes | restricted trademark use | keep official-build boundary |
| `hiddify/hiddify-core` runtime artifacts | `v3.1.8` seed | runtime bridge testing | see upstream project | downloaded, not committed | pending | manifest records pending license/binary review and `PENDING_PUBLIC_BINARY_REVIEW`; replace with exact SHA-256 values only after public binary review |

## Current Transitive Inventory Evidence

- Inventory date: `2026-06-13`.
- Source: seven local `pubspec.lock` files across Android, Windows, and
  shared packages.
- Current inventory size: 93 unique Dart/Flutter packages.
- Allowed source-release license families: `MIT`, `BSD-3-Clause`,
  `Apache-2.0`, repository `GPL-3.0`, and Flutter SDK BSD-style licensing.
- Required verification:
  `python -m pytest tests/test_release_provenance.py`.

This is source-release evidence only. Public binary releases still require a
fresh native/runtime review for bundled runtime artifacts, platform build
outputs, signing material, store metadata, and installer contents.

Runtime artifact metadata lives in
[`config/runtime-artifacts.seed.json`](../config/runtime-artifacts.seed.json).
The source-only release lane may document local fetch instructions, but it must
not claim archive hashes, redistribution clearance, APK/EXE delivery, or bundled
runtime safety until that manifest is updated from pending review to recorded
binary evidence.

## Generated Asset Provenance

Generated and brand PNG provenance is tracked in
[`config/generated-assets.seed.json`](../config/generated-assets.seed.json).

- README and diagram raster artwork is generated artwork with prompts and
  release-scope notes in [`assets/IMAGEGEN_PROMPTS.md`](../assets/IMAGEGEN_PROMPTS.md).
- `assets/branding/pokrov-mark.png` is an official brand mark governed by
  [`BRAND.md`](../BRAND.md); forks may use the code license but must not reuse
  the official mark to imply an official POKROV build.
- Every `assets/**/*.png` file must be listed in the generated asset inventory
  before a source release tag.

## Review Checklist

- Flutter and Dart packages.
- Android native dependencies for binary releases.
- Windows native dependencies for binary releases.
- Runtime binaries for binary releases.
- Icons and logos.
- Fonts.
- Generated images and other generated assets.
- Build tools and GitHub Actions.

## Rules

- Do not add unknown-license assets.
- Do not add private or generated media without source notes.
- Do not bundle GPL-incompatible dependencies into public client releases.
- Keep official POKROV brand assets governed by `BRAND.md`.
