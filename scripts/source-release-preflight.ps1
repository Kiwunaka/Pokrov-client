param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^v\d+\.\d+\.\d+-source$')]
  [string]$Tag,

  [string]$Ref = "HEAD",
  [string]$OutDir = "",
  [switch]$RequireTag,
  [switch]$AllowDirty,
  [switch]$SkipTestCommands,
  [switch]$SkipFlutterTests
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $root "build\source-release-preflight\$Tag"
}

function Assert-LastExitCode {
  param([string]$Message)

  if ($LASTEXITCODE -ne 0) {
    throw $Message
  }
}

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
  )

  Write-Host "==> $Name" -ForegroundColor Cyan
  & $ScriptBlock
}

function Get-ArtifactFingerprint {
  param([Parameter(Mandatory = $true)][string]$Path)

  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  $stream = [System.IO.File]::OpenRead($resolvedPath)
  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try {
    $hashBytes = $sha256.ComputeHash($stream)
    $hash = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
  } finally {
    $sha256.Dispose()
    $stream.Dispose()
  }
  return [ordered]@{
    path = $resolvedPath
    sha256 = $hash
  }
}

function Assert-SourceOnlyProof {
  param([Parameter(Mandatory = $true)][object]$Proof)

  foreach ($flag in @(
      "source_only",
      "no_apk",
      "no_exe",
      "no_store_release",
      "no_trusted_signing_claim"
    )) {
    if ($Proof.$flag -ne $true) {
      throw "Source preflight refused proof manifest with $flag not true."
    }
  }

  if ($Proof.forbidden_file_count -ne 0) {
    throw "Source preflight refused proof manifest with forbidden_file_count=$($Proof.forbidden_file_count)."
  }
}

