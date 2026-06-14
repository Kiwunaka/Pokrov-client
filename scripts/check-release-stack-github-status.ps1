param(
  [string]$PrStatusPath = "",
  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$defaultOutputDir = "build\release-stack-github-status"

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
    throw "Required release stack GitHub status input not found: $Path"
  }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
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
    throw "Release stack GitHub status output must stay under build\release-stack-github-status."
  }
}

function Read-PrStatusSnapshot {
  param([string]$Path)

  if (-not [string]::IsNullOrWhiteSpace($Path)) {
    $data = Read-JsonFile -Path (Resolve-RepoPath -Path $Path)
    foreach ($entry in @($data)) {
      $entry
    }
    return
  }

  $ghCommand = Get-Command gh -ErrorAction SilentlyContinue
  if (-not $ghCommand) {
    throw "GitHub CLI is required when -PrStatusPath is not provided."
  }

  $json = & gh pr list --state open --json number,title,headRefName,baseRefName,mergeStateStatus,isDraft,statusCheckRollup --limit 100
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to read pull request status snapshot with gh pr list."
  }
  $data = $json | ConvertFrom-Json
  foreach ($entry in @($data)) {
    $entry
  }
}

Push-Location $root
try {
  $seedPath = Join-Path $root "config\release-stack-github-status.seed.json"
  $mergeOrderPath = Join-Path $root "config\release-merge-order.seed.json"
  $seed = Read-JsonFile -Path $seedPath
  $mergeOrder = Read-JsonFile -Path $mergeOrderPath
  $stack = @($mergeOrder.stack)
  $requiredChecks = @($seed.required_status_checks)
  $snapshot = @(Read-PrStatusSnapshot -Path $PrStatusPath)
  $errors = [System.Collections.Generic.List[string]]::new()
  $checkedPrs = [System.Collections.Generic.List[object]]::new()
  $cleanPrCount = 0
  $draftPrCount = 0
  $uncleanPrCount = 0
  $successfulCheckCount = 0
  $failedCheckCount = 0

  foreach ($item in $stack) {
    $prNumber = [int]$item.pr
    $matches = @($snapshot | Where-Object { [int]$_.number -eq $prNumber })
    if ($matches.Count -ne 1) {
      $errors.Add("PR #$prNumber is missing from the GitHub status snapshot")
      continue
    }

    $status = $matches[0]
    $prErrors = [System.Collections.Generic.List[string]]::new()
    if ($status.baseRefName -ne $item.base) {
      $prErrors.Add("baseRefName is '$($status.baseRefName)' but expected '$($item.base)'")
    }
    if ($status.headRefName -ne $item.head) {
      $prErrors.Add("headRefName is '$($status.headRefName)' but expected '$($item.head)'")
    }
    if ($status.isDraft -eq $true) {
      $draftPrCount += 1
      $prErrors.Add("PR #$prNumber is draft")
    }
    if ($status.mergeStateStatus -ne "CLEAN") {
      $uncleanPrCount += 1
      $prErrors.Add("PR #$prNumber mergeStateStatus is $($status.mergeStateStatus)")
    } else {
      $cleanPrCount += 1
    }

    foreach ($checkName in $requiredChecks) {
      $checkMatches = @($status.statusCheckRollup | Where-Object { $_.name -eq $checkName })
      if ($checkMatches.Count -lt 1) {
        $failedCheckCount += 1
        $prErrors.Add("PR #$prNumber check '$checkName' is missing")
        continue
      }
      $check = $checkMatches[0]
      if ($check.status -ne "COMPLETED" -or $check.conclusion -ne "SUCCESS") {
        $failedCheckCount += 1
        $detail = if ($check.conclusion) { $check.conclusion } else { $check.status }
        $prErrors.Add("PR #$prNumber check '$checkName' is $detail")
      } else {
        $successfulCheckCount += 1
      }
    }

    foreach ($message in $prErrors) {
      $errors.Add($message)
    }

    $checkedPrs.Add([ordered]@{
        pr = $prNumber
        base = $item.base
        head = $item.head
        mergeStateStatus = $status.mergeStateStatus
        isDraft = [bool]$status.isDraft
        errors = @($prErrors)
      })
  }

  $github_status_ok = $true
  if ($errors.Count -gt 0) {
    $github_status_ok = $false
  }

  if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $root $defaultOutputDir
  } else {
    $OutDir = Resolve-RepoPath -Path $OutDir
  }
  Assert-BuildOutputPath -Path $OutDir
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

  $summaryPath = Join-Path $OutDir "release-stack-github-status.json"
  $summary = [ordered]@{
    schema_version = 1
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    read_only = $true
    github_status_ok = [bool]$github_status_ok
    stack_count = [int]$stack.Count
    latest_pr = if ($stack.Count -gt 0) { [int]$stack[-1].pr } else { 0 }
    latest_candidate = if ($stack.Count -gt 0) { $stack[-1].candidate } else { "" }
    clean_pr_count = [int]$cleanPrCount
    draft_pr_count = [int]$draftPrCount
    unclean_pr_count = [int]$uncleanPrCount
    successful_check_count = [int]$successfulCheckCount
    failed_check_count = [int]$failedCheckCount
    required_status_checks = $requiredChecks
    errors = @($errors)
    pull_requests = @($checkedPrs)
  }

  $summaryJson = $summary | ConvertTo-Json -Depth 30
  [System.IO.File]::WriteAllText($summaryPath, $summaryJson, [System.Text.UTF8Encoding]::new($false))

  if ($github_status_ok) {
    Write-Host "Release stack GitHub status OK." -ForegroundColor Green
    Write-Host $summaryPath
    exit 0
  }

  Write-Host "Release stack GitHub status failed." -ForegroundColor Red
  foreach ($errorMessage in $errors) {
    Write-Host "- $errorMessage"
  }
  Write-Host $summaryPath
  exit 2
} finally {
  Pop-Location
}
