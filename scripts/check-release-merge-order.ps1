param(
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$defaultOutputDir = "build\release-merge-order"

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
    throw "Required release merge order input not found: $Path"
  }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

Push-Location $root
try {
  $seedPath = Join-Path $root "config\release-merge-order.seed.json"
  $seed = Read-JsonFile -Path $seedPath
  $stack = @($seed.stack)
  $errors = [System.Collections.Generic.List[string]]::new()

  if ($stack.Count -eq 0) {
    $errors.Add("release merge order stack is empty")
  }

  for ($index = 1; $index -lt $stack.Count; $index += 1) {
    $previous = $stack[$index - 1]
    $current = $stack[$index]
    if ($current.base -ne $previous.head) {
      $errors.Add("PR #$($current.pr) base '$($current.base)' must equal previous head '$($previous.head)'")
    }
    if ([int]$current.pr -le [int]$previous.pr) {
      $errors.Add("PR #$($current.pr) must appear after PR #$($previous.pr)")
    }
  }

  $merge_order_ok = $true
  if ($errors.Count -gt 0) {
    $merge_order_ok = $false
  }

  if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $root $defaultOutputDir
  } else {
    $OutDir = Resolve-RepoPath -Path $OutDir
  }
  $allowedOutputRoot = [System.IO.Path]::GetFullPath((Join-Path $root $defaultOutputDir))
  $resolvedOutputDir = [System.IO.Path]::GetFullPath($OutDir)
  $allowedPrefix = $allowedOutputRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
  ) + [System.IO.Path]::DirectorySeparatorChar
  if (
    $resolvedOutputDir -ne $allowedOutputRoot -and
    -not $resolvedOutputDir.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)
  ) {
    throw "Release merge order output must stay under build\release-merge-order."
  }
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

  $summaryPath = Join-Path $OutDir "release-merge-order.json"
  $summary = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    read_only = $true
    merge_order_ok = $true
    linear_base_to_head_chain = [bool]$merge_order_ok
    stack_count = [int]$stack.Count
    latest_pr = if ($stack.Count -gt 0) { [int]$stack[-1].pr } else { 0 }
    latest_candidate = if ($stack.Count -gt 0) { $stack[-1].candidate } else { "" }
    errors = @($errors)
    stack = @(
      $stack | ForEach-Object {
        [ordered]@{
          pr = [int]$_.pr
          candidate = $_.candidate
          base = $_.base
          head = $_.head
        }
      }
    )
  }

  if (-not $merge_order_ok) {
    $summary.merge_order_ok = $false
  }

  $summaryJson = $summary | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($summaryPath, $summaryJson, [System.Text.UTF8Encoding]::new($false))

  if ($merge_order_ok) {
    Write-Host "Release merge order OK." -ForegroundColor Green
    Write-Host $summaryPath
    exit 0
  }

  Write-Host "Release merge order failed." -ForegroundColor Red
  foreach ($errorMessage in $errors) {
    Write-Host "- $errorMessage"
  }
  Write-Host $summaryPath
  exit 2
} finally {
  Pop-Location
}
