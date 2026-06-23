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

function Assert-ArtifactFingerprintIntegrity {
  param(
    [Parameter(Mandatory = $true)][object]$Fingerprint,
    [Parameter(Mandatory = $true)][string]$ExpectedPath,
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$ExpectedSha256 = ""
  )

  if ([string]::IsNullOrWhiteSpace($ExpectedPath)) {
    throw "Release evidence refused preflight summary with missing artifact path for $Name."
  }

  $resolvedExpectedPath = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path $ExpectedPath))
  $resolvedFingerprintPath = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path ([string]$Fingerprint.path)))
  if (-not $resolvedFingerprintPath.Equals($resolvedExpectedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Release evidence refused preflight summary with artifact fingerprint mismatch for $Name."
  }

  if (-not (Test-Path -LiteralPath $resolvedExpectedPath -PathType Leaf)) {
    throw "Release evidence refused preflight summary with artifact fingerprint mismatch for $Name."
  }

  $actualFingerprint = Get-InputFingerprint -Path $resolvedExpectedPath
  if ([string]$Fingerprint.sha256 -ne [string]$actualFingerprint.sha256) {
    throw "Release evidence refused preflight summary with artifact fingerprint mismatch for $Name."
  }

  if (
    -not [string]::IsNullOrWhiteSpace($ExpectedSha256) -and
    [string]$Fingerprint.sha256 -ne $ExpectedSha256
  ) {
    throw "Release evidence refused preflight summary with artifact fingerprint mismatch for $Name."
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

  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $artifactFingerprints.proof_manifest `
    -ExpectedPath ([string]$Summary.proof_manifest) `
    -Name "proof_manifest"
  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $artifactFingerprints.release_notes `
    -ExpectedPath ([string]$Summary.release_notes) `
    -Name "release_notes"
  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $artifactFingerprints.source_archive `
    -ExpectedPath ([string]$Summary.source_archive) `
    -ExpectedSha256 ([string]$Summary.source_archive_sha256) `
    -Name "source_archive"
  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $artifactFingerprints.windows_bundle_verifier_summary `
    -ExpectedPath ([string]$Summary.windows_bundle_verifier_summary) `
    -Name "windows_bundle_verifier_summary"
}

function Assert-RulesetReportShape {
  param([Parameter(Mandatory = $true)][object]$Report)

  if ([int]$Report.schema_version -ne 1) {
    throw "Release evidence refused ruleset report without schema_version 1."
  }

  if ($Report.read_only -ne $true) {
    throw "Release evidence refused ruleset report that is not read-only."
  }

  if ($null -eq $Report.PSObject.Properties["ok"]) {
    throw "Release evidence refused ruleset report without ok status."
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
  $currentCommitSha = [string]($commitSha | Select-Object -First 1)
  $preflightCommitSha = [string]$preflightSummary.commit_sha
  $preflightRefCommitSha = [string]$preflightSummary.ref_commit_sha
  if ($preflightCommitSha -notmatch "^[0-9a-fA-F]{40}$") {
    throw "Release evidence refused preflight summary without commit_sha."
  }
  if ($preflightRefCommitSha -notmatch "^[0-9a-fA-F]{40}$") {
    throw "Release evidence refused preflight summary without ref_commit_sha."
  }
  if ($preflightCommitSha -ne $currentCommitSha) {
    throw "Release evidence refused preflight summary: preflight commit SHA does not match current HEAD."
  }
  if ($preflightCommitSha -ne $preflightRefCommitSha) {
    throw "Release evidence refused preflight summary: preflight commit SHA does not match resolved ref commit SHA."
  }

  $rulesetOk = $null
  $rulesetClaimAllowed = $false
  if ($null -ne $rulesetReport) {
    Assert-RulesetReportShape -Report $rulesetReport
    $rulesetOk = [bool]$rulesetReport.ok
    $rulesetClaimAllowed = [bool]$rulesetReport.ok
  }

  $inputFingerprints = [ordered]@{
    preflight_summary = Get-InputFingerprint -Path $resolvedPreflightSummaryPath
  }
  if (-not [string]::IsNullOrWhiteSpace($resolvedRulesetReportPath)) {
    $inputFingerprints.github_ruleset_report = Get-InputFingerprint -Path $resolvedRulesetReportPath
  }

  $bundle = [ordered]@{
    schema_version = 1
    tag = $Tag
    commit_sha = $currentCommitSha
    preflight_commit_sha = $preflightCommitSha
    preflight_ref_commit_sha = $preflightRefCommitSha
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
    input_fingerprints = $inputFingerprints
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
