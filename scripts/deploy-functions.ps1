# Deploys every Edge Function to the cloud project (device-facing ones without JWT verification).
# One-time: `npx supabase login` (opens a browser) or set $env:SUPABASE_ACCESS_TOKEN.
# Usage: .\scripts\deploy-functions.ps1 [-Only pairing-create,device-session]
param([string[]]$Only)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$ref = 'zeproepijcixdmszlkmf'

$noJwt = @(
  'app-info',
  'featured', 'tmdb', 'watch-events',
  'pairing-create', 'pairing-status', 'pairing-confirm', 'device-session', 'device-context', 'device-progress'
)
$all = Get-ChildItem "$root\supabase\functions" -Directory | Where-Object { $_.Name -notlike '_*' } | Select-Object -ExpandProperty Name
$targets = if ($Only) { $Only } else { $all }

Push-Location $root
try {
  foreach ($fn in $targets) {
    $flag = if ($noJwt -contains $fn) { '--no-verify-jwt' } else { '' }
    Write-Host "== $fn $flag"
    npx supabase functions deploy $fn --project-ref $ref $flag
    if ($LASTEXITCODE -ne 0) { throw "deploy failed: $fn" }
  }
} finally {
  Pop-Location
}
Write-Host 'Remember the secrets: PORTAL_URL (pairing links), TMDB_API_KEY, PORTAL_TOKEN_SECRET.'
