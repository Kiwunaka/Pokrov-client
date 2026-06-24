param(
  [switch]$SourceOnly
)

$root = Split-Path -Parent $PSScriptRoot
$androidProjectPath = Join-Path $root "apps\android_shell\android"
$gradleWrapper = Join-Path $androidProjectPath "gradlew.bat"
$libcoreAar = Join-Path $androidProjectPath "app\libs\libcore.aar"

if (-not (Test-Path -LiteralPath $gradleWrapper -PathType Leaf)) {
  Write-Error "Android Gradle wrapper not found at $gradleWrapper"
  exit 1
}

& (Join-Path $PSScriptRoot "bootstrap-workspace.ps1")
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$gradleArgs = @(":app:testDebugUnitTest")
if ($SourceOnly) {
  Write-Host "Running Android native Gradle unit tests with source-only libcore stubs." -ForegroundColor Cyan
  $gradleArgs += "-PopenClientUseLibcoreStub=true"
} else {
  if (-not (Test-Path -LiteralPath $libcoreAar -PathType Leaf)) {
    Write-Error "Android runtime artifact not found at $libcoreAar. Prepare the local runtime artifact as described in docs\BUILD_FROM_SOURCE.md before the runtime-backed Android native lane."
    exit 1
  }
  Write-Host "Running Android native Gradle unit tests with local runtime artifact." -ForegroundColor Cyan
}

Push-Location $androidProjectPath
try {
  & $gradleWrapper @gradleArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}

Write-Host "Android native Gradle unit tests completed." -ForegroundColor Green
