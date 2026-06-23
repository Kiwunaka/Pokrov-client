param(
  [string]$ReleaseHandoffPath = "",
  [string]$PublicationDryRunPath = "",
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$seedPath = Join-Path $root "config\source-publication-packet.seed.json"
$defaultOutputDir = "build\source-publication-packet"
$inputMaxAgeHours = 24
$inputFutureSkewMinutes = 5

function Resolve-RepoPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  if ([System.IO.Path]::IsPathRooted($Path)) {
    return $Path
  }
  return Join-Path $root $Path
}

function Assert-BuildOutputPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  $allowedRoot = [System.IO.Path]::GetFullPath((Join-Path $root $defaultOutputDir))
  if (-not $resolvedPath.StartsWith($allowedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Source publication packet output must stay under build\source-publication-packet."
  }
}

function Assert-BuildInputPath {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$AllowedRoot,
    [Parameter(Mandatory = $true)][string]$InputName
  )

  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  $resolvedRoot = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path $AllowedRoot))
  if (-not $resolvedPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Source publication packet refused $InputName outside $AllowedRoot."
  }
}

function Get-InputPath {
  param(
    [string]$ProvidedPath,
    [string]$DefaultPath
  )

  if ([string]::IsNullOrWhiteSpace($ProvidedPath)) {
    return [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path $DefaultPath))
  }
  return [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path $ProvidedPath))
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

function Add-BlockingError {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [Parameter(Mandatory = $true)][string]$Message
  )

  $Errors.Add($Message)
}

function Test-TruthyFlag {
  param(
    [object]$Payload,
    [string]$FieldName
  )

  return ($Payload.PSObject.Properties[$FieldName] -and $Payload.$FieldName -eq $true)
}

function Test-FalseFlag {
  param(
    [object]$Payload,
    [string]$FieldName
  )

  return ($Payload.PSObject.Properties[$FieldName] -and $Payload.$FieldName -eq $false)
}

function Get-FingerprintObject {
  param(
    [object]$Container,
    [string]$FieldName
  )

  if ($null -eq $Container -or $null -eq $Container.PSObject.Properties[$FieldName]) {
    return [ordered]@{
      path = ""
      sha256 = ""
    }
  }
  $fingerprint = $Container.$FieldName
  return [ordered]@{
    path = [string]$fingerprint.path
    sha256 = [string]$fingerprint.sha256
  }
}

function Test-FingerprintField {
  param(
    [object]$Container,
    [string]$FieldName
  )

  return ($null -ne $Container -and $null -ne $Container.PSObject.Properties[$FieldName])
}

function Get-NormalizedFingerprintPath {
  param([string]$Path)

  if ([string]::IsNullOrWhiteSpace($Path)) {
    return ""
  }
  return [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path $Path))
}

function Add-FingerprintIntegrityErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Expected,
    [object]$Actual,
    [string]$Label
  )

  $expectedPath = Get-NormalizedFingerprintPath -Path ([string]$Expected.path)
  $actualPath = Get-NormalizedFingerprintPath -Path ([string]$Actual.path)
  $expectedSha = [string]$Expected.sha256
  $actualSha = [string]$Actual.sha256

  if (
    [string]::IsNullOrWhiteSpace($expectedPath) -or
    [string]::IsNullOrWhiteSpace($expectedSha)
  ) {
    Add-BlockingError -Errors $Errors -Message "$Label fingerprint is missing path or sha256"
    return
  }
  if (
    [string]::IsNullOrWhiteSpace($actualPath) -or
    [string]::IsNullOrWhiteSpace($actualSha)
  ) {
    Add-BlockingError -Errors $Errors -Message "$Label comparison fingerprint is missing path or sha256"
    return
  }
  if (
    -not $expectedPath.Equals($actualPath, [System.StringComparison]::OrdinalIgnoreCase) -or
    -not $expectedSha.Equals($actualSha, [System.StringComparison]::OrdinalIgnoreCase)
  ) {
    Add-BlockingError -Errors $Errors -Message "$Label fingerprint mismatch"
  }
}

function Get-ArtifactFileFingerprint {
  param([object]$Fingerprint)

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return [ordered]@{
      path = $resolvedPath
      sha256 = ""
    }
  }
  return Get-InputFingerprint -Path $resolvedPath
}

function Add-ArtifactFileFingerprintErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Name
  )

  $expectedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  $expectedSha = [string]$Fingerprint.sha256
  if (
    [string]::IsNullOrWhiteSpace($expectedPath) -or
    [string]::IsNullOrWhiteSpace($expectedSha)
  ) {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact fingerprint is missing path or sha256 for $Name"
    return
  }
  if (-not (Test-Path -LiteralPath $expectedPath -PathType Leaf)) {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact fingerprint mismatch for $Name"
    return
  }

  $actualFingerprint = Get-InputFingerprint -Path $expectedPath
  if (-not $expectedSha.Equals([string]$actualFingerprint.sha256, [System.StringComparison]::OrdinalIgnoreCase)) {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact fingerprint mismatch for $Name"
  }
}

function Add-InputGeneratedAtErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [Parameter(Mandatory = $true)][object]$Payload,
    [Parameter(Mandatory = $true)][string]$InputName
  )

  $generatedAtText = [string]$Payload.generated_at
  if ([string]::IsNullOrWhiteSpace($generatedAtText)) {
    Add-BlockingError -Errors $Errors -Message "$InputName must include generated_at timestamp"
    return
  }

  $generatedAt = [datetimeoffset]::MinValue
  if (-not [datetimeoffset]::TryParse($generatedAtText, [ref]$generatedAt)) {
    Add-BlockingError -Errors $Errors -Message "$InputName must include parseable generated_at timestamp"
    return
  }

  $generatedAtUtc = $generatedAt.ToUniversalTime()
  $age = [datetimeoffset]::UtcNow - $generatedAtUtc
  if (
    $age.TotalHours -gt $inputMaxAgeHours -or
    $age.TotalMinutes -lt (-1 * $inputFutureSkewMinutes)
  ) {
    Add-BlockingError -Errors $Errors -Message "$InputName has stale generated_at timestamp"
  }
}

