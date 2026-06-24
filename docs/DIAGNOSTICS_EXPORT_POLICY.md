# Diagnostics Export Policy

This repository treats diagnostics export as a privacy-first source feature.
The source of truth is
[`config/diagnostics-export-policy.seed.json`](../config/diagnostics-export-policy.seed.json).

## Defaults

- diagnostics export is local-only
- export actions must be user-initiated
- no background upload is allowed
- no raw logs by default
- clipboard diagnostics are redacted before copy
- support ticket diagnostics attachments are redacted before send

## Allowed Surfaces

Current public source surfaces:

- support diagnostics copy/export from the support preview
- support ticket diagnostics attachment
- contributor doctor redacted JSON for build issues

Adding a new diagnostics or log export surface requires updating the seed file,
this document, tests, changelog, and source-readiness notes in the same PR.

## Forbidden Payloads

Diagnostics exports must not include:

- raw configs
- subscription URLs
- proxy links
- tokens, secrets, private keys, or signing material
- WireGuard private material
- WARP private material
- private backend details

Safe exports should use the shared redactor and should prefer allowlisted keys
over broad object serialization.

## Release Boundary

This policy is source-only. It does not claim APK, EXE, store release, trusted
signing, runtime connectivity, remote support upload, or production support
readiness.
