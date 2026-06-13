param(
  [Parameter(Mandatory = $true)]
  [string]$Source,

  [Parameter(Mandatory = $true)]
  [string]$Stage,

  [Parameter(Mandatory = $true)]
  [string]$Manifest,

  [switch]$Apply,
  [switch]$SkipTests
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = [System.IO.Path]::GetFullPath($Source)
$stagePath = [System.IO.Path]::GetFullPath($Stage)
$manifestPath = [System.IO.Path]::GetFullPath($Manifest)
$repoRootPath = [System.IO.Path]::GetFullPath($repoRoot)

if ($stagePath.TrimEnd('\') -eq $repoRootPath.TrimEnd('\')) {
  throw "Stage must not be the public repository root."
}

if ($stagePath.StartsWith($repoRootPath.TrimEnd('\') + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Stage must be outside the public repository checkout."
}

if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
  throw "Source does not exist: $sourcePath"
}

if ($Apply -and (Test-Path -LiteralPath $stagePath) -and @(Get-ChildItem -LiteralPath $stagePath -Force).Count -gt 0) {
  throw "Stage must be empty before apply: $stagePath"
}

if (-not $SkipTests) {
  Push-Location $repoRootPath
  try {
    python -m pytest tests/test_source_import.py
    if ($LASTEXITCODE -ne 0) {
      throw "source-import tests failed"
    }
  } finally {
    Pop-Location
  }
}

$args = @(
  "-m",
  "tools.source_import.safe_import",
  "--source",
  $sourcePath,
  "--staging",
  $stagePath,
  "--manifest",
  $manifestPath
)

if ($Apply) {
  $args += "--apply"
}

Push-Location $repoRootPath
try {
  python @args
  if ($LASTEXITCODE -ne 0) {
    throw "safe_import reported blocked files. Review $manifestPath"
  }
} finally {
  Pop-Location
}

Write-Host "OSS import preparation completed." -ForegroundColor Green
Write-Host "Manifest: $manifestPath"
if ($Apply) {
  Write-Host "Stage: $stagePath"
} else {
  Write-Host "Dry-run only. Re-run with -Apply after reviewing the manifest." -ForegroundColor Yellow
}
