param(
  [string]$MergeOrderPath = "",
  [string]$GithubStatusPath = "",
  [string]$TagReadinessPath = "",
  [string]$PublicationDryRunPath = "",
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$defaultOutputDir = "build\release-merge-handoff"

function Resolve-RepoPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }
  return Join-Path $root $Path
}

function Read-JsonFile {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "Required release merge handoff input not found: $Path"
  }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
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
    [Parameter(Mandatory = $true)][string]$ErrorMessage,
    [Parameter(Mandatory = $true)][object]$BlockingErrors,
    [string]$RulesetReportSchemaVersionErrorMessage = "",
    [string]$RulesetReportReadOnlyErrorMessage = "",
    [string]$RulesetReportOkStatusErrorMessage = "",
    [string]$RulesetReportRepositoryErrorMessage = "",
    [string]$RulesetReportBranchErrorMessage = "",
    [string]$RulesetReportOkMissingChecksErrorMessage = "",
    [string]$RulesetReportOkFailedChecksErrorMessage = ""
  )

  $resolvedFingerprintPath = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path ([string]$Fingerprint.path)))
  if (-not (Test-Path -LiteralPath $resolvedFingerprintPath -PathType Leaf)) {
    $BlockingErrors.Add($ErrorMessage)
    return
  }

  $actualFingerprint = Get-InputFingerprint -Path $resolvedFingerprintPath
  if ([string]$Fingerprint.sha256 -ne [string]$actualFingerprint.sha256) {
    $BlockingErrors.Add($ErrorMessage)
    return
  }

  if (
    -not [string]::IsNullOrWhiteSpace($RulesetReportSchemaVersionErrorMessage) -or
    -not [string]::IsNullOrWhiteSpace($RulesetReportReadOnlyErrorMessage) -or
    -not [string]::IsNullOrWhiteSpace($RulesetReportOkStatusErrorMessage) -or
    -not [string]::IsNullOrWhiteSpace($RulesetReportRepositoryErrorMessage) -or
    -not [string]::IsNullOrWhiteSpace($RulesetReportBranchErrorMessage) -or
    -not [string]::IsNullOrWhiteSpace($RulesetReportOkMissingChecksErrorMessage) -or
    -not [string]::IsNullOrWhiteSpace($RulesetReportOkFailedChecksErrorMessage)
  ) {
    $rulesetReport = Get-Content -Raw -LiteralPath $resolvedFingerprintPath | ConvertFrom-Json
    if ([int]$rulesetReport.schema_version -ne 1) {
      $BlockingErrors.Add($RulesetReportSchemaVersionErrorMessage)
    }
    if ($rulesetReport.read_only -ne $true) {
      $BlockingErrors.Add($RulesetReportReadOnlyErrorMessage)
    }
    if ($null -eq $rulesetReport.PSObject.Properties["ok"]) {
      $BlockingErrors.Add($RulesetReportOkStatusErrorMessage)
    }
    if ([string]$rulesetReport.repository -ne "Kiwunaka/Pokrov-client") {
      $BlockingErrors.Add($RulesetReportRepositoryErrorMessage)
    }
    if ([string]$rulesetReport.branch -ne "main") {
      $BlockingErrors.Add($RulesetReportBranchErrorMessage)
    }
    if ($rulesetReport.ok -eq $true) {
      $rulesetChecksProperty = $rulesetReport.PSObject.Properties["checks"]
      $rulesetChecks = @()
      if ($null -ne $rulesetChecksProperty -and $null -ne $rulesetChecksProperty.Value) {
        $rulesetChecks = @($rulesetChecksProperty.Value)
      }
      if ($rulesetChecks.Count -eq 0) {
        $BlockingErrors.Add($RulesetReportOkMissingChecksErrorMessage)
      } else {
        foreach ($check in $rulesetChecks) {
          if ([string]$check.status -ne "pass") {
            $BlockingErrors.Add($RulesetReportOkFailedChecksErrorMessage)
            break
          }
        }
      }
    }
  }
}

function Assert-BuildOutputPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  $allowedOutputRoot = [System.IO.Path]::GetFullPath((Join-Path $root $defaultOutputDir))
  $resolvedOutputDir = [System.IO.Path]::GetFullPath($Path)
  $allowedPrefix = $allowedOutputRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  ) + [System.IO.Path]::DirectorySeparatorChar
  if (
    $resolvedOutputDir -ne $allowedOutputRoot -and
    -not $resolvedOutputDir.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)
  ) {
    throw "Release merge handoff output must stay under build\release-merge-handoff."
  }
}

function Assert-BuildInputPath {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$AllowedRoot,
    [Parameter(Mandatory = $true)][string]$InputName
  )

  $allowedInputRoot = [System.IO.Path]::GetFullPath((Join-Path $root $AllowedRoot))
  $resolvedInputPath = [System.IO.Path]::GetFullPath($Path)
  $allowedPrefix = $allowedInputRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  ) + [System.IO.Path]::DirectorySeparatorChar
  if (-not $resolvedInputPath.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    $allowedRootDisplay = $AllowedRoot -replace "/", "\"
    throw "Release merge handoff input '$InputName' must stay under $allowedRootDisplay."
  }
}

function Assert-InputGeneratedAt {
  param(
    [Parameter(Mandatory = $true)][object]$Payload,
    [Parameter(Mandatory = $true)][string]$InputName
  )

  if ([string]::IsNullOrWhiteSpace([string]$Payload.generated_at)) {
    throw "Release merge handoff input '$InputName' must include generated_at."
  }
}

function Assert-InputSchemaVersion {
  param(
    [Parameter(Mandatory = $true)][object]$Payload,
    [Parameter(Mandatory = $true)][string]$InputName
  )

  if ([int]$Payload.schema_version -ne 1) {
    throw "Release merge handoff input '$InputName' must use schema_version 1."
  }
}

