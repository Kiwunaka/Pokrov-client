param(
  [Parameter(Mandatory = $true)]
  [string]$ManifestPath,

  [string]$OutFile = "",

  [string[]]$Included = @(),

  [string[]]$KnownLimitations = @()
)

$ErrorActionPreference = "Stop"

function Assert-ManifestFlag {
  param(
    [Parameter(Mandatory = $true)]
    [object]$Proof,
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if ($Proof.$Name -ne $true) {
    throw "Source proof manifest must set $Name=true."
  }
}

function Format-List {
  param([string[]]$Items)

  return (($Items | ForEach-Object { "- $_" }) -join [Environment]::NewLine)
}

$resolvedManifestPath = (Resolve-Path -LiteralPath $ManifestPath).Path
$proof = Get-Content -Raw -LiteralPath $resolvedManifestPath | ConvertFrom-Json

if ($proof.tag -notmatch '^v\d+\.\d+\.\d+-source$') {
  throw "Source release notes require a vX.Y.Z-source tag."
}

if ($proof.commit_sha -notmatch '^[0-9a-f]{40}$') {
  throw "Source proof manifest must include a 40-character commit_sha."
}

if ($proof.source_archive_sha256 -notmatch '^[0-9a-f]{64}$') {
  throw "Source proof manifest must include a 64-character source_archive_sha256."
}

foreach ($flag in @(
    "source_only",
    "no_apk",
    "no_exe",
    "no_store_release",
    "no_trusted_signing_claim"
  )) {
  Assert-ManifestFlag -Proof $proof -Name $flag
}

if ($proof.forbidden_file_count -ne 0) {
  throw "Source proof manifest must have forbidden_file_count=0."
}

if ($Included.Count -eq 0) {
  $Included = @(
    "Source snapshot for $($proof.tag) at commit $($proof.commit_sha).",
    "Source archive $($proof.source_archive) with SHA-256 $($proof.source_archive_sha256).",
    "Source proof manifest generated from scripts/prepare-source-release.ps1."
  )
}

if ($KnownLimitations.Count -eq 0) {
  $KnownLimitations = @(
    "No APK, EXE, installer, store listing, or trusted-signed binary is included.",
    "Community and operator builds remain source builds unless a downstream maintainer publishes separate artifacts.",
    "Official POKROV service operation requires separate public release evidence."
  )
}

$tagObjectSha = $proof.tag_object_sha
if ([string]::IsNullOrWhiteSpace($tagObjectSha)) {
  $tagObjectSha = "not recorded; rerun prepare-source-release.ps1 with -RequireTag for an annotated tag proof"
}

$codeFence = [string]::new([char]96, 3)

$body = @"
# $($proof.tag)

## Source Reference

- Tag: $($proof.tag)
- Tag object SHA: $tagObjectSha
- Commit SHA: $($proof.commit_sha)
- Commit date: $($proof.commit_date)
- Source archive SHA-256: $($proof.source_archive_sha256)
- Source proof manifest: $resolvedManifestPath
- Verification date: $($proof.verification_date)

## Included

$(Format-List -Items $Included)

## Not Included

- No APK or EXE binaries.
- No store release.
- No trusted Windows signing claim.
- No official POKROV backend, billing, admin, deployment, signing, or private release evidence.

## Known Limitations

$(Format-List -Items $KnownLimitations)

## Verification

$($codeFence)powershell
python -m pytest tests
powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\verify-clean-clone.ps1 -Source .
powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-source-release.ps1 -Tag $($proof.tag) -Ref refs/tags/$($proof.tag) -RequireTag
$codeFence

## Release Honesty

This is a source-only release. It does not imply an official binary, store listing, trusted signing, official POKROV service operation, or production readiness unless those claims are backed by separate public evidence.
"@

if ([string]::IsNullOrWhiteSpace($OutFile)) {
  Write-Output $body
} else {
  $outParent = Split-Path -Parent $OutFile
  if (-not [string]::IsNullOrWhiteSpace($outParent)) {
    New-Item -ItemType Directory -Path $outParent -Force | Out-Null
  }
  $body | Set-Content -LiteralPath $OutFile -Encoding UTF8
  Write-Host "Source release notes written: $OutFile" -ForegroundColor Green
}
