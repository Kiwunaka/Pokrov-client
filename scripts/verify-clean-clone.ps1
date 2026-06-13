param(
  [string]$Source = "",
  [string]$WorkRoot = "",
  [switch]$SkipFlutterTests,
  [switch]$KeepClone
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Source)) {
  $Source = $repoRoot
}

$generatedWorkRoot = [string]::IsNullOrWhiteSpace($WorkRoot)
if ($generatedWorkRoot) {
  $WorkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("pokrov-client-clean-clone-" + [System.Guid]::NewGuid().ToString("N"))
}

$clonePath = Join-Path $WorkRoot "repo"
$stagePath = Join-Path $WorkRoot "safe-import-stage"
$manifestPath = Join-Path $WorkRoot "safe-import-manifest.json"

function Invoke-Step {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [scriptblock]$Body
  )

  Write-Host "==> $Name" -ForegroundColor Cyan
  & $Body
}

function Assert-LastExitCode {
  param([string]$Message)

  if ($LASTEXITCODE -ne 0) {
    throw $Message
  }
}

try {
  New-Item -ItemType Directory -Path $WorkRoot -Force | Out-Null

  Invoke-Step "Clone public source" {
    git clone --depth 1 $Source $clonePath
    Assert-LastExitCode "git clone failed"
  }

  Invoke-Step "Reject committed private or generated artifacts" {
    Push-Location $clonePath
    try {
      $forbiddenPathPattern = '(^|/)(build|dist|out|artifacts|coverage|reports|logs|screenshots|screen-shots|tmp|\.tmp|\.dart_tool|\.gradle|ephemeral|node_modules|config/local|private-release-evidence)(/|$)'
      $forbiddenExtensionPattern = '\.(dll|exe|pfx|p12|keystore|jks|pem|key|mobileprovision|cer|crt|env|apk|aab|ipa|msi|msix|dmg|pkg|zip|log)$'
      $tracked = git ls-files
      Assert-LastExitCode "git ls-files failed"
      $forbidden = $tracked | Where-Object {
        $normalized = $_ -replace '\\', '/'
        $normalized -match $forbiddenPathPattern -or $normalized -match $forbiddenExtensionPattern
      }
      if ($forbidden) {
        $forbidden | ForEach-Object { Write-Host "Forbidden tracked file: $_" -ForegroundColor Red }
        throw "Clean clone contains forbidden generated, secret, signing, or runtime artifacts."
      }
    } finally {
      Pop-Location
    }
  }

  Invoke-Step "Run source-import tests" {
    Push-Location $clonePath
    try {
      python -m pytest tests/test_source_import.py
      Assert-LastExitCode "source-import tests failed"
    } finally {
      Pop-Location
    }
  }

  Invoke-Step "Run safe_import dry-run against clean clone" {
    Push-Location $clonePath
    try {
      python -m tools.source_import.safe_import --source $clonePath --staging $stagePath --manifest $manifestPath
      Assert-LastExitCode "safe_import dry-run failed"
    } finally {
      Pop-Location
    }
  }

  if ($SkipFlutterTests) {
    Write-Host "Skipping Flutter clean-clone tests by request." -ForegroundColor Yellow
  } else {
    Invoke-Step "Bootstrap Flutter workspace" {
      Push-Location $clonePath
      try {
        powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-workspace.ps1
        Assert-LastExitCode "workspace bootstrap failed"
      } finally {
        Pop-Location
      }
    }

    Invoke-Step "Analyze app shell" {
      Push-Location (Join-Path $clonePath "packages\app_shell")
      try {
        flutter analyze
        Assert-LastExitCode "flutter analyze failed"
      } finally {
        Pop-Location
      }
    }

    Invoke-Step "Run workspace tests" {
      Push-Location $clonePath
      try {
        powershell -ExecutionPolicy Bypass -File .\scripts\run-tests.ps1
        Assert-LastExitCode "workspace tests failed"
      } finally {
        Pop-Location
      }
    }
  }

  Write-Host "Clean clone proof completed." -ForegroundColor Green
} finally {
  if (-not $KeepClone -and $generatedWorkRoot -and (Test-Path -LiteralPath $WorkRoot)) {
    $resolvedWorkRoot = (Resolve-Path -LiteralPath $WorkRoot).Path
    $tempRoot = [System.IO.Path]::GetTempPath().TrimEnd('\')
    $leaf = Split-Path -Leaf $resolvedWorkRoot
    if (-not $resolvedWorkRoot.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
        -not $leaf.StartsWith("pokrov-client-clean-clone-", [System.StringComparison]::OrdinalIgnoreCase)) {
      throw "Refusing to remove unexpected work root: $resolvedWorkRoot"
    }
    Remove-Item -LiteralPath $resolvedWorkRoot -Recurse -Force
  } elseif ($KeepClone -or -not $generatedWorkRoot) {
    Write-Host "Clean clone retained at $clonePath" -ForegroundColor Yellow
  }
}
