param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^v\d+\.\d+\.\d+-source$')]
  [string]$Tag,

  [string]$Ref = "HEAD",
  [string]$OutDir = "",
  [switch]$RequireTag,
  [switch]$AllowDirty
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutDir)) {
  $OutDir = Join-Path $root "build\source-release-proof\$Tag"
}

function Assert-LastExitCode {
  param([string]$Message)

  if ($LASTEXITCODE -ne 0) {
    throw $Message
  }
}

function Invoke-Git {
  param([string[]]$Arguments)

  $output = & git @Arguments
  Assert-LastExitCode "git $($Arguments -join ' ') failed"
  return $output
}

function Get-Sha256Hex {
  param([Parameter(Mandatory = $true)][string]$Path)

  $stream = [System.IO.File]::OpenRead($Path)
  try {
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
      $hashBytes = $sha256.ComputeHash($stream)
      return ([System.BitConverter]::ToString($hashBytes) -replace "-", "").ToLowerInvariant()
    } finally {
      $sha256.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

Push-Location $root
try {
  $gitRoot = (Invoke-Git @("rev-parse", "--show-toplevel") | Select-Object -First 1)
  $resolvedGitRoot = (Resolve-Path -LiteralPath $gitRoot).Path
  $resolvedRoot = (Resolve-Path -LiteralPath $root).Path
  if ($resolvedGitRoot -ne $resolvedRoot) {
    throw "Script must run from the repository root. Found git root: $resolvedGitRoot"
  }

  if ($RequireTag) {
    $tagRef = "refs/tags/$Tag"
    Invoke-Git @("rev-parse", "--verify", $tagRef) | Out-Null
    $Ref = $tagRef
  }

  $status = @(Invoke-Git @("status", "--short"))
  if (-not $AllowDirty -and $status.Count -gt 0) {
    $status | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    throw "Working tree must be clean before preparing source release proof. Pass -AllowDirty only for local/CI smoke tests."
  }

  $commitSha = (Invoke-Git @("rev-parse", $Ref) | Select-Object -First 1)
  $commitDate = (Invoke-Git @("show", "-s", "--format=%cI", $commitSha) | Select-Object -First 1)
  $trackedFiles = @(Invoke-Git @("ls-tree", "-r", "--name-only", $commitSha))
  $forbiddenPathPattern = '(^|/)(build|dist|out|artifacts|coverage|reports|logs|screenshots|screen-shots|tmp|\.tmp|\.dart_tool|\.gradle|ephemeral|node_modules|config/local|private-release-evidence)(/|$)'
  $forbiddenExtensionPattern = '\.(dll|exe|pfx|p12|keystore|jks|pem|key|mobileprovision|cer|crt|env|apk|aab|ipa|msi|msix|dmg|pkg|zip|log)$'
  $forbiddenFiles = @($trackedFiles | Where-Object {
      $normalized = $_ -replace '\\', '/'
      $normalized -match $forbiddenPathPattern -or $normalized -match $forbiddenExtensionPattern
    })

  if ($forbiddenFiles.Count -gt 0) {
    $forbiddenFiles | ForEach-Object { Write-Host "Forbidden source-release file: $_" -ForegroundColor Red }
    throw "Source release proof refused forbidden generated, binary, signing, secret, or local files."
  }

  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
  $archivePath = Join-Path $OutDir "$Tag-source.zip"
  $manifestPath = Join-Path $OutDir "$Tag-source-proof.json"

  if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
  }

  git archive --format=zip --output=$archivePath $commitSha
  Assert-LastExitCode "git archive failed"

  $archiveHash = Get-Sha256Hex -Path $archivePath
  $proof = [ordered]@{
    schema_version = 1
    tag = $Tag
    ref = $Ref
    commit_sha = $commitSha
    commit_date = $commitDate
    verification_date = (Get-Date).ToUniversalTime().ToString("o")
    source_archive = (Split-Path -Leaf $archivePath)
    source_archive_sha256 = $archiveHash
    source_only = $true
    no_apk = $true
    no_exe = $true
    no_store_release = $true
    no_trusted_signing_claim = $true
    tracked_file_count = $trackedFiles.Count
    forbidden_file_count = $forbiddenFiles.Count
  }

  $proof | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

  Write-Host "Source release proof prepared:" -ForegroundColor Green
  Write-Host "Tag: $Tag"
  Write-Host "Commit: $commitSha"
  Write-Host "Archive: $archivePath"
  Write-Host "SHA-256: $archiveHash"
  Write-Host "Manifest: $manifestPath"
} finally {
  Pop-Location
}
