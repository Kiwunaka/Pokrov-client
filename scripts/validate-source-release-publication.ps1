param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^v\d+\.\d+\.\d+-source$')]
  [string]$Tag,

  [Parameter(Mandatory = $true)]
  [string]$EvidenceBundlePath,

  [Parameter(Mandatory = $true)]
  [string]$ReleaseNotesPath,

  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$defaultOutputDir = "build\source-release-publication"
$expectedRulesetRepository = "Kiwunaka/Pokrov-client"
$expectedRulesetBranch = "main"

function Resolve-RepoPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }
  return Join-Path $root $Path
}

function Assert-FlagTrue {
  param(
    [Parameter(Mandatory = $true)][object]$Payload,
    [Parameter(Mandatory = $true)][string]$Name
  )

  if ($Payload.$Name -ne $true) {
    throw "Publication dry-run refused evidence with $Name not true."
  }
}

function Assert-Contains {
  param(
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string]$Phrase,
    [Parameter(Mandatory = $true)][string]$Label
  )

  if ($Text.IndexOf($Phrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
    throw "$Label must include '$Phrase'."
  }
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

function Assert-InputFingerprintIntegrity {
  param(
    [Parameter(Mandatory = $true)][object]$Fingerprint,
    [Parameter(Mandatory = $true)][string]$Name
  )

  $resolvedFingerprintPath = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path ([string]$Fingerprint.path)))
  if (-not (Test-Path -LiteralPath $resolvedFingerprintPath -PathType Leaf)) {
    throw "Publication dry-run refused evidence bundle preflight summary fingerprint mismatch for $Name."
  }

  $actualFingerprint = Get-InputFingerprint -Path $resolvedFingerprintPath
  if ([string]$Fingerprint.sha256 -ne [string]$actualFingerprint.sha256) {
    throw "Publication dry-run refused evidence bundle preflight summary fingerprint mismatch for $Name."
  }
}

function Assert-RulesetReportInputFingerprintIntegrity {
  param([Parameter(Mandatory = $true)][object]$Fingerprint)

  $resolvedFingerprintPath = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path ([string]$Fingerprint.path)))
  if (-not (Test-Path -LiteralPath $resolvedFingerprintPath -PathType Leaf)) {
    throw "Publication dry-run refused evidence bundle github ruleset report fingerprint mismatch."
  }

  $actualFingerprint = Get-InputFingerprint -Path $resolvedFingerprintPath
  if ([string]$Fingerprint.sha256 -ne [string]$actualFingerprint.sha256) {
    throw "Publication dry-run refused evidence bundle github ruleset report fingerprint mismatch."
  }

  $rulesetReport = Get-Content -Raw -LiteralPath $resolvedFingerprintPath | ConvertFrom-Json
  if ([int]$rulesetReport.schema_version -ne 1) {
    throw "Publication dry-run refused ruleset report without schema_version 1."
  }

  if ($rulesetReport.read_only -ne $true) {
    throw "Publication dry-run refused ruleset report that is not read-only."
  }

  if ($null -eq $rulesetReport.PSObject.Properties["ok"]) {
    throw "Publication dry-run refused ruleset report without ok status."
  }

  if ([string]$rulesetReport.repository -ne $expectedRulesetRepository) {
    throw "Publication dry-run refused ruleset report repository mismatch."
  }

  if ([string]$rulesetReport.branch -ne $expectedRulesetBranch) {
    throw "Publication dry-run refused ruleset report branch mismatch."
  }

  if ($rulesetReport.ok -eq $true) {
    $rulesetChecksProperty = $rulesetReport.PSObject.Properties["checks"]
    $rulesetChecks = @()
    if ($null -ne $rulesetChecksProperty -and $null -ne $rulesetChecksProperty.Value) {
      $rulesetChecks = @($rulesetChecksProperty.Value)
    }
    if ($rulesetChecks.Count -eq 0) {
      throw "Publication dry-run refused ruleset report ok status without checks."
    }
    foreach ($check in $rulesetChecks) {
      if (
        [string]::IsNullOrWhiteSpace([string]$check.name) -or
        [string]::IsNullOrWhiteSpace([string]$check.status)
      ) {
        throw "Publication dry-run refused ruleset report check entry shape mismatch."
      }
      if ([string]$check.status -ne "pass") {
        throw "Publication dry-run refused ruleset report ok status with failed checks."
      }
    }
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
    throw "Publication dry-run refused evidence with missing artifact path for $Name."
  }

  $resolvedExpectedPath = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path $ExpectedPath))
  $resolvedFingerprintPath = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path ([string]$Fingerprint.path)))
  if (-not $resolvedFingerprintPath.Equals($resolvedExpectedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Publication dry-run refused evidence with artifact fingerprint mismatch for $Name."
  }

  if (-not (Test-Path -LiteralPath $resolvedExpectedPath -PathType Leaf)) {
    throw "Publication dry-run refused evidence with artifact fingerprint mismatch for $Name."
  }

  $actualFingerprint = Get-InputFingerprint -Path $resolvedExpectedPath
  if ([string]$Fingerprint.sha256 -ne [string]$actualFingerprint.sha256) {
    throw "Publication dry-run refused evidence with artifact fingerprint mismatch for $Name."
  }

  if (
    -not [string]::IsNullOrWhiteSpace($ExpectedSha256) -and
    [string]$Fingerprint.sha256 -ne $ExpectedSha256
  ) {
    throw "Publication dry-run refused evidence with artifact fingerprint mismatch for $Name."
  }
}

