param(
  [string]$PacketPath,
  [string]$OutDir = "build\source-publication-gate"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$seedPath = Join-Path $root "config\source-publication-gate.seed.json"
$defaultOutputDir = "build\source-publication-gate"

function Get-Sha256 {
  param([string]$Path)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $stream = [System.IO.File]::OpenRead($Path)
    try {
      return (($sha.ComputeHash($stream) | ForEach-Object { $_.ToString("x2") }) -join "")
    } finally {
      $stream.Dispose()
    }
  } finally {
    $sha.Dispose()
  }
}

function Test-PathUnderRoot {
  param(
    [string]$Path,
    [string]$AllowedRoot
  )
  if ([System.IO.Path]::IsPathRooted($Path)) {
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  } else {
    $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $root $Path))
  }
  $resolvedRoot = [System.IO.Path]::GetFullPath((Join-Path $root $AllowedRoot))
  return $resolvedPath.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-InputFingerprint {
  param([string]$Path)
  [ordered]@{
    path = $Path
    sha256 = Get-Sha256 -Path $Path
  }
}

function Resolve-RepoPath {
  param([string]$Path)
  if ([System.IO.Path]::IsPathRooted($Path)) {
    return [System.IO.Path]::GetFullPath($Path)
  }
  return [System.IO.Path]::GetFullPath((Join-Path $root $Path))
}

function Add-BlockingError {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [string]$Message
  )
  if (-not $Errors.Contains($Message)) {
    $Errors.Add($Message)
  }
}

function Test-PropertyExists {
  param(
    [object]$Object,
    [string]$Name
  )
  return $null -ne $Object.PSObject.Properties[$Name]
}

