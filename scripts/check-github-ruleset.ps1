param(
  [string]$Repository = "Kiwunaka/Pokrov-client",
  [string]$Branch = "main",
  [switch]$Json,
  [switch]$ReportOnly
)

# Use -ReportOnly for non-blocking audits before remote settings are enabled.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$checks = [System.Collections.Generic.List[object]]::new()
$failed = $false

function Add-Check {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Status,
    [string]$Detail = ""
  )

  $script:checks.Add([ordered]@{
      name = $Name
      status = $Status
      detail = $Detail
    })

  if ($Status -eq "fail") {
    $script:failed = $true
  }
}

function Invoke-GhJson {
  param([Parameter(Mandatory = $true)][string]$Path)

  $previousErrorActionPreference = $ErrorActionPreference
  $script:ErrorActionPreference = "Continue"
  try {
    $output = & gh api $Path 2>$null
    $exitCode = $LASTEXITCODE
  } finally {
    $script:ErrorActionPreference = $previousErrorActionPreference
  }

  if ($exitCode -ne 0) {
    return [ordered]@{
      ok = $false
      payload = $null
    }
  }

  if ([string]::IsNullOrWhiteSpace($output)) {
    return [ordered]@{
      ok = $false
      payload = $null
    }
  }

  return [ordered]@{
    ok = $true
    payload = ($output | ConvertFrom-Json)
  }
}

function Get-RequiredCheckNames {
  $seedPath = Join-Path $root "config\required-checks.seed.json"
  $seed = Get-Content -Raw -LiteralPath $seedPath | ConvertFrom-Json
  return @($seed.required_jobs)
}

function Test-ContainsAll {
  param(
    [string[]]$Actual,
    [string[]]$Expected
  )

  foreach ($item in $Expected) {
    if ($Actual -notcontains $item) {
      return $false
    }
  }
  return $true
}

function Get-RulesetCheckNames {
  param([object[]]$Rulesets)

  $names = [System.Collections.Generic.List[string]]::new()
  foreach ($ruleset in @($Rulesets)) {
    foreach ($rule in @($ruleset.rules)) {
      if ($rule.type -ne "required_status_checks") {
        continue
      }
      foreach ($check in @($rule.parameters.required_status_checks)) {
        if ($check.context) {
          $names.Add([string]$check.context)
        } elseif ($check.context_name) {
          $names.Add([string]$check.context_name)
        }
      }
    }
  }
  return @($names | Select-Object -Unique)
}

function Test-RulesetAppliesToBranch {
  param(
    [object]$Ruleset,
    [string]$BranchName
  )

  $include = @($Ruleset.conditions.ref_name.include)
  if ($include.Count -eq 0) {
    return $true
  }

  foreach ($pattern in $include) {
    if ($pattern -in @("~DEFAULT_BRANCH", "refs/heads/$BranchName", $BranchName)) {
      return $true
    }
  }
  return $false
}

$requiredChecks = Get-RequiredCheckNames
$ghCommand = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghCommand) {
  Add-Check -Name "gh:command" -Status "fail" -Detail "GitHub CLI is required for remote ruleset verification"
} else {
  Add-Check -Name "gh:command" -Status "pass" -Detail $ghCommand.Source
}

$rulesets = @()
if ($ghCommand) {
  $rulesetSummariesResult = Invoke-GhJson -Path "repos/$Repository/rulesets?targets=branch"
  if ($rulesetSummariesResult.ok) {
    foreach ($summary in @($rulesetSummariesResult.payload)) {
      $detailResult = Invoke-GhJson -Path "repos/$Repository/rulesets/$($summary.id)"
      if ($detailResult.ok -and (Test-RulesetAppliesToBranch -Ruleset $detailResult.payload -BranchName $Branch)) {
        $rulesets += $detailResult.payload
      }
    }
  }
}

$activeRulesets = @($rulesets | Where-Object { $_.enforcement -eq "active" })
if ($activeRulesets.Count -gt 0) {
  Add-Check -Name "ruleset:active" -Status "pass" -Detail "$($activeRulesets.Count) active ruleset(s) apply to $Branch"
} else {
  Add-Check -Name "ruleset:active" -Status "fail" -Detail "No active repository ruleset applies to $Branch"
}

$rulesetRuleTypes = @($activeRulesets | ForEach-Object { $_.rules } | ForEach-Object { $_.type } | Select-Object -Unique)
$rulesetChecks = Get-RulesetCheckNames -Rulesets $activeRulesets
$branchChecks = @()

if ($rulesetRuleTypes -contains "pull_request") {
  Add-Check -Name "ruleset:pull_request" -Status "pass"
} else {
  Add-Check -Name "ruleset:pull_request" -Status "fail" -Detail "Active ruleset must require pull requests"
}

