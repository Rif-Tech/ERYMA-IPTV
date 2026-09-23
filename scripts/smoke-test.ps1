# Smoke test for the deployed Edge Functions (account / pairing model).
# Usage: .\scripts\smoke-test.ps1 [-BaseUrl https://<ref>.supabase.co/functions/v1] [-AnonKey <publishable key>]
#        [-DeviceUuid <uuid> -DeviceSecret <secret>]   # optional: a paired install to exercise device-session
param(
  [string]$BaseUrl = 'https://zeproepijcixdmszlkmf.supabase.co/functions/v1',
  [string]$AnonKey = $(
    $env = Join-Path (Split-Path $PSScriptRoot -Parent) 'apps\portal\.env.local'
    if (Test-Path $env) { ((Get-Content $env | Where-Object { $_ -like 'NEXT_PUBLIC_SUPABASE_ANON_KEY=*' }) -split '=', 2)[1].Trim() } else { '' }
  ),
  [string]$DeviceUuid,
  [string]$DeviceSecret
)
$ErrorActionPreference = 'Stop'
$json = @{ 'Content-Type' = 'application/json'; apikey = $AnonKey; Authorization = "Bearer $AnonKey" }

function Step($name, $block) {
  try { $out = & $block; Write-Host "[OK]   $name -> $out" } catch { Write-Host "[FAIL] $name -> $($_.Exception.Message)"; }
}
function ExpectStatus($code, $block) {
  try { & $block | Out-Null; throw "expected HTTP $code" } catch {
    $got = $_.Exception.Response.StatusCode.value__
    if ($got -ne $code) { throw "expected HTTP $code, got $got" }
    "HTTP $got"
  }
}

Step 'app-info' { $r = Invoke-RestMethod "$BaseUrl/app-info" -Headers $json; "status=$($r.app_status) portal_url=$($r.portal_url)" }

# A throw-away install: pairing-create must hand out a code + QR URL without any account.
$uuid = [guid]::NewGuid().ToString()
$secret = 'smoke-' + [guid]::NewGuid().ToString('N')
$hash = ([System.Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($secret)) | ForEach-Object { $_.ToString('x2') }) -join ''
$ticket = $null
Step 'pairing-create (device)' {
  $body = @{ kind = 'device'; device_uuid = $uuid; secret_hash = $hash; device_type = 'tv'; platform = 'android'; app_version = 'smoke' } | ConvertTo-Json
  $script:ticket = Invoke-RestMethod "$BaseUrl/pairing-create" -Method Post -Headers $json -Body $body
  "code=$($ticket.code) url=$($ticket.url)"
}
Step 'pairing-status pending' {
  $r = Invoke-RestMethod "$BaseUrl/pairing-status?session_id=$($ticket.session_id)&token=$($ticket.token)" -Headers $json
  $r.status
}
Step 'pairing-status bad token -> 404/401' {
  try { Invoke-RestMethod "$BaseUrl/pairing-status?session_id=$($ticket.session_id)&token=nope" -Headers $json | Out-Null; throw 'expected error' }
  catch { $got = $_.Exception.Response.StatusCode.value__; if ($got -notin 401, 404) { throw "got $got" }; "HTTP $got" }
}
Step 'device-session unpaired -> 401' {
  ExpectStatus 401 { Invoke-RestMethod "$BaseUrl/device-session" -Headers ($json + @{ 'x-device-id' = $uuid; 'x-device-secret' = $secret }) }
}
Step 'featured without identity -> 401' { ExpectStatus 401 { Invoke-RestMethod "$BaseUrl/featured?mode=curated" -Headers $json } }
Step 'pairing-confirm without session -> 401' {
  ExpectStatus 401 { Invoke-RestMethod "$BaseUrl/pairing-confirm?code=$($ticket.code)" -Headers $json }
}

if ($DeviceUuid -and $DeviceSecret) {
  $dev = $json + @{ 'x-device-id' = $DeviceUuid; 'x-device-secret' = $DeviceSecret }
  Step 'device-session (paired install)' {
    $r = Invoke-RestMethod "$BaseUrl/device-session" -Headers $dev
    "device=$($r.device.name) plan=$($r.account.plan) profiles=$($r.profiles.Count) playlists=$($r.playlists.Count)"
  }
  Step 'featured (paired install)' { (Invoke-RestMethod "$BaseUrl/featured?mode=curated&lang=fr-FR" -Headers $dev).items.Count }
}
