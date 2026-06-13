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

function Get-ResponseStatusCode {
  param([object]$Response)

  if ($null -eq $Response) {
    return $null
  }

  $statusCode = $Response.StatusCode
  if ($null -eq $statusCode) {
    return $null
  }

  if ($statusCode -is [int]) {
    return $statusCode
  }

  if ($null -ne $statusCode.value__) {
    return [int]$statusCode.value__
  }

  return [int]$statusCode
}

function Get-ResponseHeaderValue {
  param(
    [object]$Response,
    [string]$Name
  )

  if ($null -eq $Response -or $null -eq $Response.Headers) {
    return $null
  }

  $headers = $Response.Headers

  if ($headers -is [System.Collections.IDictionary] -and $headers.Contains($Name)) {
    return [string]$headers[$Name]
  }

  try {
    $value = $headers[$Name]
    if ($null -ne $value) {
      if ($value -is [array]) {
        return [string]$value[0]
      }
      return [string]$value
    }
  } catch {
  }

  try {
    $values = $null
    if ($headers.TryGetValues($Name, [ref]$values)) {
      return [string](@($values)[0])
    }
  } catch {
  }

  return $null
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
  if ($session.session.token_type -ne "Bearer") {
    throw "start-trial did not return Bearer token_type"
  }
  if ([int]$session.session.expires_in -le 0) {
    throw "start-trial did not return a positive expires_in"
  }
  if ($session.provisioning.managed_manifest.version -ne "operator-v1") {
    throw "start-trial did not return managed manifest version operator-v1"
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

  $tickets = Invoke-FixtureJson -Method GET -Path "/api/tickets"
  if (-not $tickets.tickets) {
    throw "support tickets fixture returned an empty list"
  }

  $unauthorized = $false
  try {
    Invoke-RestMethod -Method GET -Uri "$baseUrl/api/client/profile/managed?mode=401" | Out-Null
  } catch {
    if ((Get-ResponseStatusCode -Response $_.Exception.Response) -eq 401) {
      $unauthorized = $true
    }
  }
  if (-not $unauthorized) {
    throw "401 fixture mode did not return HTTP 401"
  }

  $rateLimited = $false
  try {
    Invoke-WebRequest `
      -Method GET `
      -Uri "$baseUrl/api/client/profile/managed?mode=429" `
      -Headers @{
        "X-Request-ID" = "operator-smoke-request"
      } | Out-Null
  } catch {
    $response = $_.Exception.Response
    if ((Get-ResponseStatusCode -Response $response) -eq 429) {
      $rateLimited = $true
      if ((Get-ResponseHeaderValue -Response $response -Name "Retry-After") -ne "60") {
        throw "429 fixture mode did not return Retry-After=60"
      }
      if ((Get-ResponseHeaderValue -Response $response -Name "X-Request-ID") -ne "operator-smoke-request") {
        throw "429 fixture mode did not echo X-Request-ID"
      }
      if ((Get-ResponseHeaderValue -Response $response -Name "X-API-Version") -ne "2026-06-operator-v1") {
        throw "429 fixture mode did not return X-API-Version"
      }
    }
  }
  if (-not $rateLimited) {
    throw "429 fixture mode did not return HTTP 429"
  }

  Write-Host "Operator fixture smoke passed at $baseUrl"
} finally {
  if ($null -ne $server -and -not $server.HasExited) {
    Stop-Process -Id $server.Id -Force
    $server.WaitForExit()
  }
}