Push-Location $root
try {
  $seed = Get-Content -Raw -LiteralPath $seedPath | ConvertFrom-Json
  $releaseHandoffPath = Get-InputPath -ProvidedPath $ReleaseHandoffPath -DefaultPath $seed.inputs.release_handoff
  $publicationDryRunPath = Get-InputPath -ProvidedPath $PublicationDryRunPath -DefaultPath $seed.inputs.publication_dry_run

  Assert-BuildInputPath -Path $releaseHandoffPath -AllowedRoot $seed.input_roots.release_handoff -InputName "release_handoff"
  Assert-BuildInputPath -Path $publicationDryRunPath -AllowedRoot $seed.input_roots.publication_dry_run -InputName "publication_dry_run"

  $releaseHandoff = Get-Content -Raw -LiteralPath $releaseHandoffPath | ConvertFrom-Json
  $publicationDryRun = Get-Content -Raw -LiteralPath $publicationDryRunPath | ConvertFrom-Json

  $blockingErrors = [System.Collections.Generic.List[string]]::new()

  if ([int]$releaseHandoff.schema_version -ne 1) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary must use schema_version 1"
  }
  if ([int]$publicationDryRun.schema_version -ne 1) {
    Add-BlockingError -Errors $blockingErrors -Message "publication dry-run summary must use schema_version 1"
  }
  if ($releaseHandoff.read_only -ne $true) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary must be read-only"
  }
  if ($publicationDryRun.read_only -ne $true) {
    Add-BlockingError -Errors $blockingErrors -Message "publication dry-run summary must be read-only"
  }
  if ($releaseHandoff.handoff_ready_for_maintainer -ne $true) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff must be ready for maintainer review"
  }
  if ($publicationDryRun.ready_for_manual_review -ne $true) {
    Add-BlockingError -Errors $blockingErrors -Message "publication dry-run must be ready for manual review"
  }
  if ($publicationDryRun.dry_run_only -ne $true) {
    Add-BlockingError -Errors $blockingErrors -Message "publication dry-run must be dry-run only"
  }
  Add-InputGeneratedAtErrors -Errors $blockingErrors -Payload $releaseHandoff -InputName "release handoff"
  Add-InputGeneratedAtErrors -Errors $blockingErrors -Payload $publicationDryRun -InputName "publication dry-run"

  foreach ($payloadSpec in @(
    [ordered]@{ name = "release handoff"; payload = $releaseHandoff },
    [ordered]@{ name = "publication dry-run"; payload = $publicationDryRun }
  )) {
    foreach ($field in @("source_only", "no_apk", "no_exe", "no_store_release", "no_trusted_signing_claim")) {
      if (-not (Test-TruthyFlag -Payload $payloadSpec.payload -FieldName $field)) {
        Add-BlockingError -Errors $blockingErrors -Message "$($payloadSpec.name) missing source-only guard '$field'"
      }
    }
    foreach ($field in @("publish_performed", "tag_push_performed")) {
      if (-not (Test-FalseFlag -Payload $payloadSpec.payload -FieldName $field)) {
        Add-BlockingError -Errors $blockingErrors -Message "$($payloadSpec.name) must not report '$field'"
      }
    }
  }

  $publicationInputFingerprints = $publicationDryRun.PSObject.Properties["input_fingerprints"].Value
  if ($null -eq $publicationInputFingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "publication dry-run summary is missing input_fingerprints"
  }
  $publicationArtifactFingerprints = $publicationDryRun.PSObject.Properties["evidence_bundle_preflight_artifact_fingerprints"].Value
  if ($null -eq $publicationArtifactFingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "publication dry-run summary is missing artifact fingerprints"
  }
  $publicationEvidenceBundleFingerprints = $publicationDryRun.PSObject.Properties["evidence_bundle_input_fingerprints"].Value
  if ($null -eq $publicationEvidenceBundleFingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "publication dry-run summary is missing evidence bundle input fingerprints"
  }

  $releaseHandoffInputFingerprints = $releaseHandoff.PSObject.Properties["input_fingerprints"].Value
  if ($null -eq $releaseHandoffInputFingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing input_fingerprints"
  }
  $releaseHandoffPublicationInputFingerprints = $releaseHandoff.PSObject.Properties["publication_dry_run_input_fingerprints"].Value
  if ($null -eq $releaseHandoffPublicationInputFingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_input_fingerprints"
  }
  $releaseHandoffPublicationEvidenceBundleFingerprints = $releaseHandoff.PSObject.Properties["publication_dry_run_evidence_bundle_input_fingerprints"].Value
  if ($null -eq $releaseHandoffPublicationEvidenceBundleFingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_evidence_bundle_input_fingerprints"
  }
  $releaseHandoffPublicationArtifactFingerprints = $releaseHandoff.PSObject.Properties["publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"].Value
  if ($null -eq $releaseHandoffPublicationArtifactFingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_evidence_bundle_preflight_artifact_fingerprints"
  }

  $publicationDryRunActualFingerprint = Get-InputFingerprint -Path $publicationDryRunPath
  Add-FingerprintIntegrityErrors `
    -Errors $blockingErrors `
    -Expected (Get-FingerprintObject -Container $releaseHandoffInputFingerprints -FieldName "publication_dry_run") `
    -Actual $publicationDryRunActualFingerprint `
    -Label "release handoff publication dry-run input"

  foreach ($fieldName in @("evidence_bundle", "release_notes")) {
    Add-FingerprintIntegrityErrors `
      -Errors $blockingErrors `
      -Expected (Get-FingerprintObject -Container $releaseHandoffPublicationInputFingerprints -FieldName $fieldName) `
      -Actual (Get-FingerprintObject -Container $publicationInputFingerprints -FieldName $fieldName) `
      -Label "handoff-carried publication dry-run $fieldName input"
  }

  foreach ($fieldName in @("preflight_summary", "github_ruleset_report")) {
    $handoffHasField = Test-FingerprintField -Container $releaseHandoffPublicationEvidenceBundleFingerprints -FieldName $fieldName
    $publicationHasField = Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName $fieldName
    if ($fieldName -eq "github_ruleset_report" -and -not $handoffHasField -and -not $publicationHasField) {
      continue
    }
    Add-FingerprintIntegrityErrors `
      -Errors $blockingErrors `
      -Expected (Get-FingerprintObject -Container $releaseHandoffPublicationEvidenceBundleFingerprints -FieldName $fieldName) `
      -Actual (Get-FingerprintObject -Container $publicationEvidenceBundleFingerprints -FieldName $fieldName) `
      -Label "handoff-carried publication dry-run $fieldName evidence input"
  }

  foreach ($fieldName in @("proof_manifest", "release_notes", "source_archive", "windows_bundle_verifier_summary")) {
    Add-FingerprintIntegrityErrors `
      -Errors $blockingErrors `
      -Expected (Get-FingerprintObject -Container $releaseHandoffPublicationArtifactFingerprints -FieldName $fieldName) `
      -Actual (Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName $fieldName) `
      -Label "handoff-carried publication dry-run $fieldName artifact"
  }

  $releaseNotes = Get-FingerprintObject -Container $publicationInputFingerprints -FieldName "release_notes"
  $releaseEvidenceBundle = Get-FingerprintObject -Container $publicationInputFingerprints -FieldName "evidence_bundle"
  $proofManifest = Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "proof_manifest"
  $sourceArchive = Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "source_archive"
  $cleanCloneOrImportProof = Get-FingerprintObject -Container $publicationEvidenceBundleFingerprints -FieldName "preflight_summary"

  foreach ($artifactSpec in @(
    [ordered]@{ name = "release_notes"; value = $releaseNotes },
    [ordered]@{ name = "proof_manifest"; value = $proofManifest },
    [ordered]@{ name = "source_archive"; value = $sourceArchive },
    [ordered]@{ name = "release_evidence_bundle"; value = $releaseEvidenceBundle },
    [ordered]@{ name = "clean_clone_or_import_proof"; value = $cleanCloneOrImportProof }
  )) {
    if (
      [string]::IsNullOrWhiteSpace([string]$artifactSpec.value.path) -or
      [string]::IsNullOrWhiteSpace([string]$artifactSpec.value.sha256)
    ) {
      Add-BlockingError -Errors $blockingErrors -Message "source publication packet is missing $($artifactSpec.name) fingerprint"
    }
  }

  if (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.source_archive_sha256) -and
    -not [string]::IsNullOrWhiteSpace([string]$sourceArchive.sha256) -and
    [string]$publicationDryRun.source_archive_sha256 -ne [string]$sourceArchive.sha256
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "source archive SHA-256 must match publication dry-run artifact fingerprint"
  }

  if ([string]$releaseHandoff.latest_candidate -ne [string]$publicationDryRun.tag) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff latest candidate must match publication dry-run tag"
  }

  foreach ($artifactFileSpec in @(
    [ordered]@{ name = "release_notes"; value = $releaseNotes },
    [ordered]@{ name = "release_evidence_bundle"; value = $releaseEvidenceBundle },
    [ordered]@{ name = "proof_manifest"; value = $proofManifest },
    [ordered]@{ name = "source_archive"; value = $sourceArchive },
    [ordered]@{ name = "clean_clone_or_import_proof"; value = $cleanCloneOrImportProof },
    [ordered]@{ name = "windows_bundle_verifier_summary"; value = Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "windows_bundle_verifier_summary" }
  )) {
    Add-ArtifactFileFingerprintErrors -Errors $blockingErrors -Fingerprint $artifactFileSpec.value -Name $artifactFileSpec.name
  }

  $publicationRulesetReport = Get-FingerprintObject -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report"
  if (Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report") {
    Add-ArtifactFileFingerprintErrors -Errors $blockingErrors -Fingerprint $publicationRulesetReport -Name "github_ruleset_report"
  }

  $artifactFileFingerprints = [ordered]@{
    release_notes = Get-ArtifactFileFingerprint -Fingerprint $releaseNotes
    release_evidence_bundle = Get-ArtifactFileFingerprint -Fingerprint $releaseEvidenceBundle
    proof_manifest = Get-ArtifactFileFingerprint -Fingerprint $proofManifest
    source_archive = Get-ArtifactFileFingerprint -Fingerprint $sourceArchive
    clean_clone_or_import_proof = Get-ArtifactFileFingerprint -Fingerprint $cleanCloneOrImportProof
    windows_bundle_verifier_summary = Get-ArtifactFileFingerprint -Fingerprint (Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "windows_bundle_verifier_summary")
  }
  if (Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report") {
    $artifactFileFingerprints.github_ruleset_report = Get-ArtifactFileFingerprint -Fingerprint $publicationRulesetReport
  }

  if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $root $defaultOutputDir
  } else {
    $OutDir = Resolve-RepoPath -Path $OutDir
  }
  Assert-BuildOutputPath -Path $OutDir
  $packetTag = if (-not [string]::IsNullOrWhiteSpace([string]$releaseHandoff.latest_candidate)) {
    [string]$releaseHandoff.latest_candidate
  } else {
    [string]$publicationDryRun.tag
  }
  $packetOutDir = Join-Path $OutDir $packetTag
  New-Item -ItemType Directory -Path $packetOutDir -Force | Out-Null

  $packetPath = Join-Path $packetOutDir "source-publication-packet.json"
  $packetReady = ($blockingErrors.Count -eq 0)
  $packet = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    read_only = $true
    source_only = $true
    manual_publish_only = $true
    packet_ready_for_manual_publish_review = [bool]$packetReady
    publish_performed = $false
    tag_push_performed = $false
    asset_upload_performed = $false
    no_apk = $true
    no_exe = $true
    no_store_release = $true
    no_trusted_signing_claim = $true
    latest_candidate = [string]$releaseHandoff.latest_candidate
    latest_pr = [int]$releaseHandoff.latest_pr
    latest_pr_url = [string]$releaseHandoff.latest_pr_url
    release_handoff_ready_for_maintainer = [bool]$releaseHandoff.handoff_ready_for_maintainer
    publication_ready_for_manual_review = [bool]$publicationDryRun.ready_for_manual_review
    ready_for_tag = [bool]$releaseHandoff.ready_for_tag
    tag_creation_allowed = [bool]$releaseHandoff.tag_creation_allowed
    publication_dry_run_ok = [bool]$releaseHandoff.publication_dry_run_ok
    publication_dry_run = [string]$publicationDryRun.tag
    release_notes = $releaseNotes
    proof_manifest = $proofManifest
    source_archive = $sourceArchive
    source_archive_sha256 = [string]$publicationDryRun.source_archive_sha256
    release_evidence_bundle = $releaseEvidenceBundle
    clean_clone_or_import_proof = $cleanCloneOrImportProof
    windows_bundle_verifier_ok = [bool]$publicationDryRun.windows_bundle_verifier_ok
    windows_bundle_verifier_summary = [string]$publicationDryRun.windows_bundle_verifier_summary
    input_fingerprints = [ordered]@{
      release_handoff = Get-InputFingerprint -Path $releaseHandoffPath
      publication_dry_run = $publicationDryRunActualFingerprint
    }
    input_generated_at = [ordered]@{
      release_handoff = [string]$releaseHandoff.generated_at
      publication_dry_run = [string]$publicationDryRun.generated_at
    }
    publication_dry_run_input_fingerprints = $publicationInputFingerprints
    publication_dry_run_evidence_bundle_input_fingerprints = $publicationEvidenceBundleFingerprints
    publication_dry_run_evidence_bundle_preflight_artifact_fingerprints = $publicationArtifactFingerprints
    release_handoff_publication_dry_run_input_fingerprints = $releaseHandoffPublicationInputFingerprints
    release_handoff_publication_dry_run_evidence_bundle_input_fingerprints = $releaseHandoffPublicationEvidenceBundleFingerprints
    release_handoff_publication_dry_run_evidence_bundle_preflight_artifact_fingerprints = $releaseHandoffPublicationArtifactFingerprints
    artifact_file_fingerprints = $artifactFileFingerprints
    blocking_error_count = [int]$blockingErrors.Count
    blocking_errors = @($blockingErrors)
    next_manual_steps = @(
      "review this source publication packet",
      "merge stacked PRs in order",
      "choose and record the exact commit SHA on main",
      "create the annotated source tag after blockers are cleared",
      "publish the GitHub Release manually with source-only notes and no binary assets"
    )
  }

  $packetJson = $packet | ConvertTo-Json -Depth 30
  [System.IO.File]::WriteAllText($packetPath, $packetJson, [System.Text.UTF8Encoding]::new($false))

  if ($packetReady) {
    Write-Host "Source publication packet ready for manual review." -ForegroundColor Green
    Write-Host $packetPath
    exit 0
  }

  Write-Host "Source publication packet blocked." -ForegroundColor Red
  foreach ($errorMessage in $blockingErrors) {
    Write-Host "- $errorMessage"
  }
  Write-Host $packetPath
  exit 2
} finally {
  Pop-Location
}
