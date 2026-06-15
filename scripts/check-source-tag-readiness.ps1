param(
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^v\d+\.\d+\.\d+-source$')]
  [string]$Tag,

  [string]$OutDir = ""
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$defaultOutputDir = "build\source-tag-readiness"

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
    throw "Required readiness input not found: $Path"
  }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

Push-Location $root
try {
  $inventoryPath = Join-Path $root "config\release-blocker-inventory.seed.json"
  $readinessPath = Join-Path $root "config\source-release-readiness.seed.json"
  $inventory = Read-JsonFile -Path $inventoryPath
  $readiness = Read-JsonFile -Path $readinessPath

  $milestone = $readiness.milestones | Where-Object { $_.tag -eq $Tag } | Select-Object -First 1
  if ($null -eq $milestone) {
    throw "Source readiness milestone not found for $Tag."
  }

  if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $root (Join-Path $defaultOutputDir $Tag)
  } else {
    $OutDir = Resolve-RepoPath -Path $OutDir
  }
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

  $openBlockers = @(
    $inventory.blockers | Where-Object {
      $_.required_before_tag -eq $true -and
      $_.status -notin @("complete", "cleared", "ready")
    }
  )

  $readyForTag = $false
  if ($inventory.tracked_candidates.tag_creation_allowed -eq $true -and
    $openBlockers.Count -eq 0 -and
    $milestone.status -notlike "*not_tagged*") {
    $readyForTag = $true
  }

  $summary = [ordered]@{
    schema_version = 1
    tag = $Tag
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    ready_for_tag = $false
    source_only = [bool]$inventory.source_only
    ships_apk = [bool]$inventory.ships_apk
    ships_exe = [bool]$inventory.ships_exe
    store_release = [bool]$inventory.store_release
    trusted_signing_claim = [bool]$inventory.trusted_signing_claim
    status = $inventory.status
    latest_candidate = $inventory.tracked_candidates.latest_candidate
    latest_stacked_pr = [int]$inventory.tracked_candidates.latest_stacked_pr
    tag_creation_allowed = [bool]$inventory.tracked_candidates.tag_creation_allowed
    milestone_status = $milestone.status
    milestone_evidence = $milestone.evidence
    open_blocker_count = [int]$openBlockers.Count
    open_blockers = @(
      $openBlockers | ForEach-Object {
        [ordered]@{
          id = $_.id
          status = $_.status
          required_before_tag = [bool]$_.required_before_tag
          evidence = $_.evidence
        }
      }
    )
  }

  if ($readyForTag) {
    $summary.ready_for_tag = $true
  }

  $summaryPath = Join-Path $OutDir "$Tag-tag-readiness.json"
  $summaryJson = $summary | ConvertTo-Json -Depth 20
  [System.IO.File]::WriteAllText($summaryPath, $summaryJson, [System.Text.UTF8Encoding]::new($false))

  if ($readyForTag) {
    Write-Host "Source tag readiness: READY" -ForegroundColor Green
    Write-Host $summaryPath
    exit 0
  }

  Write-Host "Source tag readiness: NOT READY" -ForegroundColor Yellow
  Write-Host "Open blockers: $($openBlockers.Count)"
  foreach ($blocker in $openBlockers) {
    Write-Host "- $($blocker.id): $($blocker.status)"
  }
  Write-Host $summaryPath
  exit 2
} finally {
  Pop-Location
}
