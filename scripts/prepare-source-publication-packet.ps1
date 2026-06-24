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
Add-Type -AssemblyName System.IO.Compression.FileSystem

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

function Test-PathUnderRoot {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$AllowedRoot
  )

  $resolvedPath = [System.IO.Path]::GetFullPath($Path)
  $resolvedRoot = [System.IO.Path]::GetFullPath((Resolve-RepoPath -Path $AllowedRoot))
  $rootWithSeparator = $resolvedRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
  return (
    $resolvedPath.Equals($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
    $resolvedPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
  )
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

function Add-ArtifactRootErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Name,
    [string]$AllowedRoot
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact path is missing for $Name"
    return
  }
  if (-not (Test-PathUnderRoot -Path $resolvedPath -AllowedRoot $AllowedRoot)) {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact path outside expected root for $Name"
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

function Add-ArtifactFileExtensionErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Name,
    [string]$ExpectedExtension
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    [string]::IsNullOrWhiteSpace($ExpectedExtension)
  ) {
    return
  }
  $actualExtension = [System.IO.Path]::GetExtension($resolvedPath)
  if (-not $ExpectedExtension.Equals($actualExtension, [System.StringComparison]::OrdinalIgnoreCase)) {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact file extension mismatch for $Name"
  }
}

function Add-ArtifactContentErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Name,
    [string]$ContentType
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    [string]::IsNullOrWhiteSpace($ContentType) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  try {
    if ($ContentType -eq "json") {
      $jsonText = Get-Content -Raw -LiteralPath $resolvedPath
      if ([string]::IsNullOrWhiteSpace($jsonText)) {
        throw "empty json artifact"
      }
      $null = $jsonText | ConvertFrom-Json
      return
    }

    if ($ContentType -eq "markdown") {
      $markdownText = Get-Content -Raw -LiteralPath $resolvedPath
      if ([string]::IsNullOrWhiteSpace($markdownText)) {
        throw "empty markdown artifact"
      }
      return
    }

    if ($ContentType -eq "zip") {
      $zip = [System.IO.Compression.ZipFile]::OpenRead($resolvedPath)
      try {
        if ($zip.Entries.Count -lt 1) {
          throw "empty zip artifact"
        }
      } finally {
        $zip.Dispose()
      }
      return
    }
  } catch {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact content invalid for $Name"
  }
}

function Add-ReleaseNotesClaimErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [object[]]$RequiredMarkers
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  $releaseNotesText = Get-Content -Raw -LiteralPath $resolvedPath
  if ($releaseNotesText -match "(?im)^\s*-\s*TBD\s*$" -or $releaseNotesText -match "(?i)\bTBD\b") {
    Add-BlockingError -Errors $Errors -Message "source publication packet release notes claims invalid"
    return
  }

  foreach ($marker in @($RequiredMarkers)) {
    $markerText = [string]$marker
    if ([string]::IsNullOrWhiteSpace($markerText)) {
      continue
    }
    if ($releaseNotesText.IndexOf($markerText, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      Add-BlockingError -Errors $Errors -Message "source publication packet release notes claims invalid"
      return
    }
  }
}

function Add-ReleaseNotesProofErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Tag,
    [string]$SourceArchiveSha256
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  $releaseNotesText = Get-Content -Raw -LiteralPath $resolvedPath
  foreach ($proofMarker in @($Tag, $SourceArchiveSha256)) {
    if (
      [string]::IsNullOrWhiteSpace([string]$proofMarker) -or
      $releaseNotesText.IndexOf([string]$proofMarker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet release notes proof mismatch"
      return
    }
  }
}

function Add-ProofManifestSourceArchiveShaErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Tag,
    [string]$CommitSha,
    [string]$SourceArchiveSha256,
    [string]$SourceArchivePath
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  try {
    $proofManifestPayload = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    $proofManifestTag = [string]$proofManifestPayload.tag
    $proofManifestCommitSha = [string]$proofManifestPayload.commit_sha
    $proofManifestSourceArchiveSha256 = [string]$proofManifestPayload.source_archive_sha256
    $proofManifestSourceArchiveName = [string]$proofManifestPayload.source_archive
    $sourceArchiveName = [System.IO.Path]::GetFileName((Get-NormalizedFingerprintPath -Path $SourceArchivePath))
    if (
      [string]::IsNullOrWhiteSpace($proofManifestTag) -or
      [string]::IsNullOrWhiteSpace($Tag) -or
      -not $proofManifestTag.Equals($Tag, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet proof manifest tag mismatch"
    }
    if (
      [string]::IsNullOrWhiteSpace($proofManifestCommitSha) -or
      [string]::IsNullOrWhiteSpace($CommitSha) -or
      -not $proofManifestCommitSha.Equals($CommitSha, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet proof manifest commit SHA mismatch"
    }
    if (
      [string]::IsNullOrWhiteSpace($proofManifestSourceArchiveSha256) -or
      [string]::IsNullOrWhiteSpace($SourceArchiveSha256) -or
      -not $proofManifestSourceArchiveSha256.Equals($SourceArchiveSha256, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet proof manifest source archive SHA mismatch"
    }
    if (
      [string]::IsNullOrWhiteSpace($proofManifestSourceArchiveName) -or
      [string]::IsNullOrWhiteSpace($sourceArchiveName) -or
      -not $proofManifestSourceArchiveName.Equals($sourceArchiveName, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet proof manifest source archive name mismatch"
    }
  } catch {
    Add-BlockingError -Errors $Errors -Message "source publication packet proof manifest source archive SHA mismatch"
  }
}

function Add-ReleaseEvidenceBundleTagErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Tag
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  try {
    $evidenceBundlePayload = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    $evidenceBundleTag = [string]$evidenceBundlePayload.tag
    if (
      [string]::IsNullOrWhiteSpace($evidenceBundleTag) -or
      [string]::IsNullOrWhiteSpace($Tag) -or
      -not $evidenceBundleTag.Equals($Tag, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle tag mismatch"
    }
  } catch {
    Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle tag mismatch"
  }
}

function Add-ReleaseEvidenceBundleCommitShaErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$CommitSha
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  try {
    $evidenceBundlePayload = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    $evidenceBundleCommitSha = [string]$evidenceBundlePayload.commit_sha
    if (
      [string]::IsNullOrWhiteSpace($evidenceBundleCommitSha) -or
      [string]::IsNullOrWhiteSpace($CommitSha) -or
      -not $evidenceBundleCommitSha.Equals($CommitSha, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle commit SHA mismatch"
    }
  } catch {
    Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle commit SHA mismatch"
  }
}

function Add-ReleaseEvidenceBundleSourceArchiveShaErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$SourceArchiveSha256
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  try {
    $evidenceBundlePayload = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    $evidenceBundleSourceArchiveSha256 = [string]$evidenceBundlePayload.source_archive_sha256
    if (
      [string]::IsNullOrWhiteSpace($evidenceBundleSourceArchiveSha256) -or
      [string]::IsNullOrWhiteSpace($SourceArchiveSha256) -or
      -not $evidenceBundleSourceArchiveSha256.Equals($SourceArchiveSha256, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle source archive SHA mismatch"
    }
  } catch {
    Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle source archive SHA mismatch"
  }
}

function Add-ReleaseEvidenceBundleSourceArchiveNameErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$SourceArchivePath
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  try {
    $evidenceBundlePayload = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    $evidenceBundleSourceArchiveName = [System.IO.Path]::GetFileName((Get-NormalizedFingerprintPath -Path ([string]$evidenceBundlePayload.source_archive)))
    $sourceArchiveName = [System.IO.Path]::GetFileName((Get-NormalizedFingerprintPath -Path $SourceArchivePath))
    if (
      [string]::IsNullOrWhiteSpace($evidenceBundleSourceArchiveName) -or
      [string]::IsNullOrWhiteSpace($sourceArchiveName) -or
      -not $evidenceBundleSourceArchiveName.Equals($sourceArchiveName, [System.StringComparison]::OrdinalIgnoreCase)
    ) {
      Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle source archive name mismatch"
    }
  } catch {
    Add-BlockingError -Errors $Errors -Message "source publication packet release evidence bundle source archive name mismatch"
  }
}

function Test-ArtifactTruthyFlag {
  param(
    [object]$Payload,
    [string]$FieldName
  )

  return ($Payload.PSObject.Properties[$FieldName] -and $Payload.$FieldName -eq $true)
}

function Test-ArtifactFalseFlag {
  param(
    [object]$Payload,
    [string]$FieldName
  )

  return ($Payload.PSObject.Properties[$FieldName] -and $Payload.$FieldName -eq $false)
}

function Test-ArtifactZeroField {
  param(
    [object]$Payload,
    [string]$FieldName
  )

  return ($Payload.PSObject.Properties[$FieldName] -and [int]$Payload.$FieldName -eq 0)
}

function Test-ArtifactSha256Field {
  param(
    [object]$Payload,
    [string]$FieldName
  )

  return (
    $Payload.PSObject.Properties[$FieldName] -and
    [string]$Payload.$FieldName -match "^[0-9a-fA-F]{64}$"
  )
}

function Test-ArtifactCommitShaField {
  param(
    [object]$Payload,
    [string]$FieldName
  )

  return (
    $Payload.PSObject.Properties[$FieldName] -and
    [string]$Payload.$FieldName -match "^[0-9a-fA-F]{40}$"
  )
}

function Test-SourceOnlyArtifactSchema {
  param([object]$Payload)

  foreach ($field in @("source_only", "no_apk", "no_exe", "no_store_release", "no_trusted_signing_claim")) {
    if (-not (Test-ArtifactTruthyFlag -Payload $Payload -FieldName $field)) {
      return $false
    }
  }
  if (-not (Test-ArtifactZeroField -Payload $Payload -FieldName "forbidden_file_count")) {
    return $false
  }
  return $true
}

function Add-ArtifactSchemaErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$Fingerprint,
    [string]$Name,
    [string]$SchemaContract
  )

  $resolvedPath = Get-NormalizedFingerprintPath -Path ([string]$Fingerprint.path)
  if (
    [string]::IsNullOrWhiteSpace($resolvedPath) -or
    [string]::IsNullOrWhiteSpace($SchemaContract) -or
    -not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)
  ) {
    return
  }

  try {
    $payload = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    $schemaOk = $true

    if ($SchemaContract -eq "source_proof") {
      $schemaOk = (
        (Test-SourceOnlyArtifactSchema -Payload $payload) -and
        (Test-ArtifactCommitShaField -Payload $payload -FieldName "commit_sha") -and
        (Test-ArtifactSha256Field -Payload $payload -FieldName "source_archive_sha256") -and
        -not [string]::IsNullOrWhiteSpace([string]$payload.source_archive)
      )
    } elseif ($SchemaContract -eq "source_evidence" -or $SchemaContract -eq "source_preflight") {
      $schemaOk = (
        (Test-SourceOnlyArtifactSchema -Payload $payload) -and
        (Test-ArtifactSha256Field -Payload $payload -FieldName "source_archive_sha256") -and
        (Test-ArtifactTruthyFlag -Payload $payload -FieldName "windows_bundle_verifier_ok")
      )
      if ($SchemaContract -eq "source_evidence") {
        $schemaOk = (
          $schemaOk -and
          (Test-ArtifactCommitShaField -Payload $payload -FieldName "commit_sha") -and
          (Test-ArtifactCommitShaField -Payload $payload -FieldName "preflight_commit_sha") -and
          (Test-ArtifactCommitShaField -Payload $payload -FieldName "preflight_ref_commit_sha") -and
          -not [string]::IsNullOrWhiteSpace([string]$payload.source_archive)
        )
      }
    } elseif ($SchemaContract -eq "windows_bundle_verifier") {
      $schemaOk = (
        (Test-ArtifactTruthyFlag -Payload $payload -FieldName "windows_bundle_ok") -and
        (Test-ArtifactTruthyFlag -Payload $payload -FieldName "source_only") -and
        (Test-ArtifactFalseFlag -Payload $payload -FieldName "build_performed") -and
        (Test-ArtifactFalseFlag -Payload $payload -FieldName "signing_performed") -and
        (Test-ArtifactFalseFlag -Payload $payload -FieldName "publish_performed") -and
        (Test-ArtifactFalseFlag -Payload $payload -FieldName "runtime_download_performed") -and
        (Test-ArtifactZeroField -Payload $payload -FieldName "forbidden_artifact_count")
      )
    } elseif ($SchemaContract -eq "github_ruleset_report") {
      $schemaOk = (
        [int]$payload.schema_version -eq 1 -and
        (Test-ArtifactTruthyFlag -Payload $payload -FieldName "read_only") -and
        $null -ne $payload.PSObject.Properties["ok"]
      )
    }

    if (-not $schemaOk) {
      Add-BlockingError -Errors $Errors -Message "source publication packet artifact schema invalid for $Name"
    }
  } catch {
    Add-BlockingError -Errors $Errors -Message "source publication packet artifact schema invalid for $Name"
  }
}

