param(
  [string]$ReleaseNotesPath = ""
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$errors = [System.Collections.Generic.List[string]]::new()

$requiredBoundaryPhrases = @(
  "source-only release",
  "No APK or EXE binaries.",
  "No store release.",
  "No trusted Windows signing claim.",
  "official POKROV backend, billing, admin, deployment, signing, or private",
  "release evidence",
  "separate public evidence"
)

$requiredGatePhrases = @(
  "scripts\source-release-preflight.ps1",
  "scripts\prepare-source-release.ps1",
  "scripts\render-source-release-notes.ps1"
)

function Add-MissingPhraseErrors {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$Text,
    [Parameter(Mandatory = $true)][string[]]$Phrases
  )

  foreach ($phrase in $Phrases) {
    if ($Text.IndexOf($phrase, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
      $errors.Add("$Label must include '$phrase'")
    }
  }
}

function Read-RequiredText {
  param([Parameter(Mandatory = $true)][string]$RelativePath)

  $fullPath = Join-Path $root $RelativePath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Required release-copy source is missing: $RelativePath"
  }

  return Get-Content -Raw -LiteralPath $fullPath
}

$releasePolicy = Read-RequiredText -RelativePath "docs\RELEASE_POLICY.md"
$releaseChecklist = Read-RequiredText -RelativePath "docs\RELEASE_CHECKLIST.md"
$sourceTemplate = Read-RequiredText -RelativePath "docs\releases\SOURCE_RELEASE_TEMPLATE.md"
$renderer = Read-RequiredText -RelativePath "scripts\render-source-release-notes.ps1"

Add-MissingPhraseErrors -Label "docs\RELEASE_POLICY.md" -Text $releasePolicy -Phrases @(
  "no APK, EXE, store release, or trusted-signed binary",
  "annotated tags",
  "source proof manifest",
  "scripts/source-release-preflight.ps1"
)

Add-MissingPhraseErrors -Label "docs\RELEASE_CHECKLIST.md" -Text $releaseChecklist -Phrases @(
  "source-release-preflight.ps1",
  "SkipTestCommands",
  "publishing",
  "no APK, EXE, store release, or",
  "Claims stay beta-safe"
)

Add-MissingPhraseErrors -Label "docs\releases\SOURCE_RELEASE_TEMPLATE.md" -Text $sourceTemplate -Phrases $requiredBoundaryPhrases
Add-MissingPhraseErrors -Label "scripts\render-source-release-notes.ps1" -Text $renderer -Phrases $requiredBoundaryPhrases
Add-MissingPhraseErrors -Label "scripts\render-source-release-notes.ps1" -Text $renderer -Phrases $requiredGatePhrases

if (-not [string]::IsNullOrWhiteSpace($ReleaseNotesPath)) {
  if (-not (Test-Path -LiteralPath $ReleaseNotesPath -PathType Leaf)) {
    throw "Release notes file does not exist: $ReleaseNotesPath"
  }

  $releaseNotes = Get-Content -Raw -LiteralPath $ReleaseNotesPath
  Add-MissingPhraseErrors -Label $ReleaseNotesPath -Text $releaseNotes -Phrases $requiredBoundaryPhrases
  Add-MissingPhraseErrors -Label $ReleaseNotesPath -Text $releaseNotes -Phrases @(
    "Source archive SHA-256:",
    "Source proof manifest:",
    "Verification date:"
  )
}

if ($errors.Count -gt 0) {
  Write-Host "Source release copy check failed." -ForegroundColor Red
  $errors | ForEach-Object { Write-Host $_ }
  exit 1
}

Write-Host "Source release copy check OK." -ForegroundColor Green
exit 0
