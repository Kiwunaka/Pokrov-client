# POKROV Runtime Engine

This package carries the non-UI runtime lane for the Wave 7 next-client program.

Current scope:

- desktop `libcore` FFI bootstrap for `Windows` and `macOS`
- artifact discovery from local host folders or `POKROV_LIBCORE_ROOT`
- staging and starting a managed profile payload once a real config exists
- mobile artifact readiness summaries for `Android` and `iOS`
- source-only artifact metadata through
  `config/runtime-artifacts.seed.json`; downloaded `libcore` archives are local
  test material unless a separate public binary review records exact SHA-256
  values and redistribution notes

Current limits:

- Android and iOS still need their full host-native bridge lane
- Apple signing, notarization, and store submission stay outside this package
- the package proves runtime wiring, not production rollout by itself
- source-only releases do not ship APK/EXE files or runtime binaries
