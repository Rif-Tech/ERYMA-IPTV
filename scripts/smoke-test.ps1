# Smoke test for the deployed Edge Functions. Usage: .\scripts\smoke-test.ps1 [-BaseUrl https://<ref>.supabase.co/functions/v1]
param(
  [string]$BaseUrl = 'https://zeproepijcixdmszlkmf.supabase.co/functions/v1',
  [string]$Mac = '02:11:22:33:44:55',
  [string]$Key = 'TEST01'
)
$ErrorActionPreference = 'Stop'
$json = @{ 'Content-Type' = 'application/json' }

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

Step 'app-info' { (Invoke-RestMethod "$BaseUrl/app-info").app_status }
Step 'device-register' {
  $body = @{ mac = $Mac; device_key = $Key; device_type = 'tv'; platform = 'android'; app_version = '1.0.0' } | ConvertTo-Json
  $r = Invoke-RestMethod "$BaseUrl/device-register" -Method Post -Headers $json -Body $body
  "is_trial=$($r.is_trial) expired=$($r.expired)"
}
Step 'device-register wrong key -> 409' { ExpectStatus 409 { Invoke-RestMethod "$BaseUrl/device-register" -Method Post -Headers $json -Body (@{ mac = $Mac; device_key = 'WRONG1' } | ConvertTo-Json) } }
$token = $null
Step 'portal-login' {
  $r = Invoke-RestMethod "$BaseUrl/portal-login" -Method Post -Headers $json -Body (@{ mac = $Mac; device_key = $Key } | ConvertTo-Json)
  $script:token = $r.token; "token length=$($r.token.Length)"
}
$auth = @{ 'Content-Type' = 'application/json'; 'x-portal-token' = $token }
$playlistId = $null
Step 'portal-playlists POST' {
  $r = Invoke-RestMethod "$BaseUrl/portal-playlists" -Method Post -Headers $auth -Body (@{ name = 'Test M3U'; type = 'm3u'; url = 'https://iptv-org.github.io/iptv/index.m3u' } | ConvertTo-Json)
  $script:playlistId = $r.playlist.id; $r.playlist.id
}
Step 'portal-playlists POST invalid -> 400' { ExpectStatus 400 { Invoke-RestMethod "$BaseUrl/portal-playlists" -Method Post -Headers $auth -Body (@{ name = 'x'; type = 'xtream'; url = 'http://h' } | ConvertTo-Json) } }
Step 'device-playlists GET' {
  $r = Invoke-RestMethod "$BaseUrl/device-playlists?mac=$Mac&key=$Key"
  "count=$($r.playlists.Count) first=$($r.playlists[0].name)"
}
Step 'portal-playlists PUT' {
  $r = Invoke-RestMethod "$BaseUrl/portal-playlists" -Method Put -Headers $auth -Body (@{ id = $playlistId; name = 'Renamed' } | ConvertTo-Json)
  $r.playlist.name
}
Step 'portal-playlists DELETE' { (Invoke-RestMethod "$BaseUrl/portal-playlists" -Method Delete -Headers $auth -Body (@{ id = $playlistId } | ConvertTo-Json)).ok }
Step 'portal-playlists bad token -> 401' { ExpectStatus 401 { Invoke-RestMethod "$BaseUrl/portal-playlists" -Headers @{ 'x-portal-token' = 'abc.def' } } }
