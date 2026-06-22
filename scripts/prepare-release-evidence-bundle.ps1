param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^v\d+\.\d+\.\d+-source$')]
  [string]$Tag,

  [Parameter(Mandatory = $true)]
  [string]$PreflightSummaryPath,

  [string]$RulesetReportPath = "",
  [string]$OutDir = "",
  [switch]$IncludeGitHubRulesetReport
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$defaultOutputDir = "build\release-evidence"

function Resolve-RepoPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }
  return Join-Path $root $Path
}

function Get-InputFingerprint {
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

function Assert-SourceOnlySummary {
  param([Parameter(Mandatory = $true)][object]$Summary)

  foreach ($flag in @(
      "source_only",
      "no_apk",
      "no_exe",
      "no_store_release",
      "no_trusted_signing_claim"
    )) {
    if ($Summary.$flag -ne $true) {
      throw "Release evidence refused preflight summary with $flag not true."
    }
  }

  if ([int]$Summary.forbidden_file_count -ne 0) {
    throw "Release evidence refused preflight summary with forbidden_file_count=$($Summary.forbidden_file_count)."
  }

  if ($Summary.windows_bundle_verifier_ok -ne $true) {
    throw "Release evidence refused preflight summary with windows_bundle_verifier_ok not true."
  }

  if ([string]::IsNullOrWhiteSpace([string]$Summary.windows_bundle_verifier_summary)) {
    throw "Release evidence refused preflight summary without windows_bundle_verifier_summary."
  }

  $artifactFingerprints = $null
  $artifactFingerprintProperty = $Summary.PSObject.Properties["artifact_fingerprints"]
  if ($null -ne $artifactFingerprintProperty) {
    $artifactFingerprints = $artifactFingerprintProperty.Value
  }
  foreach ($fingerprintName in @(
      "proof_manifest",
      "release_notes",
      "source_archive",
      "windows_bundle_verifier_summary"
    )) {
    $fingerprintEntry = $null
    if ($null -ne $artifactFingerprints) {
      $fingerprintProperty = $artifactFingerprints.PSObject.Properties[$fingerprintName]
      if ($null -ne $fingerprintProperty) {
        $fingerprintEntry = $fingerprintProperty.Value
      }
    }
    if (
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.path) -or
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.sha256) -or
      [string]$fingerprintEntry.sha256 -notmatch "^[0-9a-fA-F]{64}$"
    ) {
      throw "Release evidence refused preflight summary is missing artifact fingerprints."
    }
  }
}

Push-Location $root
try {
  $resolvedPreflightSummaryPath = Resolve-RepoPath -Path $PreflightSummaryPath
  if (-not (Test-Path -LiteralPath $resolvedPreflightSummaryPath -PathType Leaf)) {
    throw "Preflight summary not found: $resolvedPreflightSummaryPath"
  }

  if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $root (Join-Path $defaultOutputDir $Tag)
  } else {
    $OutDir = Resolve-RepoPath -Path $OutDir
  }

  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
  $rulesetReportOutPath = Join-Path $OutDir "$Tag-github-ruleset-report.json"
  $bundlePath = Join-Path $OutDir "$Tag-release-evidence.json"

  $preflightSummary = Get-Content -Raw -LiteralPath $resolvedPreflightSummaryPath | ConvertFrom-Json
  Assert-SourceOnlySummary -Summary $preflightSummary

  $resolvedRulesetReportPath = ""
  $rulesetReport = $null
  if ($IncludeGitHubRulesetReport) {
    $reportJson = powershell -ExecutionPolicy Bypass -File .\scripts\check-github-ruleset.ps1 -ReportOnly -Json
    if ($LASTEXITCODE -ne 0) {
      throw "check-github-ruleset.ps1 -ReportOnly -Json failed"
    }
    [System.IO.File]::WriteAllText($rulesetReportOutPath, $reportJson, [System.Text.UTF8Encoding]::new($false))
    $resolvedRulesetReportPath = $rulesetReportOutPath
    $rulesetReport = $reportJson | ConvertFrom-Json
  } elseif (-not [string]::IsNullOrWhiteSpace($RulesetReportPath)) {
    $resolvedRulesetReportPath = Resolve-RepoPath -Path $RulesetReportPath
    if (-not (Test-Path -LiteralPath $resolvedRulesetReportPath -PathType Leaf)) {
      throw "Ruleset report not found: $resolvedRulesetReportPath"
    }
    $rulesetReport = Get-Content -Raw -LiteralPath $resolvedRulesetReportPath | ConvertFrom-Json
  }

  $gitStatus = git status --short
  if ($LASTEXITCODE -ne 0) {
    throw "git status failed"
  }
  $commitSha = git rev-parse HEAD
  if ($LASTEXITCODE -ne 0) {
    throw "git rev-parse HEAD failed"
  }

  $rulesetOk = $null
  $rulesetClaimAllowed = $false
  if ($null -ne $rulesetReport) {
    $rulesetOk = [bool]$rulesetReport.ok
    $rulesetClaimAllowed = [bool]$rulesetReport.ok
  }

  $bundle = [ordered]@{
    schema_version = 1
    tag = $Tag
    commit_sha = ($commitSha | Select-Object -First 1)
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    dirty_worktree = (-not [string]::IsNullOrWhiteSpace(($gitStatus -join "`n")))
    source_only = [bool]$preflightSummary.source_only
    no_apk = [bool]$preflightSummary.no_apk
    no_exe = [bool]$preflightSummary.no_exe
    no_store_release = [bool]$preflightSummary.no_store_release
    no_trusted_signing_claim = [bool]$preflightSummary.no_trusted_signing_claim
    forbidden_file_count = [int]$preflightSummary.forbidden_file_count
    windows_bundle_verifier_ok = [bool]$preflightSummary.windows_bundle_verifier_ok
    windows_bundle_verifier_summary = $preflightSummary.windows_bundle_verifier_summary
    preflight_summary = $resolvedPreflightSummaryPath
    proof_manifest = $preflightSummary.proof_manifest
    release_notes = $preflightSummary.release_notes
    source_archive_sha256 = $preflightSummary.source_archive_sha256
    input_fingerprints = [ordered]@{
      preflight_summary = Get-InputFingerprint -Path $resolvedPreflightSummaryPath
    }
    preflight_artifact_fingerprints = $preflightSummary.artifact_fingerprints
    github_ruleset_report = $resolvedRulesetReportPath
    github_ruleset_ok = $rulesetOk
    github_enforcement_claim_allowed = $rulesetClaimAllowed
    release_boundary = [ordered]@{
      ships_apk = $false
      ships_exe = $false
      store_release = $false
      trusted_signing_claim = $false
      official_binary_claim = $false
    }
    maintainer_next_steps = @(
      "Review rendered release notes before publication.",
      "Attach or archive the source proof manifest.",
      "Do not claim remote GitHub enforcement unless github_ruleset_ok is true.",
      "Do not claim APK, EXE, store release, trusted signing, or official binary readiness from this source evidence bundle."
    )
  }

  $bundleJson = $bundle | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($bundlePath, $bundleJson, [System.Text.UTF8Encoding]::new($false))

  Write-Host "Release evidence bundle written:" -ForegroundColor Green
  Write-Host $bundlePath
} finally {
  Pop-Location
}
