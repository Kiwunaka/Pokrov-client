param(
  [switch]$SkipCommandChecks,
  [switch]$Json
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$results = [System.Collections.Generic.List[object]]::new()
$failed = $false

function Add-Check {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Status,
    [string]$Detail = ""
  )

  $script:results.Add([ordered]@{
      name = $Name
      status = $Status
      detail = $Detail
    })

  if ($Status -eq "fail") {
    $script:failed = $true
  }
}

function Test-Command {
  param([Parameter(Mandatory = $true)][string]$Name)

  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($command) {
    Add-Check -Name "command:$Name" -Status "pass" -Detail $command.Source
  } else {
    Add-Check -Name "command:$Name" -Status "fail" -Detail "Command not found on PATH"
  }
}

$requiredFiles = @(
  "README.md",
  "CHANGELOG.md",
  "CONTRIBUTING.md",
  "docs\BUILD_FROM_SOURCE.md",
  "apps\android_shell\android\gradlew.bat",
  "apps\android_shell\android\app\build.gradle",
  "apps\windows_shell\windows\CMakeLists.txt",
  "scripts\bootstrap-workspace.ps1",
  "scripts\run-tests.ps1",
  "scripts\validate-seed.ps1",
  "config\templates\local.env.example",
  "config\templates\device-overrides.seed.json"
)

foreach ($relativePath in $requiredFiles) {
  $fullPath = Join-Path $root $relativePath
  if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
    Add-Check -Name "file:$relativePath" -Status "pass"
  } else {
    Add-Check -Name "file:$relativePath" -Status "fail" -Detail "Required public file is missing"
  }
}

if ($PSVersionTable.PSVersion.Major -ge 5) {
  Add-Check -Name "powershell:version" -Status "pass" -Detail $PSVersionTable.PSVersion.ToString()
} else {
  Add-Check -Name "powershell:version" -Status "fail" -Detail "PowerShell 5+ is required"
}

if ($SkipCommandChecks) {
  foreach ($name in @("git", "python", "flutter", "dart")) {
    Add-Check -Name "command:$name" -Status "skip" -Detail "Skipped by -SkipCommandChecks"
  }
} else {
  foreach ($name in @("git", "python", "flutter", "dart")) {
    Test-Command -Name $name
  }
}

$gitDirectory = Join-Path $root ".git"
if (Test-Path -LiteralPath $gitDirectory -PathType Container) {
  Add-Check -Name "git:worktree" -Status "pass" -Detail "Repository checkout detected"
} else {
  Add-Check -Name "git:worktree" -Status "fail" -Detail "Run from a repository checkout"
}

$summary = [ordered]@{
  schema_version = 1
  ok = -not $failed
  skipped_command_checks = [bool]$SkipCommandChecks
  read_only = $true
  root = $root
  checks = @($results)
}

if ($Json) {
  $summary | ConvertTo-Json -Depth 10
} else {
  foreach ($check in $results) {
    $color = if ($check.status -eq "pass") {
      "Green"
    } elseif ($check.status -eq "skip") {
      "Yellow"
    } else {
      "Red"
    }
    $line = "$($check.status.ToUpperInvariant()) $($check.name)"
    if (-not [string]::IsNullOrWhiteSpace($check.detail)) {
      $line = "$line - $($check.detail)"
    }
    Write-Host $line -ForegroundColor $color
  }

  if ($failed) {
    Write-Host "Contributor doctor found issues." -ForegroundColor Red
  } else {
    Write-Host "Contributor doctor OK." -ForegroundColor Green
  }
}

if ($failed) {
  exit 1
}

exit 0
