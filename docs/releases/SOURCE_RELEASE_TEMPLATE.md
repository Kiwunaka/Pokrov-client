# Source Release Template

Use this body for GitHub source-only releases.

`scripts/source-release-preflight.ps1` can run the local release gate, prepare
the source proof manifest, render the first GitHub Release draft, and write a
local preflight summary. Review the draft, then fill the exact feature status
and known limitations before publishing.

## Source Reference

- Tag:
- Tag object SHA:
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
$tag = "v0.3.0-source"
$preflight = Join-Path $env:TEMP "$tag-preflight"
powershell -ExecutionPolicy Bypass -File .\scripts\source-release-preflight.ps1 `
  -Tag $tag `
  -Ref "refs/tags/$tag" `
  -OutDir $preflight `
  -RequireTag
```

## Release Honesty

This is a source-only release. It does not imply an official binary, store
listing, trusted signing, official POKROV service operation, or production
readiness unless those claims are backed by separate public evidence.