function Add-ReleaseAssetAllowlistErrors {
  param(
    [System.Collections.Generic.List[string]]$Errors,
    [object]$ReleaseAssetFingerprints,
    [object[]]$AllowedReleaseAssets
  )

  if ($null -eq $ReleaseAssetFingerprints) {
    return
  }

  $allowedAssetSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
  foreach ($assetName in @($AllowedReleaseAssets)) {
    if (-not [string]::IsNullOrWhiteSpace([string]$assetName)) {
      [void]$allowedAssetSet.Add([string]$assetName)
    }
  }

  foreach ($assetProperty in @($ReleaseAssetFingerprints.PSObject.Properties)) {
    if (-not $allowedAssetSet.Contains([string]$assetProperty.Name)) {
      Add-BlockingError -Errors $Errors -Message "source publication packet unexpected release asset fingerprint: $($assetProperty.Name)"
    }
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
  $publicationReleaseAssetFingerprints = $null
  if ($null -ne $publicationDryRun.PSObject.Properties["release_asset_fingerprints"]) {
    $publicationReleaseAssetFingerprints = $publicationDryRun.PSObject.Properties["release_asset_fingerprints"].Value
  }
  Add-ReleaseAssetAllowlistErrors `
    -Errors $blockingErrors `
    -ReleaseAssetFingerprints $publicationReleaseAssetFingerprints `
    -AllowedReleaseAssets @($seed.allowed_release_assets)

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

  $releaseHandoffPublicationSourceArchive = [string]$releaseHandoff.publication_dry_run_source_archive
  $releaseHandoffPublicationCommitSha = [string]$releaseHandoff.publication_dry_run_commit_sha
  $releaseHandoffPublicationSourceArchiveSha256 = [string]$releaseHandoff.publication_dry_run_source_archive_sha256
  $releaseHandoffPublicationPreflightCommitSha = [string]$releaseHandoff.publication_dry_run_evidence_bundle_preflight_commit_sha
  $releaseHandoffPublicationPreflightRefCommitSha = [string]$releaseHandoff.publication_dry_run_evidence_bundle_preflight_ref_commit_sha
  if ([string]::IsNullOrWhiteSpace($releaseHandoffPublicationSourceArchive)) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_source_archive"
  }
  elseif (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.source_archive) -and
    $releaseHandoffPublicationSourceArchive -ne [string]$publicationDryRun.source_archive
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff publication dry-run source archive name mismatch"
  }

  if ([string]::IsNullOrWhiteSpace($releaseHandoffPublicationCommitSha)) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_commit_sha"
  }
  elseif (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.commit_sha) -and
    $releaseHandoffPublicationCommitSha -ne [string]$publicationDryRun.commit_sha
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff publication dry-run commit SHA mismatch"
  }

  if ([string]::IsNullOrWhiteSpace($releaseHandoffPublicationSourceArchiveSha256)) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_source_archive_sha256"
  }
  elseif (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.source_archive_sha256) -and
    $releaseHandoffPublicationSourceArchiveSha256 -ne [string]$publicationDryRun.source_archive_sha256
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff publication dry-run source archive SHA mismatch"
  }

  if ([string]::IsNullOrWhiteSpace($releaseHandoffPublicationPreflightCommitSha)) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_evidence_bundle_preflight_commit_sha"
  }
  elseif (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.evidence_bundle_preflight_commit_sha) -and
    $releaseHandoffPublicationPreflightCommitSha -ne [string]$publicationDryRun.evidence_bundle_preflight_commit_sha
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff publication dry-run evidence bundle preflight commit SHA mismatch"
  }

  if ([string]::IsNullOrWhiteSpace($releaseHandoffPublicationPreflightRefCommitSha)) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff summary is missing publication_dry_run_evidence_bundle_preflight_ref_commit_sha"
  }
  elseif (
    -not [string]::IsNullOrWhiteSpace([string]$publicationDryRun.evidence_bundle_preflight_ref_commit_sha) -and
    $releaseHandoffPublicationPreflightRefCommitSha -ne [string]$publicationDryRun.evidence_bundle_preflight_ref_commit_sha
  ) {
    Add-BlockingError -Errors $blockingErrors -Message "release handoff publication dry-run evidence bundle preflight ref commit SHA mismatch"
  }

  $artifactRootSpecs = @(
    [ordered]@{ name = "release_notes"; value = $releaseNotes; root = [string]$seed.artifact_roots.release_notes },
    [ordered]@{ name = "release_evidence_bundle"; value = $releaseEvidenceBundle; root = [string]$seed.artifact_roots.release_evidence_bundle },
    [ordered]@{ name = "proof_manifest"; value = $proofManifest; root = [string]$seed.artifact_roots.proof_manifest },
    [ordered]@{ name = "source_archive"; value = $sourceArchive; root = [string]$seed.artifact_roots.source_archive },
    [ordered]@{ name = "clean_clone_or_import_proof"; value = $cleanCloneOrImportProof; root = [string]$seed.artifact_roots.clean_clone_or_import_proof },
    [ordered]@{ name = "windows_bundle_verifier_summary"; value = Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "windows_bundle_verifier_summary"; root = [string]$seed.artifact_roots.windows_bundle_verifier_summary }
  )
  foreach ($artifactRootSpec in $artifactRootSpecs) {
    Add-ArtifactRootErrors `
      -Errors $blockingErrors `
      -Fingerprint $artifactRootSpec.value `
      -Name $artifactRootSpec.name `
      -AllowedRoot $artifactRootSpec.root
  }
  $publicationRulesetReport = Get-FingerprintObject -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report"
  if (Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report") {
    Add-ArtifactRootErrors `
      -Errors $blockingErrors `
      -Fingerprint $publicationRulesetReport `
      -Name "github_ruleset_report" `
      -AllowedRoot ([string]$seed.artifact_roots.github_ruleset_report)
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

  if (Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report") {
    Add-ArtifactFileFingerprintErrors -Errors $blockingErrors -Fingerprint $publicationRulesetReport -Name "github_ruleset_report"
  }

  foreach ($artifactExtensionSpec in @(
    [ordered]@{ name = "release_notes"; value = $releaseNotes; extension = [string]$seed.artifact_file_extensions.release_notes },
    [ordered]@{ name = "release_evidence_bundle"; value = $releaseEvidenceBundle; extension = [string]$seed.artifact_file_extensions.release_evidence_bundle },
    [ordered]@{ name = "proof_manifest"; value = $proofManifest; extension = [string]$seed.artifact_file_extensions.proof_manifest },
    [ordered]@{ name = "source_archive"; value = $sourceArchive; extension = [string]$seed.artifact_file_extensions.source_archive },
    [ordered]@{ name = "clean_clone_or_import_proof"; value = $cleanCloneOrImportProof; extension = [string]$seed.artifact_file_extensions.clean_clone_or_import_proof },
    [ordered]@{ name = "windows_bundle_verifier_summary"; value = Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "windows_bundle_verifier_summary"; extension = [string]$seed.artifact_file_extensions.windows_bundle_verifier_summary }
  )) {
    Add-ArtifactFileExtensionErrors `
      -Errors $blockingErrors `
      -Fingerprint $artifactExtensionSpec.value `
      -Name $artifactExtensionSpec.name `
      -ExpectedExtension $artifactExtensionSpec.extension
  }

  if (Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report") {
    Add-ArtifactFileExtensionErrors `
      -Errors $blockingErrors `
      -Fingerprint $publicationRulesetReport `
      -Name "github_ruleset_report" `
      -ExpectedExtension ([string]$seed.artifact_file_extensions.github_ruleset_report)
  }

  foreach ($artifactContentSpec in @(
    [ordered]@{ name = "release_notes"; value = $releaseNotes; content_type = [string]$seed.artifact_content_types.release_notes },
    [ordered]@{ name = "release_evidence_bundle"; value = $releaseEvidenceBundle; content_type = [string]$seed.artifact_content_types.release_evidence_bundle },
    [ordered]@{ name = "proof_manifest"; value = $proofManifest; content_type = [string]$seed.artifact_content_types.proof_manifest },
    [ordered]@{ name = "source_archive"; value = $sourceArchive; content_type = [string]$seed.artifact_content_types.source_archive },
    [ordered]@{ name = "clean_clone_or_import_proof"; value = $cleanCloneOrImportProof; content_type = [string]$seed.artifact_content_types.clean_clone_or_import_proof },
    [ordered]@{ name = "windows_bundle_verifier_summary"; value = Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "windows_bundle_verifier_summary"; content_type = [string]$seed.artifact_content_types.windows_bundle_verifier_summary }
  )) {
    Add-ArtifactContentErrors `
      -Errors $blockingErrors `
      -Fingerprint $artifactContentSpec.value `
      -Name $artifactContentSpec.name `
      -ContentType $artifactContentSpec.content_type
  }

  if (Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report") {
    Add-ArtifactContentErrors `
      -Errors $blockingErrors `
      -Fingerprint $publicationRulesetReport `
      -Name "github_ruleset_report" `
      -ContentType ([string]$seed.artifact_content_types.github_ruleset_report)
  }

  Add-ReleaseNotesClaimErrors `
    -Errors $blockingErrors `
    -Fingerprint $releaseNotes `
    -RequiredMarkers @($seed.release_notes_required_markers)

  Add-ReleaseNotesProofErrors `
    -Errors $blockingErrors `
    -Fingerprint $releaseNotes `
    -Tag ([string]$publicationDryRun.tag) `
    -SourceArchiveSha256 ([string]$publicationDryRun.source_archive_sha256)

  Add-ProofManifestSourceArchiveShaErrors `
    -Errors $blockingErrors `
    -Fingerprint $proofManifest `
    -Tag ([string]$publicationDryRun.tag) `
    -CommitSha ([string]$publicationDryRun.commit_sha) `
    -SourceArchiveSha256 ([string]$publicationDryRun.source_archive_sha256) `
    -SourceArchivePath ([string]$sourceArchive.path)

  Add-ReleaseEvidenceBundleTagErrors `
    -Errors $blockingErrors `
    -Fingerprint $releaseEvidenceBundle `
    -Tag ([string]$publicationDryRun.tag)

  Add-ReleaseEvidenceBundleCommitShaErrors `
    -Errors $blockingErrors `
    -Fingerprint $releaseEvidenceBundle `
    -CommitSha ([string]$publicationDryRun.commit_sha)

  Add-ReleaseEvidenceBundleSourceArchiveShaErrors `
    -Errors $blockingErrors `
    -Fingerprint $releaseEvidenceBundle `
    -SourceArchiveSha256 ([string]$publicationDryRun.source_archive_sha256)

  Add-ReleaseEvidenceBundleSourceArchiveNameErrors `
    -Errors $blockingErrors `
    -Fingerprint $releaseEvidenceBundle `
    -SourceArchivePath ([string]$sourceArchive.path)

  foreach ($artifactSchemaSpec in @(
    [ordered]@{ name = "release_evidence_bundle"; value = $releaseEvidenceBundle; contract = [string]$seed.artifact_schema_contracts.release_evidence_bundle },
    [ordered]@{ name = "proof_manifest"; value = $proofManifest; contract = [string]$seed.artifact_schema_contracts.proof_manifest },
    [ordered]@{ name = "clean_clone_or_import_proof"; value = $cleanCloneOrImportProof; contract = [string]$seed.artifact_schema_contracts.clean_clone_or_import_proof },
    [ordered]@{ name = "windows_bundle_verifier_summary"; value = Get-FingerprintObject -Container $publicationArtifactFingerprints -FieldName "windows_bundle_verifier_summary"; contract = [string]$seed.artifact_schema_contracts.windows_bundle_verifier_summary }
  )) {
    Add-ArtifactSchemaErrors `
      -Errors $blockingErrors `
      -Fingerprint $artifactSchemaSpec.value `
      -Name $artifactSchemaSpec.name `
      -SchemaContract $artifactSchemaSpec.contract
  }

  if (Test-FingerprintField -Container $publicationEvidenceBundleFingerprints -FieldName "github_ruleset_report") {
    Add-ArtifactSchemaErrors `
      -Errors $blockingErrors `
      -Fingerprint $publicationRulesetReport `
      -Name "github_ruleset_report" `
      -SchemaContract ([string]$seed.artifact_schema_contracts.github_ruleset_report)
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
    publication_dry_run_release_asset_fingerprints = $publicationReleaseAssetFingerprints
    allowed_release_assets = @($seed.allowed_release_assets)
    artifact_file_extensions = $seed.artifact_file_extensions
    artifact_content_types = $seed.artifact_content_types
    artifact_schema_contracts = $seed.artifact_schema_contracts
    release_notes_required_markers = @($seed.release_notes_required_markers)
    release_notes_proof_requirements = @("publication_dry_run.tag", "publication_dry_run.source_archive_sha256")
    proof_manifest_proof_requirements = @("proof_manifest.tag", "proof_manifest.commit_sha", "proof_manifest.source_archive", "proof_manifest.source_archive_sha256", "publication_dry_run.tag", "publication_dry_run.commit_sha", "publication_dry_run.source_archive_sha256")
    release_evidence_bundle_proof_requirements = @("release_evidence_bundle.tag", "release_evidence_bundle.commit_sha", "release_evidence_bundle.source_archive", "release_evidence_bundle.source_archive_sha256", "publication_dry_run.tag", "publication_dry_run.commit_sha", "publication_dry_run.source_archive_sha256")
    release_handoff_publication_dry_run_input_fingerprints = $releaseHandoffPublicationInputFingerprints
    release_handoff_publication_dry_run_source_archive = $releaseHandoffPublicationSourceArchive
    release_handoff_publication_dry_run_commit_sha = $releaseHandoffPublicationCommitSha
    release_handoff_publication_dry_run_source_archive_sha256 = $releaseHandoffPublicationSourceArchiveSha256
    release_handoff_publication_dry_run_evidence_bundle_preflight_commit_sha = $releaseHandoffPublicationPreflightCommitSha
    release_handoff_publication_dry_run_evidence_bundle_preflight_ref_commit_sha = $releaseHandoffPublicationPreflightRefCommitSha
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