Push-Location $root
try {
  $seed = Get-Content -Raw -LiteralPath $seedPath | ConvertFrom-Json
  if ([string]::IsNullOrWhiteSpace($PacketPath)) {
    $PacketPath = [string]$seed.inputs.source_publication_packet
  }

  if (-not (Test-PathUnderRoot -Path $OutDir -AllowedRoot $defaultOutputDir)) {
    throw "Source publication gate output must stay under build\source-publication-gate."
  }
  if (-not (Test-PathUnderRoot -Path $PacketPath -AllowedRoot ([string]$seed.input_roots.source_publication_packet))) {
    throw "Source publication gate input source_publication_packet must stay under build\source-publication-packet."
  }

  $packet = Get-Content -Raw -LiteralPath $PacketPath | ConvertFrom-Json
  $blockingErrors = [System.Collections.Generic.List[string]]::new()
  $tag = [string]$packet.tag
  if ([string]::IsNullOrWhiteSpace($tag)) {
    $tag = "unknown-source"
  }

  if ($packet.schema_version -ne 1) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet must use schema_version 1"
  }
  if ($packet.read_only -ne $true -or $packet.manual_publish_only -ne $true) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet is not a read-only manual publish packet"
  }
  if ($packet.packet_ready_for_manual_publish_review -ne $true) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet is not ready for manual publish review"
  }
  if (
    $packet.source_only -ne $true -or
    $packet.no_apk -ne $true -or
    $packet.no_exe -ne $true -or
    $packet.no_store_release -ne $true -or
    $packet.no_trusted_signing_claim -ne $true
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet has unsafe source-only flags"
  }
  if (
    $packet.publish_performed -ne $false -or
    $packet.tag_push_performed -ne $false -or
    $packet.asset_upload_performed -ne $false
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet reports a publish or git mutation"
  }
  foreach ($optionalMutationField in @("merge_performed", "tag_created", "release_published")) {
    if (
      (Test-PropertyExists -Object $packet -Name $optionalMutationField) -and
      $packet.$optionalMutationField -ne $false
    ) {
      Add-BlockingError -Errors $blockingErrors -Message "source publication packet reports a publish or git mutation"
    }
  }

  $packetGeneratedAt = [string]$packet.generated_at
  $parsedGeneratedAt = [datetimeoffset]::MinValue
  if ([string]::IsNullOrWhiteSpace($packetGeneratedAt) -or -not [datetimeoffset]::TryParse($packetGeneratedAt, [ref]$parsedGeneratedAt)) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet must include parseable generated_at timestamp"
  } else {
    $age = [datetimeoffset]::UtcNow - $parsedGeneratedAt.ToUniversalTime()
    if ($age.TotalHours -gt 24 -or $age.TotalMinutes -lt -5) {
      Add-BlockingError -Errors $blockingErrors -Message "source publication packet has stale generated_at timestamp"
    }
  }

  if (
    $null -eq $packet.input_fingerprints -or
    $null -eq $packet.input_fingerprints.release_handoff -or
    $null -eq $packet.input_fingerprints.publication_dry_run
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet is missing input fingerprints"
  } else {
    foreach ($fingerprintName in @("release_handoff", "publication_dry_run")) {
      $fingerprint = $packet.input_fingerprints.PSObject.Properties[$fingerprintName].Value
      if (
        [string]::IsNullOrWhiteSpace([string]$fingerprint.path) -or
        [string]::IsNullOrWhiteSpace([string]$fingerprint.sha256) -or
        [string]$fingerprint.sha256 -notmatch "^[0-9a-fA-F]{64}$"
      ) {
        Add-BlockingError -Errors $blockingErrors -Message "source publication packet input fingerprint mismatch"
      }
    }
  }
  if ($null -eq $packet.artifact_file_fingerprints) {
    Add-BlockingError -Errors $blockingErrors -Message "source publication packet is missing artifact file fingerprints"
  } else {
    foreach ($artifactProperty in @($packet.artifact_file_fingerprints.PSObject.Properties)) {
      $artifactFingerprint = $artifactProperty.Value
      $artifactPath = [string]$artifactFingerprint.path
      $artifactSha = [string]$artifactFingerprint.sha256
      if (
        [string]::IsNullOrWhiteSpace($artifactPath) -or
        [string]::IsNullOrWhiteSpace($artifactSha) -or
        $artifactSha -notmatch "^[0-9a-fA-F]{64}$"
      ) {
        Add-BlockingError -Errors $blockingErrors -Message "source publication gate artifact fingerprint mismatch"
        continue
      }
      if (-not (Test-PathUnderRoot -Path $artifactPath -AllowedRoot "build")) {
        Add-BlockingError -Errors $blockingErrors -Message "source publication gate artifact fingerprint mismatch"
        continue
      }
      $resolvedArtifactPath = Resolve-RepoPath -Path $artifactPath
      if (-not (Test-Path -LiteralPath $resolvedArtifactPath -PathType Leaf)) {
        Add-BlockingError -Errors $blockingErrors -Message "source publication gate artifact fingerprint mismatch"
        continue
      }
      $currentArtifactSha = Get-Sha256 -Path $resolvedArtifactPath
      if ($currentArtifactSha -ne $artifactSha.ToLowerInvariant()) {
        Add-BlockingError -Errors $blockingErrors -Message "source publication gate artifact fingerprint mismatch"
      }
    }
  }

  $packetFingerprint = Get-InputFingerprint -Path $PacketPath
  $gateReady = @($blockingErrors).Count -eq 0
  $outRoot = Join-Path $OutDir $tag
  New-Item -ItemType Directory -Force -Path $outRoot | Out-Null
  $gatePath = Join-Path $outRoot "$tag-publication-gate.json"
  $summary = [ordered]@{
    schema_version = 1
    tag = $tag
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    read_only = $true
    source_only = $true
    manual_publish_review_gate = $true
    publication_gate_ready_for_manual_publish = [bool]$gateReady
    publish_performed = $false
    asset_upload_performed = $false
    tag_push_performed = $false
    source_publication_packet = $PacketPath
    source_publication_packet_sha256 = $packetFingerprint.sha256
    source_publication_packet_generated_at = $packetGeneratedAt
    source_publication_packet_input_fingerprint = $packetFingerprint
    packet_input_fingerprints = $packet.input_fingerprints
    packet_artifact_file_fingerprints = $packet.artifact_file_fingerprints
    blocking_errors = @($blockingErrors)
  }
  $summaryJson = $summary | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($gatePath, $summaryJson, [System.Text.UTF8Encoding]::new($false))

  if ($gateReady) {
    Write-Host "Source publication gate: READY" -ForegroundColor Green
    Write-Host $gatePath
    exit 0
  }

  Write-Host "Source publication gate: NOT READY" -ForegroundColor Yellow
  foreach ($errorMessage in $blockingErrors) {
    Write-Host "- $errorMessage"
  }
  exit 2
} finally {
  Pop-Location
}
