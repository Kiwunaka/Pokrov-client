param(
  [string]$OutDir = "build\windows-bundle-verifier"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$seedPath = Join-Path $root "config\windows-bundle-verifier.seed.json"
$defaultOutput = Join-Path $root "build\windows-bundle-verifier"
$resolvedDefaultOutput = [System.IO.Path]::GetFullPath($defaultOutput)
$outputCandidate = if ([System.IO.Path]::IsPathRooted($OutDir)) {
  $OutDir
} else {
  Join-Path $root $OutDir
}
$resolvedOutDir = [System.IO.Path]::GetFullPath($outputCandidate)
$errors = [System.Collections.Generic.List[string]]::new()

if (-not ($resolvedOutDir.Equals($resolvedDefaultOutput, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedOutDir.StartsWith($resolvedDefaultOutput + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase))) {
  throw "Windows bundle verifier output must stay under build\windows-bundle-verifier."
}

if (-not (Test-Path -LiteralPath $seedPath -PathType Leaf)) {
  throw "Missing config\windows-bundle-verifier.seed.json"
}

$seed = Get-Content -Raw -LiteralPath $seedPath | ConvertFrom-Json
$missingRequired = [System.Collections.Generic.List[string]]::new()
$forbiddenArtifacts = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in @($seed.required_paths)) {
  $fullPath = Join-Path $root $relativePath
  if (-not (Test-Path -LiteralPath $fullPath)) {
    $missingRequired.Add($relativePath)
  }
}

foreach ($relativeRoot in @($seed.scan_roots)) {
  $scanRoot = Join-Path $root $relativeRoot
  if (-not (Test-Path -LiteralPath $scanRoot -PathType Container)) {
    $errors.Add("Missing scan root: $relativeRoot")
    continue
  }

  $trackedPaths = @(git -C $root ls-files -- $relativeRoot)
  foreach ($repoPath in $trackedPaths) {
    $extension = [System.IO.Path]::GetExtension($repoPath).ToLowerInvariant()
    $isAllowed = @($seed.allowed_committed_files) -contains $repoPath
    if ((@($seed.forbidden_committed_extensions) -contains $extension) -and -not $isAllowed) {
      $forbiddenArtifacts.Add($repoPath)
    }
  }
}

foreach ($relativePath in $missingRequired) {
  $errors.Add("Missing required Windows source path: $relativePath")
}

foreach ($relativePath in $forbiddenArtifacts) {
  $errors.Add("Forbidden Windows binary, signing, archive, or runtime artifact is committed: $relativePath")
}

$summary = [ordered]@{
  schema_version = 1
  windows_bundle_ok = ($errors.Count -eq 0)
  source_only = [bool]$seed.policy.source_only
  read_only = [bool]$seed.policy.read_only
  no_flutter_build = $true
  no_runtime_download = $true
  no_signing = $true
  no_packaging = $true
  no_publish = $true
  build_performed = $false
  signing_performed = $false
  publish_performed = $false
  runtime_download_performed = $false
  required_path_count = @($seed.required_paths).Count
  missing_required_paths = @($missingRequired)
  forbidden_artifact_count = $forbiddenArtifacts.Count
  forbidden_artifacts = @($forbiddenArtifacts)
  release_claim_boundary = [ordered]@{
    ships_exe = [bool]$seed.release_claim_boundary.ships_exe
    store_release = [bool]$seed.release_claim_boundary.store_release
    trusted_signing_claim = [bool]$seed.release_claim_boundary.trusted_signing_claim
    runtime_binary_ready = [bool]$seed.release_claim_boundary.runtime_binary_ready
    official_binary_claim = [bool]$seed.release_claim_boundary.official_binary_claim
  }
  errors = @($errors)
}

New-Item -ItemType Directory -Force -Path $resolvedOutDir | Out-Null
$summaryPath = Join-Path $resolvedOutDir "windows-bundle-verifier.json"
$summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

if ($errors.Count -gt 0) {
  Write-Host "Windows bundle verifier blocked." -ForegroundColor Red
  $errors | ForEach-Object { Write-Host $_ }
  exit 1
}

Write-Host "Windows bundle verifier OK:" -ForegroundColor Green
Write-Host $summaryPath
exit 0
