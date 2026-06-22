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
  if (@($prValues).Count -ne 1) {
    $blockingErrors.Add("input summaries do not agree on latest PR")
  } elseif ([int]$tagReadiness.latest_stacked_pr -ne [int]@($prValues)[0]) {
    $blockingErrors.Add("tag readiness latest stacked PR mismatch")
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
