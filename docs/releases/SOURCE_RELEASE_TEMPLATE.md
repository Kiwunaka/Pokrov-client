# Source Release Template

Use this body for GitHub source-only releases.

## Source Reference

- Tag:
- Commit SHA:
- Commit date:
- Source archive SHA-256:
- Source proof manifest:
- Verification date:

## Included

- TBD

## Not Included

- No APK or EXE binaries.
- No store release.
- No trusted Windows signing claim.
- No official POKROV backend, billing, admin, deployment, signing, or private
  release evidence.

## Known Limitations

- TBD

## Verification

```powershell
python -m pytest tests
powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1 -Source .
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-source-release.ps1 `
  -Tag <tag> `
  -Ref refs/tags/<tag> `
  -RequireTag
```

## Release Honesty

This is a source-only release. It does not imply an official binary, store
listing, trusted signing, official POKROV service operation, or production
readiness unless those claims are backed by separate public evidence.