Push-Location $root
try {
  $resolvedEvidenceBundlePath = Resolve-RepoPath -Path $EvidenceBundlePath
  $resolvedReleaseNotesPath = Resolve-RepoPath -Path $ReleaseNotesPath

  if (-not (Test-Path -LiteralPath $resolvedEvidenceBundlePath -PathType Leaf)) {
    throw "Evidence bundle not found: $resolvedEvidenceBundlePath"
  }
  if (-not (Test-Path -LiteralPath $resolvedReleaseNotesPath -PathType Leaf)) {
    throw "Release notes not found: $resolvedReleaseNotesPath"
  }

  if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $root (Join-Path $defaultOutputDir $Tag)
  } else {
    $OutDir = Resolve-RepoPath -Path $OutDir
  }
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

  $evidence = Get-Content -Raw -LiteralPath $resolvedEvidenceBundlePath | ConvertFrom-Json
  if ($evidence.tag -ne $Tag) {
    throw "Evidence bundle tag '$($evidence.tag)' does not match $Tag."
  }
  $evidenceCommitSha = [string]$evidence.commit_sha
  $evidencePreflightCommitSha = [string]$evidence.preflight_commit_sha
  $evidencePreflightRefCommitSha = [string]$evidence.preflight_ref_commit_sha
  if (
    $evidenceCommitSha -notmatch "^[0-9a-fA-F]{40}$" -or
    $evidencePreflightCommitSha -notmatch "^[0-9a-fA-F]{40}$" -or
    $evidencePreflightRefCommitSha -notmatch "^[0-9a-fA-F]{40}$"
  ) {
    throw "Publication dry-run refused evidence without commit SHA proof."
  }
  if ($evidenceCommitSha -ne $evidencePreflightCommitSha) {
    throw "Publication dry-run refused evidence: evidence commit SHA does not match preflight commit SHA."
  }
  if ($evidencePreflightCommitSha -ne $evidencePreflightRefCommitSha) {
    throw "Publication dry-run refused evidence: evidence preflight commit SHA does not match resolved ref commit SHA."
  }

  foreach ($flag in @(
      "source_only",
      "no_apk",
      "no_exe",
      "no_store_release",
      "no_trusted_signing_claim"
    )) {
    Assert-FlagTrue -Payload $evidence -Name $flag
  }

  if ([int]$evidence.forbidden_file_count -ne 0) {
    throw "Publication dry-run refused evidence with forbidden_file_count=$($evidence.forbidden_file_count)."
  }

  if ($evidence.windows_bundle_verifier_ok -ne $true) {
    throw "Publication dry-run refused evidence with windows_bundle_verifier_ok not true."
  }

  if ([string]::IsNullOrWhiteSpace([string]$evidence.windows_bundle_verifier_summary)) {
    throw "Publication dry-run refused evidence without windows_bundle_verifier_summary."
  }

  if ($evidence.release_boundary.ships_apk -ne $false -or
    $evidence.release_boundary.ships_exe -ne $false -or
    $evidence.release_boundary.store_release -ne $false -or
    $evidence.release_boundary.trusted_signing_claim -ne $false -or
    $evidence.release_boundary.official_binary_claim -ne $false) {
    throw "Publication dry-run refused evidence with binary or official release boundary enabled."
  }

  $evidenceBundleInputFingerprints = $null
  $evidenceInputFingerprintProperty = $evidence.PSObject.Properties["input_fingerprints"]
  if ($null -ne $evidenceInputFingerprintProperty) {
    $evidenceBundleInputFingerprints = $evidenceInputFingerprintProperty.Value
  }
  $preflightFingerprint = $null
  if ($null -ne $evidenceBundleInputFingerprints) {
    $preflightFingerprintProperty = $evidenceBundleInputFingerprints.PSObject.Properties["preflight_summary"]
    if ($null -ne $preflightFingerprintProperty) {
      $preflightFingerprint = $preflightFingerprintProperty.Value
    }
  }
  if (
    [string]::IsNullOrWhiteSpace([string]$preflightFingerprint.path) -or
    [string]::IsNullOrWhiteSpace([string]$preflightFingerprint.sha256) -or
    [string]$preflightFingerprint.sha256 -notmatch "^[0-9a-fA-F]{64}$"
  ) {
    throw "Publication dry-run refused evidence bundle is missing input fingerprints."
  }
  Assert-InputFingerprintIntegrity -Fingerprint $preflightFingerprint -Name "preflight_summary"

  $rulesetFingerprint = $null
  if ($null -ne $evidenceBundleInputFingerprints) {
    $rulesetFingerprintProperty = $evidenceBundleInputFingerprints.PSObject.Properties["github_ruleset_report"]
    if ($null -ne $rulesetFingerprintProperty) {
      $rulesetFingerprint = $rulesetFingerprintProperty.Value
    }
  }
  $rulesetFingerprintPresent = (
    -not [string]::IsNullOrWhiteSpace([string]$rulesetFingerprint.path) -and
    -not [string]::IsNullOrWhiteSpace([string]$rulesetFingerprint.sha256) -and
    [string]$rulesetFingerprint.sha256 -match "^[0-9a-fA-F]{64}$"
  )
  if ($rulesetFingerprintPresent) {
    Assert-RulesetReportInputFingerprintIntegrity -Fingerprint $rulesetFingerprint
  } elseif (
    $evidence.github_enforcement_claim_allowed -eq $true -or
    -not [string]::IsNullOrWhiteSpace([string]$evidence.github_ruleset_report)
  ) {
    throw "Publication dry-run refused evidence bundle is missing github ruleset report input fingerprint."
  }

  $evidenceBundlePreflightArtifactFingerprints = $null
  $artifactFingerprintProperty = $evidence.PSObject.Properties["preflight_artifact_fingerprints"]
  if ($null -ne $artifactFingerprintProperty) {
    $evidenceBundlePreflightArtifactFingerprints = $artifactFingerprintProperty.Value
  }
  foreach ($fingerprintName in @(
      "proof_manifest",
      "release_notes",
      "source_archive",
      "windows_bundle_verifier_summary"
    )) {
    $fingerprintEntry = $null
    if ($null -ne $evidenceBundlePreflightArtifactFingerprints) {
      $fingerprintProperty = $evidenceBundlePreflightArtifactFingerprints.PSObject.Properties[$fingerprintName]
      if ($null -ne $fingerprintProperty) {
        $fingerprintEntry = $fingerprintProperty.Value
      }
    }
    if (
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.path) -or
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.sha256) -or
      [string]$fingerprintEntry.sha256 -notmatch "^[0-9a-fA-F]{64}$"
    ) {
      throw "Publication dry-run refused evidence bundle is missing preflight artifact fingerprints."
    }
  }

  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $evidenceBundlePreflightArtifactFingerprints.proof_manifest `
    -ExpectedPath ([string]$evidenceBundlePreflightArtifactFingerprints.proof_manifest.path) `
    -Name "proof_manifest"
  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $evidenceBundlePreflightArtifactFingerprints.release_notes `
    -ExpectedPath $resolvedReleaseNotesPath `
    -Name "release_notes"
  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $evidenceBundlePreflightArtifactFingerprints.source_archive `
    -ExpectedPath ([string]$evidenceBundlePreflightArtifactFingerprints.source_archive.path) `
    -ExpectedSha256 ([string]$evidence.source_archive_sha256) `
    -Name "source_archive"
  Assert-ArtifactFingerprintIntegrity `
    -Fingerprint $evidenceBundlePreflightArtifactFingerprints.windows_bundle_verifier_summary `
    -ExpectedPath ([string]$evidence.windows_bundle_verifier_summary) `
    -Name "windows_bundle_verifier_summary"

  powershell -ExecutionPolicy Bypass -File .\scripts\check-source-release-copy.ps1 -ReleaseNotesPath $resolvedReleaseNotesPath
  if ($LASTEXITCODE -ne 0) {
    throw "check-source-release-copy.ps1 failed for rendered release notes."
  }

  $releaseNotes = Get-Content -Raw -LiteralPath $resolvedReleaseNotesPath
  foreach ($phrase in @(
      "Source archive SHA-256:",
      "Source proof manifest:",
      "Verification date:",
      "This is a source-only release"
    )) {
    Assert-Contains -Text $releaseNotes -Phrase $phrase -Label $resolvedReleaseNotesPath
  }

  if ($evidence.github_enforcement_claim_allowed -ne $true) {
    foreach ($forbiddenPhrase in @(
        "remote GitHub enforcement is active",
        "branch protection is enforced",
        "repository rulesets are enforced"
      )) {
      if ($releaseNotes.IndexOf($forbiddenPhrase, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        throw "Release notes must not claim '$forbiddenPhrase' unless github_enforcement_claim_allowed is true."
      }
    }
  }

  $dryRunPath = Join-Path $OutDir "$Tag-publication-dry-run.json"
  $summary = [ordered]@{
    schema_version = 1
    tag = $Tag
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    read_only = $true
    dry_run_only = $true
    publish_performed = $false
    tag_push_performed = $false
    evidence_bundle = $resolvedEvidenceBundlePath
    release_notes = $resolvedReleaseNotesPath
    commit_sha = $evidence.commit_sha
    source_archive_sha256 = $evidence.source_archive_sha256
    input_fingerprints = [ordered]@{
      evidence_bundle = Get-InputFingerprint -Path $resolvedEvidenceBundlePath
      release_notes = Get-InputFingerprint -Path $resolvedReleaseNotesPath
    }
    evidence_bundle_input_fingerprints = $evidenceBundleInputFingerprints
    evidence_bundle_preflight_artifact_fingerprints = $evidenceBundlePreflightArtifactFingerprints
    evidence_bundle_preflight_commit_sha = $evidencePreflightCommitSha
    evidence_bundle_preflight_ref_commit_sha = $evidencePreflightRefCommitSha
    windows_bundle_verifier_ok = [bool]$evidence.windows_bundle_verifier_ok
    windows_bundle_verifier_summary = $evidence.windows_bundle_verifier_summary
    github_ruleset_ok = $evidence.github_ruleset_ok
    github_enforcement_claim_allowed = $evidence.github_enforcement_claim_allowed
    source_only = [bool]$evidence.source_only
    no_apk = [bool]$evidence.no_apk
    no_exe = [bool]$evidence.no_exe
    no_store_release = [bool]$evidence.no_store_release
    no_trusted_signing_claim = [bool]$evidence.no_trusted_signing_claim
    ready_for_manual_review = $true
    manual_publish_note = "Review this dry-run output, release notes, proof manifest, and evidence bundle before creating a GitHub Release manually."
  }

  $summaryJson = $summary | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($dryRunPath, $summaryJson, [System.Text.UTF8Encoding]::new($false))

  Write-Host "Source release publication dry-run written:" -ForegroundColor Green
  Write-Host $dryRunPath
} finally {
  Pop-Location
}
