param(
  [int]$Port = 18765,
  [string]$Python = "python"
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$baseUrl = "http://127.0.0.1:$Port"
$server = $null

function Invoke-FixtureJson {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body = $null
  )

  $headers = @{
    Authorization = "Bearer operator-session-token-placeholder"
  }
  $uri = "$baseUrl$Path"
  if ($null -eq $Body) {
    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
  }
  return Invoke-RestMethod `
    -Method $Method `
    -Uri $uri `
    -Headers $headers `
    -ContentType "application/json" `
    -Body ($Body | ConvertTo-Json -Depth 20)
}

try {
  $server = Start-Process `
    -FilePath $Python `
    -ArgumentList @("-m", "tools.operator_fixture_server", "--port", "$Port") `
    -WorkingDirectory $repoRoot `
    -PassThru `
    -WindowStyle Hidden

  $ready = $false
  for ($attempt = 0; $attempt -lt 30; $attempt += 1) {
    try {
      $health = Invoke-RestMethod -Method GET -Uri "$baseUrl/health"
      if ($health.ok -eq $true) {
        $ready = $true
        break
      }
    } catch {
      Start-Sleep -Milliseconds 250
    }
  }

  if (-not $ready) {
    throw "Operator fixture did not become ready at $baseUrl"
  }

  $session = Invoke-FixtureJson `
    -Method POST `
    -Path "/api/client/session/start-trial" `
    -Body @{
      install_id = "smoke-install"
      platform = "windows"
      app_version = "0.1.0-source"
    }
  if (-not $session.session.session_token) {
    throw "start-trial did not return session.session_token"
  }

  $route = Invoke-FixtureJson `
    -Method POST `
    -Path "/api/client/route-policy" `
    -Body @{
      route_mode = "all"
      selected_apps = @()
    }
  if ($route.ok -ne $true) {
    throw "route-policy did not return ok=true"
  }

  $profile = Invoke-FixtureJson -Method GET -Path "/api/client/profile/managed"
  if (-not $profile.materialized_for_runtime) {
    throw "managed profile was not materialized_for_runtime"
  }

  $apps = Invoke-FixtureJson `
    -Method GET `
    -Path "/api/client/apps?platform=windows&current_version=0.1.0-source&channel=beta"
  if ($apps.update_check.silent_update -ne $false) {
    throw "apps metadata must use prompt updates, not silent updates"
  }

  $tickets = Invoke-FixtureJson -Method GET -Path "/api/client/support/tickets"
  if (-not $tickets.tickets) {
    throw "support tickets fixture returned an empty list"
  }

  $unauthorized = $false
  try {
    Invoke-RestMethod -Method GET -Uri "$baseUrl/api/client/profile/managed?mode=401" | Out-Null
  } catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 401) {
      $unauthorized = $true
    }
  }
  if (-not $unauthorized) {
    throw "401 fixture mode did not return HTTP 401"
  }

  Write-Host "Operator fixture smoke passed at $baseUrl"
} finally {
  if ($null -ne $server -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force
    $server.WaitForExit()
  }
}