Push-Location $root
try {
  $resolvedOutDir = $OutDir
  if (-not [System.IO.Path]::IsPathRooted($resolvedOutDir)) {
    $resolvedOutDir = Join-Path $root $resolvedOutDir
  }

  $proofDir = Join-Path $resolvedOutDir "proof"
  $manifestPath = Join-Path $proofDir "$Tag-source-proof.json"
  $releaseNotesPath = Join-Path $resolvedOutDir "$Tag-release-notes.md"
  $summaryPath = Join-Path $resolvedOutDir "$Tag-source-preflight.json"
  $windowsBundleVerifierSummaryPath = Join-Path $root "build\windows-bundle-verifier\windows-bundle-verifier.json"

  New-Item -ItemType Directory -Path $resolvedOutDir -Force | Out-Null

  if ($SkipTestCommands) {
    Write-Host "Skipping test commands by request. Use this only for local/CI smoke tests, not for publishing." -ForegroundColor Yellow
  } else {
    Invoke-Step "Run Python tests" {
      python -m pytest tests
      Assert-LastExitCode "python -m pytest tests failed"
    }

    Invoke-Step "Validate public seed/config contract" {
      powershell -ExecutionPolicy Bypass -File .\scripts\validate-seed.ps1
      Assert-LastExitCode "validate-seed.ps1 failed"
    }

    Invoke-Step "Verify clean clone source boundary" {
      $verifyArgs = @(
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        ".\scripts\verify-clean-clone.ps1",
        "-Source",
        "."
      )
      if ($SkipFlutterTests) {
        $verifyArgs += "-SkipFlutterTests"
      }

      powershell @verifyArgs
      Assert-LastExitCode "verify-clean-clone.ps1 failed"
    }

    if ($SkipFlutterTests) {
      Write-Host "Skipping workspace Flutter test command by request." -ForegroundColor Yellow
    } else {
      Invoke-Step "Run workspace tests" {
        powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
        Assert-LastExitCode "run-tests.ps1 failed"
      }
    }
  }

  Invoke-Step "Verify Windows bundle source boundary" {
    powershell -ExecutionPolicy Bypass -File .\scripts\verify-windows-bundle.ps1
    Assert-LastExitCode "verify-windows-bundle.ps1 failed"
  }

  Invoke-Step "Prepare source-only proof manifest" {
    $prepareArgs = @(
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      ".\scripts\prepare-source-release.ps1",
      "-Tag",
      $Tag,
      "-Ref",
      $Ref,
      "-OutDir",
      $proofDir
    )
    if ($RequireTag) {
      $prepareArgs += "-RequireTag"
    }
    if ($AllowDirty) {
      $prepareArgs += "-AllowDirty"
    }

    powershell @prepareArgs
    Assert-LastExitCode "prepare-source-release.ps1 failed"
  }

  Invoke-Step "Render source-only release notes" {
    powershell -ExecutionPolicy Bypass -File .\scripts\render-source-release-notes.ps1 `
      -ManifestPath $manifestPath `
      -ManifestLabel (Split-Path -Leaf $manifestPath) `
      -OutFile $releaseNotesPath
    Assert-LastExitCode "render-source-release-notes.ps1 failed"
  }

  Invoke-Step "Check source release copy boundaries" {
    powershell -ExecutionPolicy Bypass -File .\scripts\check-source-release-copy.ps1 `
      -ReleaseNotesPath $releaseNotesPath
    Assert-LastExitCode "check-source-release-copy.ps1 failed"
  }

  $proof = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
  $windowsBundleVerifier = Get-Content -Raw -LiteralPath $windowsBundleVerifierSummaryPath | ConvertFrom-Json
  Assert-SourceOnlyProof -Proof $proof
  $resolvedRefCommitSha = git rev-parse "${Ref}^{commit}"
  Assert-LastExitCode "git rev-parse ${Ref}^{commit} failed"
  $refCommitSha = [string]($resolvedRefCommitSha | Select-Object -First 1)
  if ($refCommitSha -notmatch "^[0-9a-fA-F]{40}$") {
    throw "Source preflight refused resolved ref without a 40-character commit SHA."
  }
  if ([string]$proof.commit_sha -ne $refCommitSha) {
    throw "Source preflight refused proof manifest: proof manifest commit SHA does not match resolved ref."
  }
  if ($windowsBundleVerifier.windows_bundle_ok -ne $true) {
    throw "Source preflight refused Windows bundle verifier summary with windows_bundle_ok not true."
  }

  $summary = [ordered]@{
    schema_version = 1
    tag = $Tag
    ref = $Ref
    require_tag = [bool]$RequireTag
    allow_dirty = [bool]$AllowDirty
    skipped_test_commands = [bool]$SkipTestCommands
    skipped_flutter_tests = [bool]$SkipFlutterTests
    source_only = [bool]$proof.source_only
    no_apk = [bool]$proof.no_apk
    no_exe = [bool]$proof.no_exe
    no_store_release = [bool]$proof.no_store_release
    no_trusted_signing_claim = [bool]$proof.no_trusted_signing_claim
    forbidden_file_count = [int]$proof.forbidden_file_count
    windows_bundle_verifier_ok = [bool]$windowsBundleVerifier.windows_bundle_ok
    windows_bundle_verifier_summary = $windowsBundleVerifierSummaryPath
    tag_object_sha = $proof.tag_object_sha
    ref_commit_sha = $refCommitSha
    commit_sha = $proof.commit_sha
    source_archive = (Join-Path $proofDir $proof.source_archive)
    source_archive_sha256 = $proof.source_archive_sha256
    proof_manifest = $manifestPath
    release_notes = $releaseNotesPath
    artifact_fingerprints = [ordered]@{
      proof_manifest = Get-ArtifactFingerprint -Path $manifestPath
      release_notes = Get-ArtifactFingerprint -Path $releaseNotesPath
      source_archive = Get-ArtifactFingerprint -Path (Join-Path $proofDir $proof.source_archive)
      windows_bundle_verifier_summary = Get-ArtifactFingerprint -Path $windowsBundleVerifierSummaryPath
    }
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
  }

  $summary | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

  Write-Host "Source release preflight completed:" -ForegroundColor Green
  Write-Host "Summary: $summaryPath"
  Write-Host "Proof manifest: $manifestPath"
  Write-Host "Release notes: $releaseNotesPath"
} finally {
  Pop-Location
}