if (Test-ContainsAll -Actual $rulesetChecks -Expected $requiredChecks) {
  Add-Check -Name "ruleset:required_status_checks" -Status "pass" -Detail ($rulesetChecks -join ", ")
} else {
  Add-Check -Name "ruleset:required_status_checks" -Status "fail" -Detail "Required checks must include: $($requiredChecks -join ', ')"
}

if ($rulesetRuleTypes -contains "deletion") {
  Add-Check -Name "ruleset:block_deletion" -Status "pass"
} else {
  Add-Check -Name "ruleset:block_deletion" -Status "fail" -Detail "Active ruleset must block branch deletion"
}

if ($rulesetRuleTypes -contains "non_fast_forward") {
  Add-Check -Name "ruleset:block_force_push" -Status "pass"
} else {
  Add-Check -Name "ruleset:block_force_push" -Status "fail" -Detail "Active ruleset must block force pushes"
}

$branchProtection = $null
if ($ghCommand) {
  $branchProtectionResult = Invoke-GhJson -Path "repos/$Repository/branches/$Branch/protection"
  if ($branchProtectionResult.ok) {
    $branchProtection = $branchProtectionResult.payload
  }
}

if ($null -eq $branchProtection) {
  Add-Check -Name "branch_protection:active" -Status "fail" -Detail "Branch protection is not active or cannot be read for $Branch"
} else {
  Add-Check -Name "branch_protection:active" -Status "pass"

  foreach ($context in @($branchProtection.required_status_checks.contexts)) {
    $branchChecks += [string]$context
  }
  foreach ($check in @($branchProtection.required_status_checks.checks)) {
    if ($check.context) {
      $branchChecks += [string]$check.context
    }
  }
  $branchChecks = @($branchChecks | Select-Object -Unique)

  if (Test-ContainsAll -Actual $branchChecks -Expected $requiredChecks) {
    Add-Check -Name "branch_protection:required_status_checks" -Status "pass" -Detail ($branchChecks -join ", ")
  } else {
    Add-Check -Name "branch_protection:required_status_checks" -Status "fail" -Detail "Required checks must include: $($requiredChecks -join ', ')"
  }

  if ($branchProtection.required_pull_request_reviews.require_code_owner_reviews -eq $true) {
    Add-Check -Name "branch_protection:codeowners" -Status "pass"
  } else {
    Add-Check -Name "branch_protection:codeowners" -Status "fail" -Detail "CODEOWNERS review must be required"
  }

  if ($branchProtection.required_conversation_resolution.enabled -eq $true) {
    Add-Check -Name "branch_protection:conversation_resolution" -Status "pass"
  } else {
    Add-Check -Name "branch_protection:conversation_resolution" -Status "fail" -Detail "Conversation resolution must be required"
  }

  if ($branchProtection.allow_force_pushes.enabled -eq $false) {
    Add-Check -Name "branch_protection:block_force_push" -Status "pass"
  } else {
    Add-Check -Name "branch_protection:block_force_push" -Status "fail" -Detail "Force pushes must be blocked"
  }

  if ($branchProtection.allow_deletions.enabled -eq $false) {
    Add-Check -Name "branch_protection:block_deletion" -Status "pass"
  } else {
    Add-Check -Name "branch_protection:block_deletion" -Status "fail" -Detail "Branch deletion must be blocked"
  }
}

$detectedRequiredChecks = @($rulesetChecks + $branchChecks | Select-Object -Unique)
$coveredRequiredChecks = @($requiredChecks | Where-Object { $detectedRequiredChecks -contains $_ })

$summary = [ordered]@{
  schema_version = 1
  ok = -not $failed
  read_only = $true
  report_only = [bool]$ReportOnly
  repository = $Repository
  branch = $Branch
  required_status_checks = $requiredChecks
  covered_required_status_checks = $coveredRequiredChecks
  checked_at = (Get-Date).ToUniversalTime().ToString("o")
  checks = @($checks)
}

if ($Json) {
  $summary | ConvertTo-Json -Depth 20
} else {
  foreach ($check in $checks) {
    $color = if ($check.status -eq "pass") { "Green" } else { "Red" }
    $line = "$($check.status.ToUpperInvariant()) $($check.name)"
    if (-not [string]::IsNullOrWhiteSpace($check.detail)) {
      $line = "$line - $($check.detail)"
    }
    Write-Host $line -ForegroundColor $color
  }

  if ($failed) {
    Write-Host "GitHub ruleset verification failed or is not configured." -ForegroundColor Red
  } else {
    Write-Host "GitHub ruleset verification OK." -ForegroundColor Green
  }
}

if ($failed -and -not $ReportOnly) {
  exit 1
}

exit 0