function Assert-InputReadOnly {
  param(
    [Parameter(Mandatory = $true)][object]$Payload,
    [Parameter(Mandatory = $true)][string]$InputName
  )

  if ($Payload.read_only -ne $true) {
    throw "Release merge handoff input '$InputName' must be read-only."
  }
}

function Get-InputPath {
  param(
    [AllowEmptyString()][string]$ProvidedPath,
    [Parameter(Mandatory = $true)][string]$DefaultPath
  )

  if ([string]::IsNullOrWhiteSpace($ProvidedPath)) {
    return Resolve-RepoPath -Path $DefaultPath
  }
  return Resolve-RepoPath -Path $ProvidedPath
}

function Get-InputErrors {
  param([Parameter(Mandatory = $true)][object]$Payload)

  $property = $Payload.PSObject.Properties["errors"]
  if ($null -eq $property) {
    return @()
  }
  return @($property.Value) | Where-Object {
    -not [string]::IsNullOrWhiteSpace([string]$_)
  }
}

Push-Location $root
try {
  $seedPath = Join-Path $root "config\release-merge-handoff.seed.json"
  $seed = Read-JsonFile -Path $seedPath
  $githubStatusSeedPath = Join-Path $root "config\release-stack-github-status.seed.json"
  $githubStatusSeed = Read-JsonFile -Path $githubStatusSeedPath
  $expectedPrUrlPrefix = [string]$githubStatusSeed.expected_pr_url_prefix
  $requiredChecks = @($githubStatusSeed.required_status_checks)
  $requiredStatusCheckCount = @($requiredChecks).Count
  $blockerInventoryPath = Join-Path $root "config\release-blocker-inventory.seed.json"
  $blockerInventory = Read-JsonFile -Path $blockerInventoryPath

  $mergeOrderPath = Get-InputPath -ProvidedPath $MergeOrderPath -DefaultPath $seed.inputs.merge_order
  $githubStatusPath = Get-InputPath -ProvidedPath $GithubStatusPath -DefaultPath $seed.inputs.github_status
  $tagReadinessPath = Get-InputPath -ProvidedPath $TagReadinessPath -DefaultPath $seed.inputs.tag_readiness
  $publicationDryRunPath = Get-InputPath -ProvidedPath $PublicationDryRunPath -DefaultPath $seed.inputs.publication_dry_run

  Assert-BuildInputPath -Path $mergeOrderPath -AllowedRoot $seed.input_roots.merge_order -InputName "merge_order"
  Assert-BuildInputPath -Path $githubStatusPath -AllowedRoot $seed.input_roots.github_status -InputName "github_status"
  Assert-BuildInputPath -Path $tagReadinessPath -AllowedRoot $seed.input_roots.tag_readiness -InputName "tag_readiness"
  Assert-BuildInputPath -Path $publicationDryRunPath -AllowedRoot $seed.input_roots.publication_dry_run -InputName "publication_dry_run"

  $mergeOrder = Read-JsonFile -Path $mergeOrderPath
  $githubStatus = Read-JsonFile -Path $githubStatusPath
  $tagReadiness = Read-JsonFile -Path $tagReadinessPath
  $publicationDryRun = Read-JsonFile -Path $publicationDryRunPath

  Assert-InputGeneratedAt -Payload $mergeOrder -InputName "merge_order"
  Assert-InputGeneratedAt -Payload $githubStatus -InputName "github_status"
  Assert-InputGeneratedAt -Payload $tagReadiness -InputName "tag_readiness"
  Assert-InputGeneratedAt -Payload $publicationDryRun -InputName "publication_dry_run"
  Assert-InputSchemaVersion -Payload $mergeOrder -InputName "merge_order"
  Assert-InputSchemaVersion -Payload $githubStatus -InputName "github_status"
  Assert-InputSchemaVersion -Payload $tagReadiness -InputName "tag_readiness"
  Assert-InputSchemaVersion -Payload $publicationDryRun -InputName "publication_dry_run"
  Assert-InputReadOnly -Payload $mergeOrder -InputName "merge_order"
  Assert-InputReadOnly -Payload $githubStatus -InputName "github_status"
  Assert-InputReadOnly -Payload $tagReadiness -InputName "tag_readiness"
  Assert-InputReadOnly -Payload $publicationDryRun -InputName "publication_dry_run"

  $blockingErrors = [System.Collections.Generic.List[string]]::new()

  if ($mergeOrder.merge_order_ok -ne $true) {
    $blockingErrors.Add("release merge order is not OK")
  }
  if ($githubStatus.github_status_ok -ne $true) {
    $blockingErrors.Add("release stack GitHub status is not OK")
  }
  if ($tagReadiness.source_only -ne $true) {
    $blockingErrors.Add("tag readiness summary is not source-only")
  }
  if ($publicationDryRun.source_only -ne $true) {
    $blockingErrors.Add("publication dry-run is not source-only")
  }
  if ($publicationDryRun.dry_run_only -ne $true) {
    $blockingErrors.Add("publication dry-run is not marked dry-run only")
  }
  if ($publicationDryRun.ready_for_manual_review -ne $true) {
    $blockingErrors.Add("publication dry-run is not ready for manual review")
  }
  if ($publicationDryRun.publish_performed -ne $false) {
    $blockingErrors.Add("publication dry-run reports a publish action")
  }
  if ($publicationDryRun.tag_push_performed -ne $false) {
    $blockingErrors.Add("publication dry-run reports a tag push action")
  }
  if ($publicationDryRun.windows_bundle_verifier_ok -ne $true -or [string]::IsNullOrWhiteSpace([string]$publicationDryRun.windows_bundle_verifier_summary)) {
    $blockingErrors.Add("publication dry-run missing Windows bundle verifier proof")
  }
  $publicationDryRunCommitSha = [string]$publicationDryRun.commit_sha
  $publicationDryRunEvidenceBundlePreflightCommitSha = [string]$publicationDryRun.evidence_bundle_preflight_commit_sha
  $publicationDryRunEvidenceBundlePreflightRefCommitSha = [string]$publicationDryRun.evidence_bundle_preflight_ref_commit_sha
  if (
    $publicationDryRunCommitSha -notmatch "^[0-9a-fA-F]{40}$" -or
    $publicationDryRunEvidenceBundlePreflightCommitSha -notmatch "^[0-9a-fA-F]{40}$" -or
    $publicationDryRunCommitSha -ne $publicationDryRunEvidenceBundlePreflightCommitSha
  ) {
    $blockingErrors.Add("publication dry-run commit SHA mismatch")
  }
  if (
    $publicationDryRunEvidenceBundlePreflightRefCommitSha -notmatch "^[0-9a-fA-F]{40}$" -or
    $publicationDryRunEvidenceBundlePreflightCommitSha -ne $publicationDryRunEvidenceBundlePreflightRefCommitSha
  ) {
    $blockingErrors.Add("publication dry-run ref commit SHA mismatch")
  }
  $inputErrors = @(Get-InputErrors -Payload $mergeOrder) +
    @(Get-InputErrors -Payload $githubStatus) +
    @(Get-InputErrors -Payload $tagReadiness) +
    @(Get-InputErrors -Payload $publicationDryRun)
  if (@($inputErrors).Count -gt 0) {
    $blockingErrors.Add("input summaries report errors")
  }
  $tagReadinessInputFingerprints = $null
  $tagReadinessInputFingerprintProperty = $tagReadiness.PSObject.Properties["input_fingerprints"]
  if ($null -ne $tagReadinessInputFingerprintProperty) {
    $tagReadinessInputFingerprints = $tagReadinessInputFingerprintProperty.Value
  }
  $missingTagReadinessInputFingerprints = $false
  foreach ($fingerprintName in @("blocker_inventory", "source_readiness")) {
    $fingerprintEntry = $null
    if ($null -ne $tagReadinessInputFingerprints) {
      $fingerprintProperty = $tagReadinessInputFingerprints.PSObject.Properties[$fingerprintName]
      if ($null -ne $fingerprintProperty) {
        $fingerprintEntry = $fingerprintProperty.Value
      }
    }
    if (
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.path) -or
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.sha256) -or
      [string]$fingerprintEntry.sha256 -notmatch "^[0-9a-fA-F]{64}$"
    ) {
      $missingTagReadinessInputFingerprints = $true
      break
    }
  }
  if ($missingTagReadinessInputFingerprints) {
    $blockingErrors.Add("tag readiness summary is missing input fingerprints")
  } else {
    foreach ($fingerprintName in @("blocker_inventory", "source_readiness")) {
      $fingerprintEntry = $tagReadinessInputFingerprints.PSObject.Properties[$fingerprintName].Value
      Assert-InputFingerprintIntegrity `
        -Fingerprint $fingerprintEntry `
        -ErrorMessage "tag readiness input fingerprints mismatch" `
        -BlockingErrors $blockingErrors
    }
  }
  $publicationDryRunInputFingerprints = $null
  $publicationDryRunInputFingerprintProperty = $publicationDryRun.PSObject.Properties["input_fingerprints"]
  if ($null -ne $publicationDryRunInputFingerprintProperty) {
    $publicationDryRunInputFingerprints = $publicationDryRunInputFingerprintProperty.Value
  }
  $missingPublicationDryRunInputFingerprints = $false
  foreach ($fingerprintName in @("evidence_bundle", "release_notes")) {
    $fingerprintEntry = $null
    if ($null -ne $publicationDryRunInputFingerprints) {
      $fingerprintProperty = $publicationDryRunInputFingerprints.PSObject.Properties[$fingerprintName]
      if ($null -ne $fingerprintProperty) {
        $fingerprintEntry = $fingerprintProperty.Value
      }
    }
    if (
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.path) -or
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.sha256) -or
      [string]$fingerprintEntry.sha256 -notmatch "^[0-9a-fA-F]{64}$"
    ) {
      $missingPublicationDryRunInputFingerprints = $true
      break
    }
  }
  if ($missingPublicationDryRunInputFingerprints) {
    $blockingErrors.Add("publication dry-run summary is missing input fingerprints")
  } else {
    foreach ($fingerprintName in @("evidence_bundle", "release_notes")) {
      $fingerprintEntry = $publicationDryRunInputFingerprints.PSObject.Properties[$fingerprintName].Value
      Assert-InputFingerprintIntegrity `
        -Fingerprint $fingerprintEntry `
        -ErrorMessage "publication dry-run input fingerprints mismatch" `
        -BlockingErrors $blockingErrors
    }
  }
  $publicationDryRunEvidenceBundleInputFingerprints = $null
  $publicationDryRunEvidenceBundleInputFingerprintProperty = $publicationDryRun.PSObject.Properties["evidence_bundle_input_fingerprints"]
  if ($null -ne $publicationDryRunEvidenceBundleInputFingerprintProperty) {
    $publicationDryRunEvidenceBundleInputFingerprints = $publicationDryRunEvidenceBundleInputFingerprintProperty.Value
  }
  $publicationDryRunPreflightFingerprint = $null
  if ($null -ne $publicationDryRunEvidenceBundleInputFingerprints) {
    $preflightFingerprintProperty = $publicationDryRunEvidenceBundleInputFingerprints.PSObject.Properties["preflight_summary"]
    if ($null -ne $preflightFingerprintProperty) {
      $publicationDryRunPreflightFingerprint = $preflightFingerprintProperty.Value
    }
  }
  if (
    [string]::IsNullOrWhiteSpace([string]$publicationDryRunPreflightFingerprint.path) -or
    [string]::IsNullOrWhiteSpace([string]$publicationDryRunPreflightFingerprint.sha256) -or
    [string]$publicationDryRunPreflightFingerprint.sha256 -notmatch "^[0-9a-fA-F]{64}$"
  ) {
    $blockingErrors.Add("publication dry-run summary is missing evidence bundle input fingerprints")
  } else {
    Assert-InputFingerprintIntegrity `
      -Fingerprint $publicationDryRunPreflightFingerprint `
      -ErrorMessage "publication dry-run preflight input fingerprint mismatch" `
      -BlockingErrors $blockingErrors
  }
  $publicationDryRunRulesetReportFingerprint = $null
  if ($null -ne $publicationDryRunEvidenceBundleInputFingerprints) {
    $rulesetReportFingerprintProperty = $publicationDryRunEvidenceBundleInputFingerprints.PSObject.Properties["github_ruleset_report"]
    if ($null -ne $rulesetReportFingerprintProperty) {
      $publicationDryRunRulesetReportFingerprint = $rulesetReportFingerprintProperty.Value
    }
  }
  $publicationDryRunRulesetReportFingerprintPresent = (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRunRulesetReportFingerprint.path) -and
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRunRulesetReportFingerprint.sha256) -and
    [string]$publicationDryRunRulesetReportFingerprint.sha256 -match "^[0-9a-fA-F]{64}$"
  )
  if ($publicationDryRunRulesetReportFingerprintPresent) {
    Assert-InputFingerprintIntegrity `
      -Fingerprint $publicationDryRunRulesetReportFingerprint `
      -ErrorMessage "publication dry-run ruleset report input fingerprint mismatch" `
      -RulesetReportSchemaVersionErrorMessage "publication dry-run ruleset report without schema_version 1" `
      -RulesetReportReadOnlyErrorMessage "publication dry-run ruleset report that is not read-only" `
      -RulesetReportOkStatusErrorMessage "publication dry-run ruleset report without ok status" `
      -RulesetReportRepositoryErrorMessage "publication dry-run ruleset report repository mismatch" `
      -RulesetReportBranchErrorMessage "publication dry-run ruleset report branch mismatch" `
      -RulesetReportOkMissingChecksErrorMessage "publication dry-run ruleset report ok status without checks" `
      -RulesetReportOkFailedChecksErrorMessage "publication dry-run ruleset report ok status with failed checks" `
      -BlockingErrors $blockingErrors
  } elseif (
    $publicationDryRun.github_enforcement_claim_allowed -eq $true -or
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.github_ruleset_report)
  ) {
    $blockingErrors.Add("publication dry-run summary is missing ruleset report input fingerprint")
  }
  $publicationDryRunEvidenceBundlePreflightArtifactFingerprints = $null
  $publicationDryRunEvidenceBundlePreflightArtifactFingerprintProperty = $publicationDryRun.PSObject.Properties["evidence_bundle_preflight_artifact_fingerprints"]
  if ($null -ne $publicationDryRunEvidenceBundlePreflightArtifactFingerprintProperty) {
    $publicationDryRunEvidenceBundlePreflightArtifactFingerprints = $publicationDryRunEvidenceBundlePreflightArtifactFingerprintProperty.Value
  }
  $missingPublicationDryRunEvidenceBundlePreflightArtifactFingerprints = $false
  foreach ($fingerprintName in @(
      "proof_manifest",
      "release_notes",
      "source_archive",
      "windows_bundle_verifier_summary"
    )) {
    $fingerprintEntry = $null
    if ($null -ne $publicationDryRunEvidenceBundlePreflightArtifactFingerprints) {
      $fingerprintProperty = $publicationDryRunEvidenceBundlePreflightArtifactFingerprints.PSObject.Properties[$fingerprintName]
      if ($null -ne $fingerprintProperty) {
        $fingerprintEntry = $fingerprintProperty.Value
      }
    }
    if (
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.path) -or
      [string]::IsNullOrWhiteSpace([string]$fingerprintEntry.sha256) -or
      [string]$fingerprintEntry.sha256 -notmatch "^[0-9a-fA-F]{64}$"
    ) {
      $missingPublicationDryRunEvidenceBundlePreflightArtifactFingerprints = $true
      break
    }
  }
  if ($missingPublicationDryRunEvidenceBundlePreflightArtifactFingerprints) {
    $blockingErrors.Add("publication dry-run summary is missing evidence bundle preflight artifact fingerprints")
  } else {
    foreach ($fingerprintName in @(
        "proof_manifest",
        "release_notes",
        "source_archive",
        "windows_bundle_verifier_summary"
      )) {
      $fingerprintEntry = $publicationDryRunEvidenceBundlePreflightArtifactFingerprints.PSObject.Properties[$fingerprintName].Value
      Assert-InputFingerprintIntegrity `
        -Fingerprint $fingerprintEntry `
        -ErrorMessage "publication dry-run artifact fingerprints mismatch" `
        -BlockingErrors $blockingErrors
    }
  }
  if (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRunInputFingerprints.release_notes.sha256) -and
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRunEvidenceBundlePreflightArtifactFingerprints.release_notes.sha256) -and
    [string]$publicationDryRunInputFingerprints.release_notes.sha256 -ne [string]$publicationDryRunEvidenceBundlePreflightArtifactFingerprints.release_notes.sha256
  ) {
    $blockingErrors.Add("publication dry-run artifact fingerprints mismatch")
  }
  if (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.source_archive_sha256) -and
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRunEvidenceBundlePreflightArtifactFingerprints.source_archive.sha256) -and
    [string]$publicationDryRun.source_archive_sha256 -ne [string]$publicationDryRunEvidenceBundlePreflightArtifactFingerprints.source_archive.sha256
  ) {
    $blockingErrors.Add("publication dry-run artifact fingerprints mismatch")
  }
  $tagOpenBlockers = @($tagReadiness.open_blockers)
  $tagOpenBlockerCount = [int]$tagReadiness.open_blocker_count
  if ($tagOpenBlockerCount -ne @($tagOpenBlockers).Count) {
    $blockingErrors.Add("tag readiness open blocker count mismatch")
  }
  foreach ($openBlocker in $tagOpenBlockers) {
    if (
      [string]::IsNullOrWhiteSpace([string]$openBlocker.id) -or
      [string]::IsNullOrWhiteSpace([string]$openBlocker.status)
    ) {
      $blockingErrors.Add("tag readiness open blockers have invalid entries")
      break
    }
  }
  foreach ($openBlocker in $tagOpenBlockers) {
    if (
      $openBlocker.required_before_tag -ne $true -or
      [string]::IsNullOrWhiteSpace([string]$openBlocker.evidence)
    ) {
      $blockingErrors.Add("tag readiness open blockers are missing evidence fields")
      break
    }
  }
  if ($tagOpenBlockerCount -gt 0 -and ($tagReadiness.ready_for_tag -eq $true -or $tagReadiness.tag_creation_allowed -eq $true)) {
    $blockingErrors.Add("tag readiness allows tag creation while blockers remain")
  }
  if ($tagOpenBlockerCount -eq 0 -and ($tagReadiness.ready_for_tag -ne $true -or $tagReadiness.tag_creation_allowed -ne $true)) {
    $blockingErrors.Add("tag readiness denies tag creation without blockers")
  }
  $candidateValues = @(
    [string]$mergeOrder.latest_candidate,
    [string]$githubStatus.latest_candidate,
    [string]$tagReadiness.latest_candidate,
    [string]$tagReadiness.tag,
    [string]$publicationDryRun.tag
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
  if (@($candidateValues).Count -ne 1) {
    $blockingErrors.Add("input summaries do not agree on latest candidate")
  }
  $blockerInventoryLatestCandidate = [string]$blockerInventory.tracked_candidates.latest_candidate
  if ([string]::IsNullOrWhiteSpace($blockerInventoryLatestCandidate)) {
    $blockingErrors.Add("release blocker inventory latest candidate is missing")
  } elseif (@($candidateValues).Count -eq 1 -and [string]@($candidateValues)[0] -ne $blockerInventoryLatestCandidate) {
    $blockingErrors.Add("release handoff latest candidate does not match blocker inventory")
  }
  $prValues = @(
    [int]$mergeOrder.latest_pr,
    [int]$githubStatus.latest_pr
  ) | Select-Object -Unique
  $githubStatusLatestPrUrl = [string]$githubStatus.latest_pr_url
  $githubStatusExpectedPrUrlPrefix = [string]$githubStatus.expected_pr_url_prefix
  $githubStatusStackCount = [int]$githubStatus.stack_count
  $githubStatusCleanPrCount = [int]$githubStatus.clean_pr_count
  $githubStatusDraftPrCount = [int]$githubStatus.draft_pr_count
  $githubStatusUncleanPrCount = [int]$githubStatus.unclean_pr_count
  $githubStatusSuccessfulCheckCount = [int]$githubStatus.successful_check_count
  $githubStatusFailedCheckCount = [int]$githubStatus.failed_check_count
  $expectedSuccessfulCheckCount = $githubStatusStackCount * $requiredStatusCheckCount
  $githubStatusPullRequests = @()
  $githubStatusPullRequestsProperty = $githubStatus.PSObject.Properties["pull_requests"]
  if ($null -ne $githubStatusPullRequestsProperty -and $null -ne $githubStatusPullRequestsProperty.Value) {
    $githubStatusPullRequests = @($githubStatusPullRequestsProperty.Value)
  }
  $githubStatusPullRequestCount = @($githubStatusPullRequests).Count
  $githubStatusPrSequence = @(
    $githubStatusPullRequests | ForEach-Object { [int]$_.pr }
  )
  $githubStatusPrRefs = @(
    $githubStatusPullRequests | ForEach-Object {
      [ordered]@{
        pr = [int]$_.pr
        base = [string]$_.base
        head = [string]$_.head
      }
    }
  )
  $githubStatusPrUrls = @(
    $githubStatusPullRequests | ForEach-Object {
      [ordered]@{
        pr = [int]$_.pr
        url = [string]$_.url
      }
    }
  )
  $githubStatusPrStates = @(
    $githubStatusPullRequests | ForEach-Object {
      [ordered]@{
        pr = [int]$_.pr
        mergeStateStatus = [string]$_.mergeStateStatus
        isDraft = [bool]$_.isDraft
      }
    }
  )
  $githubStatusPrChecks = @(
    $githubStatusPullRequests | ForEach-Object {
      $checkEntries = @()
      $checkEntriesProperty = $_.PSObject.Properties["checks"]
      if ($null -ne $checkEntriesProperty -and $null -ne $checkEntriesProperty.Value) {
        $checkEntries = @($checkEntriesProperty.Value)
      }
      [ordered]@{
        pr = [int]$_.pr
        successful_check_count = [int]$_.successful_check_count
        failed_check_count = [int]$_.failed_check_count
        required_status_check_count = [int]$_.required_status_check_count
        checks = @(
          $checkEntries | ForEach-Object {
            [ordered]@{
              name = [string]$_.name
              status = [string]$_.status
              conclusion = [string]$_.conclusion
              details_url = [string]$_.details_url
              workflow_name = [string]$_.workflow_name
            }
          }
        )
      }
    }
  )
  $mergeOrderStack = @()
  $mergeOrderStackProperty = $mergeOrder.PSObject.Properties["stack"]
  if ($null -ne $mergeOrderStackProperty -and $null -ne $mergeOrderStackProperty.Value) {
    $mergeOrderStack = @($mergeOrderStackProperty.Value)
  }
  $mergeOrderPrSequence = @(
    $mergeOrderStack | ForEach-Object { [int]$_.pr }
  )
  if (@($prValues).Count -ne 1) {
    $blockingErrors.Add("input summaries do not agree on latest PR")
  } elseif ([int]$tagReadiness.latest_stacked_pr -ne [int]@($prValues)[0]) {
    $blockingErrors.Add("tag readiness latest stacked PR mismatch")
  }
  if (
    [string]::IsNullOrWhiteSpace($githubStatusExpectedPrUrlPrefix) -or
    [string]$githubStatusExpectedPrUrlPrefix -ne [string]$expectedPrUrlPrefix
  ) {
    $blockingErrors.Add("release stack GitHub status expected PR URL prefix mismatch")
  }
  if ([string]::IsNullOrWhiteSpace($githubStatusLatestPrUrl)) {
    $blockingErrors.Add("release stack GitHub status latest PR URL is missing")
  } elseif (-not [string]::IsNullOrWhiteSpace($expectedPrUrlPrefix) -and -not $githubStatusLatestPrUrl.StartsWith($expectedPrUrlPrefix, [System.StringComparison]::Ordinal)) {
    $blockingErrors.Add("release stack GitHub status latest PR URL repository mismatch")
  } elseif (@($prValues).Count -eq 1 -and $githubStatusLatestPrUrl -notmatch "/pull/$([int]@($prValues)[0])$") {
    $blockingErrors.Add("release stack GitHub status latest PR URL mismatch")
  }
  if (
    $githubStatusCleanPrCount -ne $githubStatusStackCount -or
    $githubStatusDraftPrCount -ne 0 -or
    $githubStatusUncleanPrCount -ne 0 -or
    $githubStatusFailedCheckCount -ne 0 -or
    $githubStatusSuccessfulCheckCount -ne $expectedSuccessfulCheckCount
  ) {
    $blockingErrors.Add("release stack GitHub status count mismatch")
  }
  $githubStatusPullRequestEntriesMismatch = $false
  if ($githubStatusPullRequestCount -ne $githubStatusStackCount) {
    $githubStatusPullRequestEntriesMismatch = $true
  } elseif ($githubStatusPullRequestCount -gt 0) {
    $latestGithubStatusPullRequest = $githubStatusPullRequests[-1]
    if (
      [int]$latestGithubStatusPullRequest.pr -ne [int]$githubStatus.latest_pr -or
      [string]$latestGithubStatusPullRequest.url -ne [string]$githubStatusLatestPrUrl
    ) {
      $githubStatusPullRequestEntriesMismatch = $true
    }
    foreach ($githubStatusPullRequest in $githubStatusPullRequests) {
      $pullRequestErrors = @($githubStatusPullRequest.errors) | Where-Object {
        -not [string]::IsNullOrWhiteSpace([string]$_)
      }
      if (@($pullRequestErrors).Count -gt 0) {
        $githubStatusPullRequestEntriesMismatch = $true
        break
      }
    }
  }
  if ($githubStatusPullRequestEntriesMismatch) {
    $blockingErrors.Add("release stack GitHub status pull request entries mismatch")
  }
  $githubStatusPrSequenceMismatch = $false
  if (@($githubStatusPrSequence).Count -ne @($mergeOrderPrSequence).Count) {
    $githubStatusPrSequenceMismatch = $true
  } else {
    for ($index = 0; $index -lt @($mergeOrderPrSequence).Count; $index += 1) {
      if ([int]$githubStatusPrSequence[$index] -ne [int]$mergeOrderPrSequence[$index]) {
        $githubStatusPrSequenceMismatch = $true
        break
      }
    }
  }
  if ($githubStatusPrSequenceMismatch) {
    $blockingErrors.Add("release stack GitHub status PR sequence mismatch")
  }
  $githubStatusPrRefsMismatch = $false
  if (@($githubStatusPrRefs).Count -ne @($mergeOrderStack).Count) {
    $githubStatusPrRefsMismatch = $true
  } else {
    for ($index = 0; $index -lt @($mergeOrderStack).Count; $index += 1) {
      $githubStatusPrRef = $githubStatusPrRefs[$index]
      $mergeOrderStackItem = $mergeOrderStack[$index]
      if (
        [int]$githubStatusPrRef.pr -ne [int]$mergeOrderStackItem.pr -or
        [string]$githubStatusPrRef.base -ne [string]$mergeOrderStackItem.base -or
        [string]$githubStatusPrRef.head -ne [string]$mergeOrderStackItem.head
      ) {
        $githubStatusPrRefsMismatch = $true
        break
      }
    }
  }
  if ($githubStatusPrRefsMismatch) {
    $blockingErrors.Add("release stack GitHub status PR refs mismatch")
  }
  $githubStatusPrUrlsMismatch = $false
  if (@($githubStatusPrUrls).Count -ne @($mergeOrderStack).Count) {
    $githubStatusPrUrlsMismatch = $true
  } else {
    for ($index = 0; $index -lt @($mergeOrderStack).Count; $index += 1) {
      $githubStatusPrUrl = $githubStatusPrUrls[$index]
      $mergeOrderStackItem = $mergeOrderStack[$index]
      $expectedPrUrl = "$expectedPrUrlPrefix$([int]$mergeOrderStackItem.pr)"
      if (
        [int]$githubStatusPrUrl.pr -ne [int]$mergeOrderStackItem.pr -or
        [string]$githubStatusPrUrl.url -ne [string]$expectedPrUrl
      ) {
        $githubStatusPrUrlsMismatch = $true
        break
      }
    }
  }
  if ($githubStatusPrUrlsMismatch) {
    $blockingErrors.Add("release stack GitHub status PR URLs mismatch")
  }
  $githubStatusPrStatesMismatch = $false
  if (@($githubStatusPrStates).Count -ne @($mergeOrderStack).Count) {
    $githubStatusPrStatesMismatch = $true
  } else {
    for ($index = 0; $index -lt @($mergeOrderStack).Count; $index += 1) {
      $githubStatusPrState = $githubStatusPrStates[$index]
      $mergeOrderStackItem = $mergeOrderStack[$index]
      if (
        [int]$githubStatusPrState.pr -ne [int]$mergeOrderStackItem.pr -or
        [string]$githubStatusPrState.mergeStateStatus -ne "CLEAN" -or
        [bool]$githubStatusPrState.isDraft -ne $false
      ) {
        $githubStatusPrStatesMismatch = $true
        break
      }
    }
  }
  if ($githubStatusPrStatesMismatch) {
    $blockingErrors.Add("release stack GitHub status PR states mismatch")
  }
  $githubStatusPrChecksMismatch = $false
  if (@($githubStatusPrChecks).Count -ne @($mergeOrderStack).Count) {
    $githubStatusPrChecksMismatch = $true
  } else {
    for ($index = 0; $index -lt @($mergeOrderStack).Count; $index += 1) {
      $githubStatusPrCheck = $githubStatusPrChecks[$index]
      $mergeOrderStackItem = $mergeOrderStack[$index]
      if (
        [int]$githubStatusPrCheck.pr -ne [int]$mergeOrderStackItem.pr -or
        [int]$githubStatusPrCheck.successful_check_count -ne [int]$requiredStatusCheckCount -or
        [int]$githubStatusPrCheck.failed_check_count -ne 0 -or
        [int]$githubStatusPrCheck.required_status_check_count -ne [int]$requiredStatusCheckCount -or
        @($githubStatusPrCheck.checks).Count -ne [int]$requiredStatusCheckCount
      ) {
        $githubStatusPrChecksMismatch = $true
        break
      }
      for ($checkIndex = 0; $checkIndex -lt @($requiredChecks).Count; $checkIndex += 1) {
        $requiredCheckName = [string]$requiredChecks[$checkIndex]
        $githubStatusCheck = @($githubStatusPrCheck.checks)[$checkIndex]
        if (
          [string]$githubStatusCheck.name -ne [string]$requiredCheckName -or
          [string]$githubStatusCheck.status -ne "COMPLETED" -or
          [string]$githubStatusCheck.conclusion -ne "SUCCESS"
        ) {
          $githubStatusPrChecksMismatch = $true
          break
        }
      }
      if ($githubStatusPrChecksMismatch) {
        break
      }
    }
  }
  if ($githubStatusPrChecksMismatch) {
    $blockingErrors.Add("release stack GitHub status PR checks mismatch")
  }
  $githubStatusPrCheckTraceMismatch = $false
  $githubActionsJobUrlPrefix = "https://github.com/Kiwunaka/Pokrov-client/actions/runs/"
  if (@($githubStatusPrChecks).Count -ne @($mergeOrderStack).Count) {
    $githubStatusPrCheckTraceMismatch = $true
  } else {
    foreach ($githubStatusPrCheck in $githubStatusPrChecks) {
      foreach ($githubStatusCheck in @($githubStatusPrCheck.checks)) {
        $detailsUrl = [string]$githubStatusCheck.details_url
        $workflowName = [string]$githubStatusCheck.workflow_name
        if (
          [string]::IsNullOrWhiteSpace($detailsUrl) -or
          -not $detailsUrl.StartsWith($githubActionsJobUrlPrefix, [System.StringComparison]::Ordinal) -or
          $detailsUrl -notmatch "/jobs/" -or
          [string]::IsNullOrWhiteSpace($workflowName)
        ) {
          $githubStatusPrCheckTraceMismatch = $true
          break
        }
      }
      if ($githubStatusPrCheckTraceMismatch) {
        break
      }
    }
  }
  if ($githubStatusPrCheckTraceMismatch) {
    $blockingErrors.Add("release stack GitHub status PR check trace mismatch")
  }
  $blockerInventoryLatestPr = [int]$blockerInventory.tracked_candidates.latest_stacked_pr
  if ($blockerInventoryLatestPr -le 0) {
    $blockingErrors.Add("release blocker inventory latest PR is missing")
  } elseif (@($prValues).Count -eq 1 -and [int]@($prValues)[0] -ne $blockerInventoryLatestPr) {
    $blockingErrors.Add("release handoff latest PR does not match blocker inventory")
  }
  $stackCountValues = @(
    [int]$mergeOrder.stack_count,
    [int]$githubStatus.stack_count
  ) | Select-Object -Unique
  if (@($stackCountValues).Count -ne 1) {
    $blockingErrors.Add("input summaries do not agree on stack count")
  }
  foreach ($field in @("ships_apk", "ships_exe", "store_release", "trusted_signing_claim")) {
    if ($tagReadiness.$field -ne $false) {
      $blockingErrors.Add("tag readiness summary has unsafe release flag '$field'")
    }
  }
  foreach ($field in @("no_apk", "no_exe", "no_store_release", "no_trusted_signing_claim")) {
    if ($publicationDryRun.$field -ne $true) {
      $blockingErrors.Add("publication dry-run missing source-only guard '$field'")
    }
  }

  $handoff_ready_for_maintainer = $true
  if ($blockingErrors.Count -gt 0) {
    $handoff_ready_for_maintainer = $false
  }

  if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $root $defaultOutputDir
  } else {
    $OutDir = Resolve-RepoPath -Path $OutDir
  }
  Assert-BuildOutputPath -Path $OutDir
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

  $summaryPath = Join-Path $OutDir "release-merge-handoff.json"
  $summary = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    read_only = $true
    handoff_ready_for_maintainer = [bool]$handoff_ready_for_maintainer
    source_only = $true
    no_apk = $true
    no_exe = $true
    no_store_release = $true
    no_trusted_signing_claim = $true
    manual_merge_required = $true
    manual_tag_required = $true
    publish_performed = $false
    tag_push_performed = $false
    ready_for_tag = [bool]$tagReadiness.ready_for_tag
    tag_creation_allowed = [bool]$tagReadiness.tag_creation_allowed
    latest_candidate = if (@($candidateValues).Count -gt 0) { [string]@($candidateValues)[0] } else { "" }
    latest_pr = if (@($prValues).Count -gt 0) { [int]@($prValues)[0] } else { 0 }
    latest_pr_url = [string]$githubStatusLatestPrUrl
    expected_pr_url_prefix = [string]$expectedPrUrlPrefix
    github_status_expected_pr_url_prefix = [string]$githubStatusExpectedPrUrlPrefix
    blocker_inventory_latest_candidate = [string]$blockerInventoryLatestCandidate
    blocker_inventory_latest_pr = [int]$blockerInventoryLatestPr
    merge_order_ok = [bool]$mergeOrder.merge_order_ok
    github_status_ok = [bool]$githubStatus.github_status_ok
    input_fingerprints = [ordered]@{
      blocker_inventory = Get-InputFingerprint -Path $blockerInventoryPath
      merge_order = Get-InputFingerprint -Path $mergeOrderPath
      github_status = Get-InputFingerprint -Path $githubStatusPath
      tag_readiness = Get-InputFingerprint -Path $tagReadinessPath
      publication_dry_run = Get-InputFingerprint -Path $publicationDryRunPath
    }
    tag_readiness_input_fingerprints = $tagReadinessInputFingerprints
    publication_dry_run_input_fingerprints = $publicationDryRunInputFingerprints
    publication_dry_run_evidence_bundle_input_fingerprints = $publicationDryRunEvidenceBundleInputFingerprints
    publication_dry_run_evidence_bundle_preflight_artifact_fingerprints = $publicationDryRunEvidenceBundlePreflightArtifactFingerprints
    publication_dry_run_commit_sha = $publicationDryRunCommitSha
    publication_dry_run_evidence_bundle_preflight_commit_sha = $publicationDryRunEvidenceBundlePreflightCommitSha
    publication_dry_run_evidence_bundle_preflight_ref_commit_sha = $publicationDryRunEvidenceBundlePreflightRefCommitSha
    input_generated_at = [ordered]@{
      merge_order = [string]$mergeOrder.generated_at
      github_status = [string]$githubStatus.generated_at
      tag_readiness = [string]$tagReadiness.generated_at
      publication_dry_run = [string]$publicationDryRun.generated_at
    }
    input_schema_versions = [ordered]@{
      merge_order = [int]$mergeOrder.schema_version
      github_status = [int]$githubStatus.schema_version
      tag_readiness = [int]$tagReadiness.schema_version
      publication_dry_run = [int]$publicationDryRun.schema_version
    }
    input_stack_counts = [ordered]@{
      merge_order = [int]$mergeOrder.stack_count
      github_status = [int]$githubStatus.stack_count
    }
    github_status_counts = [ordered]@{
      stack_count = [int]$githubStatusStackCount
      clean_pr_count = [int]$githubStatusCleanPrCount
      draft_pr_count = [int]$githubStatusDraftPrCount
      unclean_pr_count = [int]$githubStatusUncleanPrCount
      successful_check_count = [int]$githubStatusSuccessfulCheckCount
      failed_check_count = [int]$githubStatusFailedCheckCount
      required_status_check_count = [int]$requiredStatusCheckCount
    }
    github_status_pull_request_count = [int]$githubStatusPullRequestCount
    github_status_pr_sequence = @($githubStatusPrSequence)
    github_status_pr_refs = @($githubStatusPrRefs)
    github_status_pr_urls = @($githubStatusPrUrls)
    github_status_pr_states = @($githubStatusPrStates)
    github_status_pr_checks = @($githubStatusPrChecks)
    publication_dry_run_ok = [bool](
      $publicationDryRun.source_only -eq $true -and
      $publicationDryRun.dry_run_only -eq $true -and
      $publicationDryRun.ready_for_manual_review -eq $true -and
      $publicationDryRun.publish_performed -eq $false -and
      $publicationDryRun.tag_push_performed -eq $false -and
      $publicationDryRun.no_apk -eq $true -and
      $publicationDryRun.no_exe -eq $true -and
      $publicationDryRun.no_store_release -eq $true -and
      $publicationDryRun.no_trusted_signing_claim -eq $true -and
      $publicationDryRun.windows_bundle_verifier_ok -eq $true -and
      -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.windows_bundle_verifier_summary)
    )
    publication_ready_for_manual_review = [bool]$publicationDryRun.ready_for_manual_review
    publication_dry_run = [string]$publicationDryRun.tag
    windows_bundle_verifier_ok = [bool]$publicationDryRun.windows_bundle_verifier_ok
    windows_bundle_verifier_summary = [string]$publicationDryRun.windows_bundle_verifier_summary
    open_blocker_count = [int]$tagOpenBlockerCount
    blocking_errors = @($blockingErrors)
    input_error_count = [int]@($inputErrors).Count
    input_errors = @($inputErrors)
    open_blockers = @($tagOpenBlockers)
    next_manual_steps = @(
      "merge stacked PRs in order after maintainer review",
      "choose and record the exact commit SHA on main",
      "create the annotated source tag only after blockers are cleared",
      "run full source-release preflight without -SkipTestCommands",
      "review the publication dry-run, rendered release notes, and evidence bundle before publishing"
    )
  }

  $summaryJson = $summary | ConvertTo-Json -Depth 30
  [System.IO.File]::WriteAllText($summaryPath, $summaryJson, [System.Text.UTF8Encoding]::new($false))

  if ($handoff_ready_for_maintainer) {
    Write-Host "Release merge handoff ready for maintainer review." -ForegroundColor Green
    Write-Host $summaryPath
    exit 0
  }

  Write-Host "Release merge handoff blocked." -ForegroundColor Red
  foreach ($errorMessage in $blockingErrors) {
    Write-Host "- $errorMessage"
  }
  Write-Host $summaryPath
  exit 2
} finally {
  Pop-Location
}
