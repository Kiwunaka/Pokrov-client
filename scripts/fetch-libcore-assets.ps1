param(
  [string]$Tag,
  [string[]]$Platforms = @("windows"),
  [switch]$Force,
  [switch]$SyncToHosts
)

$root = Split-Path -Parent $PSScriptRoot

function Get-Sha256Hex {
  param([string]$Path)
  return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Test-Sha256ReviewValue {
  param([string]$Value)
  return (-not [string]::IsNullOrWhiteSpace($Value)) -and ($Value -match "^[a-fA-F0-9]{64}$")
}

function Assert-PathInsideRepo {
  param(
    [string]$Path,
    [string]$Description
  )

  $resolvedRoot = (Resolve-Path -LiteralPath $root).Path.TrimEnd("\", "/")
  $resolvedPath = (Resolve-Path -LiteralPath $Path).Path.TrimEnd("\", "/")
  $repoPrefix = $resolvedRoot + [System.IO.Path]::DirectorySeparatorChar

  if ($resolvedPath -ne $resolvedRoot -and -not $resolvedPath.StartsWith($repoPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "$Description must stay inside the repository: $resolvedPath"
  }
}

$configPath = Join-Path $root "config\runtime-artifacts.seed.json"
$config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json

if (-not $Tag) {
  $Tag = $config.libcore.release_tag
}

$repo = $config.libcore.repository
$cacheRoot = Join-Path $root "artifacts\libcore\$Tag"
New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

$ProgressPreference = "SilentlyContinue"
$release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/tags/$Tag"

foreach ($platform in $Platforms) {
  $assetConfig = $config.libcore.assets.$platform
  if (-not $assetConfig) {
    Write-Host "Skipping unknown platform '$platform'." -ForegroundColor Yellow
    continue
  }

  $asset = $release.assets | Where-Object { $_.name -eq $assetConfig.asset } | Select-Object -First 1
  if (-not $asset) {
    throw "Release $Tag does not include asset $($assetConfig.asset)"
  }

  $platformRoot = Join-Path $cacheRoot $platform
  $downloadDir = Join-Path $cacheRoot "_downloads"
  $archivePath = Join-Path $downloadDir $asset.name
  New-Item -ItemType Directory -Force -Path $platformRoot, $downloadDir | Out-Null

  if ($Force -or -not (Test-Path -LiteralPath $archivePath)) {
    Write-Host "Downloading $($asset.name)..." -ForegroundColor Cyan
    Invoke-WebRequest $asset.browser_download_url -OutFile $archivePath
  }

  if ($assetConfig.sha256 -eq "PENDING_PUBLIC_BINARY_REVIEW") {
    Write-Host "SHA-256 review is pending for $platform; this is local-only runtime material, not a source-release binary claim." -ForegroundColor Yellow
  } elseif (Test-Sha256ReviewValue $assetConfig.sha256) {
    $actualSha256 = Get-Sha256Hex -Path $archivePath
    if ($actualSha256 -ne $assetConfig.sha256.ToLowerInvariant()) {
      throw "SHA-256 mismatch for $($asset.name): expected $($assetConfig.sha256), got $actualSha256"
    }
  } else {
    throw "runtime-artifacts.seed.json must provide a 64-hex sha256 or PENDING_PUBLIC_BINARY_REVIEW for $platform"
  }

  if ($Force -and (Test-Path -LiteralPath $platformRoot)) {
    Get-ChildItem -Force -LiteralPath $platformRoot | Remove-Item -Recurse -Force
  }

  if (-not (Get-ChildItem -Force -LiteralPath $platformRoot -ErrorAction SilentlyContinue)) {
    Write-Host "Extracting $($asset.name)..." -ForegroundColor Cyan
    tar -xf $archivePath -C $platformRoot
  }

  $entryPath = Join-Path $platformRoot $assetConfig.entry
  if (-not (Test-Path -LiteralPath $entryPath)) {
    throw "Expected entry $($assetConfig.entry) was not found after extraction for $platform"
  }

  if ($SyncToHosts) {
    $syncDestination = Join-Path $root $assetConfig.sync_destination
    New-Item -ItemType Directory -Force -Path $syncDestination | Out-Null
    Assert-PathInsideRepo -Path $syncDestination -Description "Runtime sync destination"

    $destinationEntry = Join-Path $syncDestination (Split-Path $entryPath -Leaf)
    if (Test-Path -LiteralPath $destinationEntry) {
      Remove-Item -Recurse -Force -LiteralPath $destinationEntry
    }

    if (Test-Path -LiteralPath $entryPath -PathType Container) {
      tar -xf $archivePath -C $syncDestination $assetConfig.entry
    } else {
      Copy-Item -Force -LiteralPath $entryPath -Destination $syncDestination
    }

    if ($assetConfig.helper) {
      $helperPath = Join-Path $platformRoot $assetConfig.helper
      if (Test-Path -LiteralPath $helperPath) {
        Copy-Item -Force -LiteralPath $helperPath -Destination $syncDestination
      }
    }
  }

  Write-Host "Prepared $platform artifacts in $platformRoot" -ForegroundColor Green
}
