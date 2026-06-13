# Windows Shell Seed

Current responsibility:

- Windows-specific Flutter host entry point for the shared open-client seed shell
- desktop FFI runtime integration through `pokrov_runtime_engine`
- local host-runtime sync at `windows/runner/resources/runtime`
- neutral open-source Windows runner metadata that operators can override at build time
- local release-build verification through the shared source checks

Current local truth:

- `flutter build windows --release` produces a runnable source-built bundle with `open_client_windows.exe` and `libcore.dll`
- the shared shell keeps local runtime controls out of the first layer and uses one-tap connect from `Protection` on Windows
- generated binaries are not official public release artifacts unless a downstream maintainer completes their own review, signing, and release process

Deferred responsibility:

- Windows process-picker integration for selected-apps mode
- elevated lifecycle hardening for the real full-tunnel and selected-apps paths
- trusted code signing, installer or `MSIX` publication, and updater wiring
- public download hosting, Microsoft Store submission, and product cutover
